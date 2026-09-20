<?php
declare(strict_types=1);
require __DIR__.'/../shared-hosting/public/backup_store.php';
$directory = sys_get_temp_dir() . '/raha-backup-test-' . bin2hex(random_bytes(8));
function verify(bool $value, string $label): void {
    if (!$value) throw new RuntimeException($label);
    echo "PASS $label\n";
}
try {
    for ($i=0; $i<12; $i++) {
        $name = writeBackup($directory, 'backup-' . $i, 3);
        verify(file_get_contents($directory . '/latest.rahabackup') === 'backup-' . $i, 'latest complete ' . $i);
        verify(is_file($directory . '/' . $name), 'acknowledged archive exists ' . $i);
    }
    verify(count(glob($directory . '/Raha-Life-Backup-*.rahabackup')) === 3, 'retention bounded');
    verify(count(glob($directory . '/upload-*')) === 0, 'temporary files cleaned');
    try { writeBackup($directory, '', 3); throw new RuntimeException('Empty accepted'); }
    catch (InvalidArgumentException $e) { echo "PASS empty rejected\n"; }
    verify(file_get_contents($directory . '/latest.rahabackup') === 'backup-11', 'failed upload preserves latest');
} finally {
    if (is_dir($directory)) {
        foreach (scandir($directory) as $file) if ($file !== '.' && $file !== '..') unlink($directory . '/' . $file);
        rmdir($directory);
    }
}
