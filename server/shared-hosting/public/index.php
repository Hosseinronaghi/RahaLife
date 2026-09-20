<?php
declare(strict_types=1);
// Do not expose SQL statements, paths or credentials in public error responses.
ini_set('display_errors', '0');
set_exception_handler(static function (Throwable $error): void {
    error_log('Raha API unhandled exception: ' . get_class($error));
    respond(500, ['ok'=>false, 'error'=>'internal_error']);
});

function loadConfig(): array
{
    $local = dirname(__DIR__) . '/config.local.php';
    if (is_file($local)) {
        $config = require $local;
        if (is_array($config)) {
            return $config;
        }
    }
    return [
        'db_dsn' => getenv('RAHA_DB_DSN') ?: '',
        'db_user' => getenv('RAHA_DB_USER') ?: '',
        'db_password' => getenv('RAHA_DB_PASSWORD') ?: '',
        'api_token' => getenv('RAHA_API_TOKEN') ?: '',
        'storage_dir' => getenv('RAHA_STORAGE_DIR') ?: dirname(__DIR__) . '/storage',
        'max_backup_bytes' => (int) (getenv('RAHA_MAX_BACKUP_BYTES') ?: 268435456),
        'keep_backup_versions' => (int) (getenv('RAHA_KEEP_BACKUP_VERSIONS') ?: 7),
        'cors_origin' => getenv('RAHA_CORS_ORIGIN') ?: '*',
    ];
}

$config = loadConfig();
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ($config['cors_origin'] ?? '*'));
header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Raha-Client, X-Raha-Backup-Name');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(int $status, array $payload): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function bearerToken(): string
{
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (preg_match('/^Bearer\s+(.+)$/i', $header, $matches)) {
        return trim($matches[1]);
    }
    return '';
}

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
require __DIR__ . '/accounts.php';
require __DIR__ . '/protocol.php';
require __DIR__ . '/backup_store.php';
$expectedToken = (string)($config['api_token'] ?? '');
$scopeId = ($expectedToken !== '' && $expectedToken !== 'CHANGE_TO_A_LONG_RANDOM_TOKEN' && hash_equals($expectedToken,bearerToken())) ? 'personal' : accountRoute($config,$path,$method);
if(!$scopeId)respond(401,['error'=>'unauthorized']);
collaborationRoute($config,$path,$method,$scopeId);

function routeEndsWith(string $path, string $route): bool
{
    $normalizedPath = '/' . trim($path, '/');
    $normalizedRoute = '/' . trim($route, '/');
    return $normalizedPath === $normalizedRoute || str_ends_with($normalizedPath, $normalizedRoute);
}

function pdo(array $config): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }
    $dsn = (string) ($config['db_dsn'] ?? '');
    if ($dsn === '') {
        respond(503, ['ok' => false, 'error' => 'database_not_configured']);
    }
    try {
        $pdo = new PDO(
            $dsn,
            (string) ($config['db_user'] ?? ''),
            (string) ($config['db_password'] ?? ''),
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
        return $pdo;
    } catch (Throwable $error) {
        respond(503, ['ok' => false, 'error' => 'database_unavailable']);
    }
}

function readJsonBody(): array
{
    $raw = file_get_contents('php://input', false, null, 0, 8388609);
    if ($raw !== false && strlen($raw)>8388608) respond(413,['error'=>'request_too_large']);
    if ($raw === false || $raw === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        respond(400, ['ok' => false, 'error' => 'invalid_json']);
    }
    return $decoded;
}


if (routeEndsWith($path, '/health') && $method === 'GET') {
    $db = pdo($config);
    $db->query('SELECT 1');
    respond(200, [
        'ok' => true,
        'service' => 'raha-sync',
        'protocolVersion' => 3,
        'features' => ['backup', 'record-sync'],
    ]);
}

if (routeEndsWith($path, '/v1/backup/latest') && $method === 'PUT') {
    $storageDir = (string) ($config['storage_dir'] ?? dirname(__DIR__) . '/storage') . ($scopeId === 'personal' ? '' : '/' . $scopeId);
    if (!is_dir($storageDir) && !mkdir($storageDir, 0700, true) && !is_dir($storageDir)) {
        respond(500, ['ok' => false, 'error' => 'storage_unavailable']);
    }
    $maxBytes = (int) ($config['max_backup_bytes'] ?? 268435456);
    $contentLength = isset($_SERVER['CONTENT_LENGTH']) ? (int) $_SERVER['CONTENT_LENGTH'] : 0;
    if ($contentLength > $maxBytes) {
        respond(413, ['ok' => false, 'error' => 'backup_too_large']);
    }
    $raw = file_get_contents('php://input',false,null,0,$maxBytes+1);
    if ($raw === false || $raw === '') {
        respond(400, ['ok' => false, 'error' => 'empty_backup']);
    }
    if (strlen($raw) > $maxBytes) {
        respond(413, ['ok' => false, 'error' => 'backup_too_large']);
    }
    try {
        $safeName = writeBackup($storageDir, $raw, (int)($config['keep_backup_versions'] ?? 7));
    } catch (Throwable $error) {
        respond(500, ['ok' => false, 'error' => 'backup_write_failed']);
    }
    respond(200, ['ok' => true, 'fileName' => $safeName, 'bytes' => strlen($raw)]);
}

if (routeEndsWith($path, '/v1/backup/latest') && $method === 'GET') {
    $storageDir = (string) ($config['storage_dir'] ?? dirname(__DIR__) . '/storage') . ($scopeId === 'personal' ? '' : '/' . $scopeId);
    $latest = $storageDir . '/latest.rahabackup';
    if (!is_file($latest)) {
        respond(404, ['ok' => false, 'error' => 'backup_not_found']);
    }
    header('Content-Type: application/octet-stream');
    header('Content-Length: ' . filesize($latest));
    readfile($latest);
    exit;
}

if (routeEndsWith($path, '/v1/sync/pull') && $method === 'GET') {
    $cursor = max(0, (int) ($_GET['cursor'] ?? 0));
    $deviceId = trim((string) ($_GET['deviceId'] ?? ''));
    if ($deviceId === '') {
        respond(400, ['ok' => false, 'error' => 'device_id_required']);
    }
    $limit = 500;
    $db = pdo($config);
    // Read all cursor rows, including this device's own changes, so the cursor
    // always advances. Own changes are filtered only from the response body.
    $statement = $db->prepare(
        'SELECT cursor_id, change_id, entity_type, entity_id, operation, version, updated_at_utc, device_id, deleted_at_utc, payload_json, clock_json
         FROM sync_changes
         WHERE owner_id = :owner AND cursor_id > :cursor
         ORDER BY cursor_id ASC
         LIMIT ' . $limit
    );
    $statement->execute(['cursor' => $cursor, 'owner'=>$scopeId]);
    $rows = $statement->fetchAll();
    $types = isset($_GET['types']) ? array_filter(explode(',', (string)$_GET['types'])) : null;
    $changes = [];
    $nextCursor = $cursor;
    foreach ($rows as $row) {
        $nextCursor = max($nextCursor, (int) $row['cursor_id']);
        if ((string) $row['device_id'] === $deviceId) {
            continue;
        }
        if ($types !== null && !in_array($row['entity_type'], $types, true)) continue;
        $changes[] = rowToEnvelope($row);
    }
    respond(200, [
        'ok' => true,
        'changes' => $changes,
        'nextCursor' => (string) $nextCursor,
        'hasMore' => count($rows) === $limit,
    ]);
}

if (routeEndsWith($path, '/v1/sync/push') && $method === 'POST') {
    $body = readJsonBody();
    $deviceId = trim((string) ($body['deviceId'] ?? ''));
    $rawChanges = $body['changes'] ?? [];
    if ($deviceId === '' || !is_array($rawChanges)) {
        respond(400, ['ok' => false, 'error' => 'invalid_push']);
    }
    if (count($rawChanges)>100) respond(413,['error'=>'batch_too_large']);
    $db = pdo($config);
    $selectChange = $db->prepare(
        'SELECT * FROM sync_changes WHERE change_id = ? AND owner_id = ? LIMIT 1'
    );
    $selectEntity = $db->prepare(
        'SELECT entity_type, entity_id, operation, version, updated_at_utc, device_id, deleted_at_utc, payload_json, clock_json
         FROM sync_entities WHERE entity_type = ? AND entity_id = ? AND owner_id = ? FOR UPDATE'
    );
    $upsertEntity = $db->prepare(
        'INSERT INTO sync_entities
          (entity_type, entity_id, operation, version, updated_at_utc, device_id, deleted_at_utc, payload_json, clock_json, owner_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
          operation = VALUES(operation), version = VALUES(version), updated_at_utc = VALUES(updated_at_utc),
          device_id = VALUES(device_id), deleted_at_utc = VALUES(deleted_at_utc), payload_json = VALUES(payload_json), clock_json = VALUES(clock_json)'
    );
    $insertChange = $db->prepare(
        'INSERT INTO sync_changes
          (change_id, entity_type, entity_id, operation, version, updated_at_utc, device_id, deleted_at_utc, payload_json, clock_json, owner_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $accepted = [];
    $conflicts = [];
    try {
        $db->beginTransaction();
        foreach ($rawChanges as $rawChange) {
            if (!is_array($rawChange)) {
                continue;
            }
            $change = normalizeChange($rawChange, $deviceId);
            $selectChange->execute([$change['changeId'],$scopeId]);
            $storedChange = $selectChange->fetch();
            if ($storedChange) {
                if (!sameChange(rowToEnvelope($storedChange), $change)) {
                    $db->rollBack();
                    respond(409, ['ok'=>false, 'error'=>'change_id_reused']);
                }
                // Only an identical retry can acknowledge a committed change.
                $accepted[] = $change['changeId'];
                continue;
            }

            $selectEntity->execute([$change['entityType'], $change['entityId'],$scopeId]);
            $existing = $selectEntity->fetch();
            $accept = false;
            $acknowledgeOnly = false;
            if (!$existing) {
                $accept = true;
            } else {
                $remoteVersion = (int) $existing['version'];
                $incomingVersion = (int) $change['version'];
                $sameContent =
                    (string) $existing['operation'] === $change['operation'] &&
                    (string) $existing['updated_at_utc'] === $change['updatedAtUtc'] &&
                    (string) $existing['device_id'] === $change['deviceId'] &&
                    (string) ($existing['deleted_at_utc'] ?? '') === (string) ($change['deletedAtUtc'] ?? '') &&
                    json_decode((string) $existing['payload_json'], true) == $change['payload'];

                $order = clockOrder($change['clock'], normalizeClock(json_decode($existing['clock_json'] ?? '{}', true), (string)$existing['device_id'], $remoteVersion));
                if ($order === 'after') {
                    $accept = true;
                } elseif ($order === 'before' || ($order === 'equal' && $sameContent)) {
                    $acknowledgeOnly = true;
                } else {
                    $conflicts[] = ['local'=>$change, 'remote'=>rowToEnvelope($existing)];
                }
            }
            if ($acknowledgeOnly) {
                $accepted[] = $change['changeId'];
                continue;
            }
            if (!$accept) {
                continue;
            }
            $payloadJson = json_encode($change['payload'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
            $entityValues = [
                $change['entityType'],
                $change['entityId'],
                $change['operation'],
                $change['version'],
                $change['updatedAtUtc'],
                $change['deviceId'],
                $change['deletedAtUtc'],
                $payloadJson,
                json_encode($change['clock'], JSON_THROW_ON_ERROR),
                $scopeId,
            ];
            $changeValues = [
                $change['changeId'],
                ...$entityValues,
            ];
            $upsertEntity->execute($entityValues);
            $insertChange->execute($changeValues);
            $accepted[] = $change['changeId'];
        }
        $db->commit();
    } catch (Throwable $error) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        respond(500, ['ok' => false, 'error' => 'sync_push_failed']);
    }
    respond(200, ['ok' => true, 'accepted' => $accepted, 'conflicts' => $conflicts]);
}

respond(404, ['ok' => false, 'error' => 'route_not_found']);
