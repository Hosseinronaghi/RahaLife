<?php
declare(strict_types=1);
require __DIR__.'/../shared-hosting/public/protocol.php';
function respond(int $status,array $body): never {throw new RuntimeException((string)$status);}
function check(bool $ok,string $label): void {if(!$ok)throw new RuntimeException($label);echo "PASS $label\n";}
check(clockOrder(['A'=>9],['A'=>1,'B'=>1])==='concurrent','independent edits with unequal scalar versions');
check(clockOrder(['A'=>9,'B'=>2],['A'=>1,'B'=>1])==='after','descendant');
check(clockOrder(['A'=>1],['A'=>1,'B'=>1])==='before','ancestor');
check(clockOrder(['A'=>1,'B'=>2],['B'=>2,'A'=>1])==='equal','key order');
check(normalizeClock(null,'old',7)===['old'=>7],'legacy fallback');
$c=normalizeChange(['changeId'=>'exact-id','entityType'=>'note','entityId'=>'one','operation'=>'delete','version'=>3,'deviceId'=>'A','updatedAtUtc'=>'2026-09-15T10:00:00Z','payload'=>['id'=>'one']]);
check($c['deletedAtUtc']===$c['updatedAtUtc'],'delete timestamp normalized');
check($c['changeId']==='exact-id','acknowledgement identity preserved');
try {normalizeClock(['A'=>-1],'A',1);throw new RuntimeException('Negative clock accepted');}catch(RuntimeException $e){check($e->getMessage()==='400','negative clock rejected');}
