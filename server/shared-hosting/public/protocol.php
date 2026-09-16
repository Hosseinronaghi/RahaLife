<?php
declare(strict_types=1);

function normalizeChange(array $change, string $fallbackDeviceId = ''): array
{
    $changeId = trim((string) ($change['changeId'] ?? ''));
    $entityType = trim((string) ($change['entityType'] ?? ''));
    $entityId = trim((string) ($change['entityId'] ?? ''));
    $operation = (string) ($change['operation'] ?? 'upsert');
    $version = (int) ($change['version'] ?? 1);
    $updatedAtUtc = trim((string) ($change['updatedAtUtc'] ?? ''));
    $deviceId = trim((string) ($change['deviceId'] ?? $fallbackDeviceId));
    $deletedAtUtc = isset($change['deletedAtUtc']) ? (string) $change['deletedAtUtc'] : null;
    $payload = $change['payload'] ?? [];
    if ($entityType === '' || $entityId === '' || $updatedAtUtc === '' || $deviceId === '') {
        respond(400, ['ok' => false, 'error' => 'invalid_change']);
    }
    if (!in_array($operation, ['upsert', 'delete'], true)) {
        respond(400,['error'=>'invalid_operation']);
    }
    if(!is_array($payload))respond(400,['error'=>'invalid_payload']);
    if(strlen($entityType)>120 || strlen($entityId)>120 || strlen($deviceId)>120 || strlen($changeId)>160)respond(400,['error'=>'identifier_too_long']);
    if($operation==='delete' && !$deletedAtUtc)$deletedAtUtc=$updatedAtUtc;
    if($operation==='upsert')$deletedAtUtc=null;
    if ($changeId === '') {
        $changeId = 'legacy-' . hash('sha256', json_encode([
            $entityType, $entityId, $operation, $version, $updatedAtUtc, $deviceId, $deletedAtUtc, $payload,
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }
    return [
        'clock' => normalizeClock($change['clock'] ?? null, $deviceId, max(1, $version)),
        'changeId' => $changeId,
        'entityType' => $entityType,
        'entityId' => $entityId,
        'operation' => $operation,
        'version' => max(1, $version),
        'updatedAtUtc' => $updatedAtUtc,
        'deviceId' => $deviceId,
        'deletedAtUtc' => $deletedAtUtc,
        'payload' => is_array($payload) ? $payload : [],
    ];
}

function normalizeClock($raw, string $device, int $version): array {
    if (!is_array($raw) || !$raw) return [$device => $version];
    if (count($raw) > 256) respond(400, ['error'=>'clock_too_large']);
    $result = [];
    foreach ($raw as $key=>$value) {
        if (!is_string($key) || strlen($key)>160 || !is_int($value) || $value<0) respond(400,['error'=>'invalid_clock']);
        $result[$key]=$value;
    }
    return $result;
}
function clockOrder(array $a,array $b): string {
    $less=false; $greater=false;
    foreach (array_unique(array_merge(array_keys($a),array_keys($b))) as $key) {
        $less = $less || (($a[$key] ?? 0) < ($b[$key] ?? 0));
        $greater = $greater || (($a[$key] ?? 0) > ($b[$key] ?? 0));
    }
    return $less && $greater ? 'concurrent' : ($less ? 'before' : ($greater ? 'after' : 'equal'));
}

function rowToEnvelope(array $row): array
{
    $payload = json_decode((string) $row['payload_json'], true);
    return [
        'clock' => normalizeClock(json_decode($row['clock_json'] ?? '{}', true), (string)$row['device_id'], (int)$row['version']),
        'changeId' => $row['change_id'] ?? null,
        'entityType' => $row['entity_type'],
        'entityId' => $row['entity_id'],
        'operation' => $row['operation'],
        'version' => (int) $row['version'],
        'updatedAtUtc' => $row['updated_at_utc'],
        'deviceId' => $row['device_id'],
        'deletedAtUtc' => $row['deleted_at_utc'],
        'payload' => is_array($payload) ? $payload : [],
    ];
}

