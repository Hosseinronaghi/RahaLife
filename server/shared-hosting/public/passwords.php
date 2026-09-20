<?php
declare(strict_types=1);

// New hashes support the complete UTF-8 password, including passwords over 72 bytes.
// Argon2id is preferred. PBKDF2 is the portable fallback for shared PHP hosting.
function rahaPasswordHash(string $password): string {
    if (defined('PASSWORD_ARGON2ID') && in_array('argon2id', password_algos(), true)) {
        return password_hash($password, PASSWORD_ARGON2ID, ['memory_cost'=>65536, 'time_cost'=>3, 'threads'=>1]);
    }
    $salt = random_bytes(16);
    $digest = hash_pbkdf2('sha256', $password, $salt, 600000, 32, true);
    return 'raha-pbkdf2-sha256$600000$'.base64_encode($salt).'$'.base64_encode($digest);
}
function rahaPasswordVerify(string $password, string $hash): bool {
    if (!str_starts_with($hash, 'raha-pbkdf2-sha256$')) {
        return password_verify($password, $hash);
    }
    $parts = explode('$', $hash);
    if (count($parts)!==4 || $parts[1]!=='600000') return false;
    $salt = base64_decode($parts[2], true);
    $expected = base64_decode($parts[3], true);
    if ($salt===false || strlen($salt)!==16 || $expected===false || strlen($expected)!==32) return false;
    return hash_equals($expected, hash_pbkdf2('sha256', $password, $salt, 600000, 32, true));
}
function rahaPasswordCanUpgrade(string $password, string $hash): bool {
    // Legacy bcrypt never stored bytes after 72. Do not silently turn an
    // ambiguous suffix into the user's new password; preserve compatibility.
    return str_starts_with($hash, '$2') && strlen($password) < 72;
}
