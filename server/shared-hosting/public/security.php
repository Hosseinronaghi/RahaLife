<?php
declare(strict_types=1);

/** Exact browser origins only. Native requests without Origin remain supported. */
function rahaSecurityHeaders(array $config, array $server): array {
    $headers = ['Content-Type: application/json; charset=utf-8', 'Cache-Control: no-store',
        'X-Content-Type-Options: nosniff', 'Referrer-Policy: no-referrer',
        'Access-Control-Allow-Headers: Authorization, Content-Type, X-Raha-Client, X-Raha-Backup-Name',
        'Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS', 'Vary: Origin'];
    $origin = (string)($server['HTTP_ORIGIN'] ?? '');
    if ($origin !== '') {
        $allowed = array_filter(array_map('trim', explode(',', (string)($config['cors_origin'] ?? ''))));
        if (!in_array($origin, $allowed, true) || str_contains($origin, "\r") || str_contains($origin, "\n")) {
            throw new DomainException('origin_not_allowed');
        }
        $headers[] = 'Access-Control-Allow-Origin: ' . $origin;
    }
    if (($server['HTTPS'] ?? '') === 'on' || (int)($server['SERVER_PORT'] ?? 0) === 443) {
        // Do not trust client-supplied forwarded headers or force HSTS on HTTP dev servers.
        $headers[] = 'Strict-Transport-Security: max-age=31536000';
    }
    return $headers;
}

/** Locked file buckets work on shared hosting and serialize concurrent requests. */
function rahaRateAllowed(string $directory, string $identity, int $limit, int $window, ?int $now=null): bool {
    $now ??= time();
    if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
        throw new RuntimeException('rate_store_unavailable');
    }
    $path = $directory . '/' . hash('sha256', $identity) . '.json';
    $handle = fopen($path, 'c+');
    if (!$handle) throw new RuntimeException('rate_store_unavailable');
    try {
        if (!flock($handle, LOCK_EX)) throw new RuntimeException('rate_lock_unavailable');
        $raw = stream_get_contents($handle);
        $state = $raw === '' ? null : json_decode($raw, true, 4, JSON_THROW_ON_ERROR);
        if (!is_array($state) || $now >= (int)$state['start'] + $window) $state = ['start'=>$now, 'count'=>0];
        if ((int)$state['count'] >= $limit) return false;
        $state['count']++;
        $encoded = json_encode($state, JSON_THROW_ON_ERROR);
        rewind($handle);
        if (!ftruncate($handle, 0) || fwrite($handle, $encoded) !== strlen($encoded) || !fflush($handle)) {
            throw new RuntimeException('rate_write_failed');
        }
        return true;
    } finally { flock($handle, LOCK_UN); fclose($handle); }
}
