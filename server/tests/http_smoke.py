"""Run against a DISPOSABLE local test server. Creates random test accounts.
RAHA_TEST_URL defaults to http://127.0.0.1:8090; RAHA_REGISTRATION_CODE required.
"""
import json, os, uuid, urllib.request, urllib.error
BASE=os.environ.get('RAHA_TEST_URL','http://127.0.0.1:8090')
CODE=os.environ['RAHA_REGISTRATION_CODE']
def request(path, body=None, token=None, status=200):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    req=urllib.request.Request(BASE+path,data=None if body is None else json.dumps(body).encode(),headers=headers)
    try:
        with urllib.request.urlopen(req,timeout=20) as response: actual=response.status;data=response.read()
    except urllib.error.HTTPError as error: actual=error.code;data=error.read()
    assert actual==status,(path,actual,status,data)
    return json.loads(data)

def account():
    name='test_'+uuid.uuid4().hex[:12]
    result=request('/v1/account/register',{'username':name,'password':'Test-only-'+uuid.uuid4().hex,'registrationCode':CODE})
    return name,result['accountId'],result['token']

def main():
    a,aid,at=account();b,bid,bt=account();_,_,ct=account()
    request('/health',status=401)
    assert request('/health',token=at)['protocolVersion']==3
    def change(device,clock,title): return dict(changeId=str(uuid.uuid4()),entityType='home_entry',entityId='same-id',operation='upsert',version=sum(clock.values()),deviceId=device,clock=clock,updatedAtUtc='2026-09-15T10:00:00Z',payload={'id':'same-id','title':title})
    first=change('A',{'A':9},'A title')
    for _ in range(2): assert request('/v1/sync/push',{'deviceId':'A','changes':[first]},at)['accepted']==[first['changeId']]
    assert request('/v1/sync/pull?cursor=0&deviceId=B',token=at)['changes'][0]['payload']['title']=='A title'
    assert request('/v1/sync/pull?cursor=0&deviceId=B',token=bt)['changes']==[]
    selected=request('/v1/sync/pull?cursor=0&deviceId=B&types=rich_note',token=at)
    assert selected['changes']==[] and int(selected['nextCursor'])>0
    assert request('/v1/sync/pull?cursor=0&deviceId=B&types=',token=at)['changes']==[]
    assert len(request('/v1/sync/pull?cursor=0&deviceId=B&types=home_entry',token=at)['changes'])==1
    assert request('/v1/sync/push',{'deviceId':'A','changes':[first]},bt)['accepted']==[first['changeId']]
    conflict=request('/v1/sync/push',{'deviceId':'B','changes':[change('B',{'A':1,'B':1},'B title')]},at)
    assert len(conflict['conflicts'])==1 and conflict['accepted']==[]
    request('/v1/collab/messages',{'id':str(uuid.uuid4()),'to':bid,'text':'not friends'},at,status=403)
    request('/v1/collab/friends',{'username':b,'action':'request'},at)
    request('/v1/collab/friends',{'username':b,'action':'accept'},at,status=403)
    request('/v1/collab/friends',{'username':a,'action':'accept'},bt)
    message={'id':str(uuid.uuid4()),'to':bid,'text':'hello'}
    request('/v1/collab/messages',message,at);request('/v1/collab/messages',message,at)
    assert len(request('/v1/collab/messages?peer='+aid,token=bt)['messages'])==1
    request('/v1/collab/messages',{**message,'text':'different'},at,status=409)
    request('/v1/collab/messages',{'id':message['id'],'to':aid,'text':'reply'},bt)
    sid=request('/v1/collab/shared',{'to':bid,'permission':'read','payload':{'title':'Private'}},at)['id']
    edit={'action':'update','id':sid,'version':1,'payload':{'title':'Changed'}}
    request('/v1/collab/shared',edit,bt,status=403);request('/v1/collab/shared',edit,ct,status=403)
    request('/v1/collab/shared',edit,at);request('/v1/collab/shared',edit,at,status=409)
    request('/v1/collab/friends',{'username':b,'action':'block'},at)
    assert request('/v1/collab/shared',token=bt)['records']==[]
    request('/v1/collab/messages',{'id':str(uuid.uuid4()),'to':aid,'text':'blocked'},bt,status=403)
    request('/v1/account/logout',{},at);request('/health',token=at,status=401)
    print('PASS selective pull, account isolation, exact retry ACK, causal conflict, friendship, message deduplication, share permissions, CAS, revocation, logout')
if __name__=='__main__':main()
