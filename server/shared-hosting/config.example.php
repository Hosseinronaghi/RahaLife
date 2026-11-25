<?php
return [
    'registration_code' => '', // Set a private invitation code to enable account registration.
    'db_dsn' => 'mysql:host=localhost;dbname=raha_sync;charset=utf8mb4',
    'db_user' => 'raha_sync',
    'db_password' => 'CHANGE_ME',
    'api_token' => 'CHANGE_TO_A_LONG_RANDOM_TOKEN',
    'storage_dir' => __DIR__ . '/storage',
    'max_backup_bytes' => 268435456, // 256 MB
    'keep_backup_versions' => 7,
    'session_days' => 7,
    'api_requests_per_minute' => 300,
    'account_requests_per_minute' => 240,
    'cors_origin' => '', // Comma-separated exact web origins, e.g. https://raha.example. Native apps do not need CORS.
];
