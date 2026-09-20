<?php
declare(strict_types=1);
require_once __DIR__ . '/passwords.php';
// Included by index.php after its shared helpers have been declared.
function accountRoute(array $config, string $path, string $method): ?string {
    $db=pdo($config);
    if ($method==='POST' && (routeEndsWith($path,'/v1/account/register') || routeEndsWith($path,'/v1/account/login'))) {
        $body=readJsonBody();
        if(!is_string($body['username']??null) || !is_string($body['password']??null)) respond(400,['error'=>'invalid_credentials_format']);
        $username=strtolower(trim((string)($body['username']??'')));
        $password=(string)($body['password']??'');
        if(!preg_match('/^[a-z0-9_.-]{3,64}$/',$username)||strlen($password)<10||strlen($password)>512) respond(400,['error'=>'invalid_credentials_format']);
        // Independent account and address limits also cover rotating usernames/IPs.
        // REMOTE_ADDR is trusted; untrusted forwarded headers are deliberately ignored.
        $address=(string)($_SERVER['REMOTE_ADDR']??'unknown');
        $limits=[hash('sha256','pair:'.$address.':'.$username)=>10,
                 hash('sha256','account:'.$username)=>30,
                 hash('sha256','address:'.$address)=>60];
        foreach($limits as $key=>$limit) {
            $q=$db->prepare('SELECT COUNT(*) FROM auth_attempts WHERE attempt_key=? AND created_at>DATE_SUB(NOW(),INTERVAL 15 MINUTE)');$q->execute([$key]);
            if((int)$q->fetchColumn()>=$limit)respond(429,['error'=>'try_later']);
        }
        foreach($limits as $key=>$limit) {
            $db->prepare('INSERT INTO auth_attempts(attempt_key) VALUES(?)')->execute([$key]);
        }
        $db->exec('DELETE FROM auth_attempts WHERE created_at<DATE_SUB(NOW(),INTERVAL 1 DAY) LIMIT 500');
        if(routeEndsWith($path,'/v1/account/register')){
            $code=(string)(getenv('RAHA_REGISTRATION_CODE')?:($config['registration_code']??''));
            if($code==='' || !hash_equals($code,(string)($body['registrationCode']??'')))respond(403,['error'=>'registration_invitation_required']);
            $id=bin2hex(random_bytes(16));
            try{$db->prepare('INSERT INTO raha_users(id,username,password_hash) VALUES(?,?,?)')->execute([$id,$username,rahaPasswordHash($password)]);}catch(PDOException $e){respond(409,['error'=>'username_unavailable']);}
        }else{
            $q=$db->prepare('SELECT id,password_hash FROM raha_users WHERE username=?');$q->execute([$username]);$user=$q->fetch();
            if(!$user || !rahaPasswordVerify($password,$user['password_hash']))respond(401,['error'=>'invalid_credentials']);
            $id=$user['id'];
            if(rahaPasswordCanUpgrade($password,$user['password_hash'])) {
                $db->prepare('UPDATE raha_users SET password_hash=? WHERE id=? AND password_hash=?')->execute([rahaPasswordHash($password),$id,$user['password_hash']]);
            }
        }
        $token=bin2hex(random_bytes(32));
        $db->prepare('INSERT INTO raha_sessions(token_hash,account_id,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))')->execute([hash('sha256',$token),$id]);
        respond(200,['ok'=>true,'accountId'=>$id,'username'=>$username,'token'=>$token]);
    }
    if($method==='POST' && routeEndsWith($path,'/v1/account/logout')) {
        $db->prepare('DELETE FROM raha_sessions WHERE token_hash=?')->execute([hash('sha256',bearerToken())]);
        respond(200,['ok'=>true]);
    }
    $q=$db->prepare('SELECT account_id FROM raha_sessions WHERE token_hash=? AND expires_at>NOW()');
    $q->execute([hash('sha256',bearerToken())]);return $q->fetchColumn()?:null;
}
function mutualFriend(PDO $db,string $a,string $b): bool {
    $q=$db->prepare("SELECT status FROM connections WHERE low_id=? AND high_id=?");$q->execute([min($a,$b),max($a,$b)]);return $q->fetchColumn()==='accepted';
}
function collaborationRoute(array $config,string $path,string $method,string $me): void {
    if(!str_contains($path,'/v1/collab/'))return;
    if($me==='personal')respond(403,['error'=>'account_login_required']);
    $db=pdo($config);
    if(routeEndsWith($path,'/v1/collab/friends')){
        if($method==='POST'){
            $b=readJsonBody();$q=$db->prepare('SELECT id FROM raha_users WHERE username=?');$q->execute([strtolower(trim((string)($b['username']??'')))]);$other=$q->fetchColumn();
            if(!$other||$other===$me)respond(404,['error'=>'user_not_found']);
            $low=min($me,$other);$high=max($me,$other);$action=$b['action']??'request';
            $db->beginTransaction();$q=$db->prepare('SELECT * FROM connections WHERE low_id=? AND high_id=? FOR UPDATE');$q->execute([$low,$high]);$row=$q->fetch();
            if($action==='request'){
                if($row && in_array($row['status'],['blocked','accepted']))respond(409,['error'=>'connection_unavailable']);
                if(!$row)$db->prepare("INSERT INTO connections(low_id,high_id,requested_by,status) VALUES(?,?,?,'pending')")->execute([$low,$high,$me]);
            }elseif($action==='accept'){
                if(!$row||$row['status']!=='pending'||$row['requested_by']===$me)respond(403,['error'=>'not_an_incoming_request']);
                $db->prepare("UPDATE connections SET status='accepted' WHERE low_id=? AND high_id=?")->execute([$low,$high]);
            }elseif($action==='block'){
                $db->prepare("INSERT INTO connections(low_id,high_id,requested_by,status) VALUES(?,?,?,'blocked') ON DUPLICATE KEY UPDATE requested_by=VALUES(requested_by),status='blocked'")->execute([$low,$high,$me]);
                $db->prepare('DELETE FROM shared_records WHERE (owner_id=? AND recipient_id=?) OR (owner_id=? AND recipient_id=?)')->execute([$me,$other,$other,$me]);
            }elseif($action==='remove'){
                if($row && $row['status']==='blocked' && $row['requested_by']!==$me)respond(403,['error'=>'blocked']);
                $db->prepare('DELETE FROM connections WHERE low_id=? AND high_id=?')->execute([$low,$high]);
                $db->prepare('DELETE FROM shared_records WHERE (owner_id=? AND recipient_id=?) OR (owner_id=? AND recipient_id=?)')->execute([$me,$other,$other,$me]);
            }else respond(400,['error'=>'invalid_action']);
            $db->commit();respond(200,['ok'=>true]);
        }
        $q=$db->prepare('SELECT u.id,u.username,c.status,c.requested_by FROM connections c JOIN raha_users u ON u.id=IF(c.low_id=?,c.high_id,c.low_id) WHERE c.low_id=? OR c.high_id=?');$q->execute([$me,$me,$me]);respond(200,['friends'=>$q->fetchAll()]);
    }
    if(routeEndsWith($path,'/v1/collab/messages')){
        if($method==='POST'){
            $b=readJsonBody();$other=(string)($b['to']??'');$text=trim((string)($b['text']??''));
            if(!mutualFriend($db,$me,$other))respond(403,['error'=>'friendship_required']);
            if($text===''||strlen($text)>20000)respond(400,['error'=>'invalid_message']);
            $id=(string)($b['id']??'');if(!preg_match('/^[a-zA-Z0-9-]{16,64}$/',$id))respond(400,['error'=>'invalid_message_id']);
            $db->prepare('INSERT IGNORE INTO direct_messages(id,sender_id,recipient_id,body) VALUES(?,?,?,?)')->execute([$id,$me,$other,$text]);
            $q=$db->prepare('SELECT recipient_id,body FROM direct_messages WHERE sender_id=? AND id=?');$q->execute([$me,$id]);$stored=$q->fetch();
            if(!$stored || $stored['recipient_id']!==$other || $stored['body']!==$text)respond(409,['error'=>'message_id_reused']);
            respond(200,['ok'=>true]);
        }
        $other=(string)($_GET['peer']??'');if(!mutualFriend($db,$me,$other))respond(403,['error'=>'friendship_required']);
        $q=$db->prepare('SELECT * FROM direct_messages WHERE (sender_id=? AND recipient_id=?) OR (sender_id=? AND recipient_id=?) ORDER BY created_at DESC,id DESC LIMIT 200');$q->execute([$me,$other,$other,$me]);respond(200,['messages'=>array_reverse($q->fetchAll())]);
    }
    if(routeEndsWith($path,'/v1/collab/shared')){
        if($method==='POST'){
            $b=readJsonBody();$action=$b['action']??'create';$id=(string)($b['id']??'');
            if($action==='create'){
                $to=(string)($b['to']??'');if(!mutualFriend($db,$me,$to))respond(403,['error'=>'friendship_required']);
                $permission=($b['permission']??'read')==='edit'?'edit':'read';
                $payload=json_encode($b['payload']??[],JSON_THROW_ON_ERROR);if(strlen($payload)>262144)respond(413,['error'=>'shared_record_too_large']);
                $id=bin2hex(random_bytes(16));$db->prepare('INSERT INTO shared_records(id,owner_id,recipient_id,permission,payload_json,version) VALUES(?,?,?,?,?,1)')->execute([$id,$me,$to,$permission,$payload]);
            }else{
                $db->beginTransaction();$q=$db->prepare('SELECT * FROM shared_records WHERE id=? FOR UPDATE');$q->execute([$id]);$row=$q->fetch();
                if(!$row || ($row['owner_id']!==$me && ($row['recipient_id']!==$me || $row['permission']!=='edit')))respond(403,['error'=>'not_authorized']);
                if(!mutualFriend($db,$row['owner_id'],$row['recipient_id']))respond(403,['error'=>'friendship_required']);
                if($action==='revoke'){
                    if($row['owner_id']!==$me)respond(403,['error'=>'owner_required']);
                    $db->prepare('DELETE FROM shared_records WHERE id=?')->execute([$id]);
                }elseif($action==='update'){
                    if((int)($b['version']??0)!==(int)$row['version'])respond(409,['error'=>'conflict_reload','current'=>$row]);
                    $payload=json_encode($b['payload']??[],JSON_THROW_ON_ERROR);if(strlen($payload)>262144)respond(413,['error'=>'shared_record_too_large']);
                    $db->prepare('UPDATE shared_records SET payload_json=?,version=version+1 WHERE id=?')->execute([$payload,$id]);
                }else respond(400,['error'=>'invalid_action']);
                $db->commit();
            }respond(200,['ok'=>true,'id'=>$id]);
        }
        $q=$db->prepare('SELECT * FROM shared_records WHERE owner_id=? OR recipient_id=? ORDER BY id LIMIT 200');$q->execute([$me,$me]);respond(200,['records'=>$q->fetchAll()]);
    }
    respond(404,['error'=>'route_not_found']);
}
