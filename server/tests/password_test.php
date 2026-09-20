<?php
declare(strict_types=1);
require __DIR__.'/../shared-hosting/public/passwords.php';
function checkPassword(bool $ok,string $message): void { if(!$ok)throw new RuntimeException($message); }
$prefix=str_repeat('a',72);
$hash=rahaPasswordHash($prefix.'correct');
checkPassword(rahaPasswordVerify($prefix.'correct',$hash),'long password accepted');
checkPassword(!rahaPasswordVerify($prefix.'wrong',$hash),'suffix must matter');
checkPassword(!rahaPasswordVerify($prefix,$hash),'truncation rejected');
checkPassword(!rahaPasswordVerify('test','raha-pbkdf2-sha256$999999999$x$x'),'unbounded work rejected');
$legacy=password_hash('legacy-password',PASSWORD_BCRYPT,['cost'=>4]);
checkPassword(rahaPasswordVerify('legacy-password',$legacy),'legacy remains usable');
checkPassword(rahaPasswordCanUpgrade('legacy-password',$legacy),'unambiguous legacy upgrade');
checkPassword(!rahaPasswordCanUpgrade($prefix.'suffix',$legacy),'ambiguous legacy suffix not migrated');
echo "Password tests: 7 assertions passed\n";
