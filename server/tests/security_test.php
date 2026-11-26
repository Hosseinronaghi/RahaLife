<?php
declare(strict_types=1);
require __DIR__.'/../shared-hosting/public/security.php';
if (($argv[1]??'') === 'worker') exit(rahaRateAllowed($argv[2], 'parallel', 10, 60, 100) ? 0 : 1);
function check(bool $value, string $message): void { if (!$value) throw new RuntimeException($message); }
$h=rahaSecurityHeaders(['cors_origin'=>'https://raha.example'],['HTTP_ORIGIN'=>'https://raha.example','HTTPS'=>'on']);
check(in_array('Access-Control-Allow-Origin: https://raha.example',$h,true),'exact origin');
check(in_array('Strict-Transport-Security: max-age=31536000',$h,true),'TLS HSTS');
check(!array_filter(rahaSecurityHeaders([],[]),fn($s)=>str_starts_with($s,'Strict-Transport-Security')),'no HSTS on plain HTTP');
foreach(['https://evil.example','https://raha.example.evil.example','null'] as $origin) {
    try { rahaSecurityHeaders(['cors_origin'=>'https://raha.example'],['HTTP_ORIGIN'=>$origin]); throw new RuntimeException('origin accepted'); }
    catch(DomainException $expected) {}
}
$dir=sys_get_temp_dir().'/raha-rate-'.bin2hex(random_bytes(6));
try {
    check(rahaRateAllowed($dir,'alice',2,60,100),'first');
    check(rahaRateAllowed($dir,'alice',2,60,101),'second');
    check(!rahaRateAllowed($dir,'alice',2,60,102),'limit');
    check(rahaRateAllowed($dir,'bob',2,60,102),'account partition');
    check(rahaRateAllowed($dir,'alice',2,60,160),'next window');
    $workers=[];
    for($i=0;$i<24;$i++) {
        $pipes=[];
        $process=proc_open([PHP_BINARY,'-n',__FILE__,'worker',$dir],[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes);
        if (!is_resource($process)) throw new RuntimeException('worker failed');
        foreach($pipes as $pipe) fclose($pipe);
        $workers[]=$process;
    }
    $accepted=0;
    foreach($workers as $worker) if(proc_close($worker)===0) $accepted++;
    check($accepted===10,'concurrent requests cannot bypass rate limit');
    echo "PASS: exact CORS, TLS headers, bounded rate windows and account partition\n";
} finally { foreach(glob($dir.'/*.json')?:[] as $file) unlink($file); if(is_dir($dir))rmdir($dir); }
