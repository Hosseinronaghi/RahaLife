<?php
declare(strict_types=1);

/** Store only server-named archives. Readers see complete files via atomic rename. */
function writeBackup(string $directory, string $bytes, int $keep): string
{
    if ($bytes === '') throw new InvalidArgumentException('Empty backup');
    if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
        throw new RuntimeException('Storage unavailable');
    }
    $lock = fopen($directory . '/.backup.lock', 'c');
    if ($lock === false) throw new RuntimeException('Lock unavailable');
    $temporary = [];
    try {
        if (!flock($lock, LOCK_EX)) throw new RuntimeException('Lock unavailable');
        $name = 'Raha-Life-Backup-' . gmdate('Ymd\THis\Z') . '-' . bin2hex(random_bytes(8)) . '.rahabackup';
        foreach ([$directory . '/' . $name, $directory . '/latest.rahabackup'] as $destination) {
            $tmp = tempnam($directory, 'upload-');
            if ($tmp === false) throw new RuntimeException('Temporary file unavailable');
            $temporary[] = $tmp;
            if (file_put_contents($tmp, $bytes, LOCK_EX) !== strlen($bytes) || !rename($tmp, $destination)) {
                throw new RuntimeException('Backup write failed');
            }
        }
        $files = glob($directory . '/Raha-Life-Backup-*.rahabackup') ?: [];
        // Always retain the upload just acknowledged, including same-second uploads.
        usort($files, static function(string $a, string $b) use ($name): int {
            if (basename($a) === $name) return -1;
            if (basename($b) === $name) return 1;
            return (filemtime($b) ?: 0) <=> (filemtime($a) ?: 0);
        });
        foreach (array_slice($files, max(1, min(100, $keep))) as $file) {
            if (!unlink($file)) throw new RuntimeException('Archive pruning failed');
        }
        return $name;
    } finally {
        foreach ($temporary as $tmp) if (is_file($tmp)) unlink($tmp);
        flock($lock, LOCK_UN);
        fclose($lock);
    }
}
