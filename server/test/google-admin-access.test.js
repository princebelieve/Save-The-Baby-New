import test from 'node:test';
import assert from 'node:assert/strict';
import {ADMOB_SCOPE, desktopSettings, validState, callbackServer, safeFailure, inspectPlayVisibility} from '../scripts/google-admin-access.js';

test('visibility audit reads production data and discards its edit without publishing',async()=>{
 const calls=[];
 const client={async request(request){
  calls.push(request);
  if(request.method==='POST')return {data:{id:'temporary-edit'}};
  if(request.method==='GET')return {data:request.url.endsWith('/tracks')?{tracks:[{track:'production'}]}:{countries:[{countryCode:'NG'}]}};
  return {data:{}};
 }};
 const report=await inspectPlayVisibility(client);
 assert.equal(report.temporaryEditDeleted,true);
 assert.equal(report.publishedChanges,false);
 assert.equal(report.tracks.tracks[0].track,'production');
 assert.equal(calls.filter(call=>call.method==='GET').length,3);
 assert.equal(calls.at(-1).method,'DELETE');
 assert.ok(calls.every(call=>!call.url.includes(':commit')&&call.method!=='PUT'));
});

test('visibility audit still discards the edit if a production read fails',async()=>{
 const calls=[];
 const client={async request(request){calls.push(request);if(request.method==='POST')return {data:{id:'temporary-edit'}};if(request.method==='GET')throw {response:{status:403}};return {data:{}};}};
 const report=await inspectPlayVisibility(client);
 assert.match(report.productionCountries.error,/403/);
 assert.equal(report.temporaryEditDeleted,true);
 assert.equal(calls.at(-1).method,'DELETE');
});

test('admin connection accepts only the correct desktop OAuth project',()=>{
 const installed={client_id:'sample-client',client_secret:'sample-secret',project_id:'save-the-baby-513514'};
 assert.equal(desktopSettings({installed}),installed);
 assert.throws(()=>desktopSettings({web:installed}),/Desktop app/);
 assert.throws(()=>desktopSettings({installed:{...installed,project_id:'other-project'}}),/different/);
 assert.equal(ADMOB_SCOPE,'https://www.googleapis.com/auth/admob.readonly');
});

test('callback state must match exactly and errors never expose credentials',()=>{
 assert.equal(validState('abc','abc'),true);
 for(const actual of [null,undefined,'ab','abd'])assert.equal(validState(actual,'abc'),false);
 const error={response:{status:403,data:{token:'private-token'}},config:{headers:{Authorization:'private-token'}},message:'private-token'};
 assert.match(safeFailure(error),/403/);
 assert.ok(!safeFailure(error).includes('private-token'));
 assert.ok(!safeFailure({message:'private-token'}).includes('private-token'));
});

test('OAuth callback rejects invalid state, handles success once and keeps credentials out of HTML',async t=>{
 let calls=0;
 const callback=callbackServer('expected-state',async code=>{assert.equal(code,'authorization-code');calls++;});
 t.after(()=>callback.close());
 const url=await callback.ready;
 assert.equal((await fetch(url+'?state=wrong&code=authorization-code')).status,400);
 assert.equal((await fetch(url+'?state=expected-state&code=authorization-code',{method:'POST'})).status,405);
 assert.equal(calls,0);
 const result=await fetch(url+'?state=expected-state&code=authorization-code');
 assert.equal(result.status,200);
 assert.equal(result.headers.get('cache-control'),'no-store');
 assert.ok(!(await result.text()).includes('authorization-code'));
 await callback.done;
 assert.equal((await fetch(url+'?state=expected-state&code=authorization-code')).status,409);
 assert.equal(calls,1);
});

test('cancellation and timeout release the pending authorization',async t=>{
 const canceled=callbackServer('state',async()=>assert.fail('must not exchange token'));
 t.after(()=>canceled.close());
 const url=await canceled.ready;
 const rejected=assert.rejects(canceled.done,/canceled/);
 assert.equal((await fetch(url+'?state=state&error=access_denied')).status,400);
 await rejected;
 const timeout=callbackServer('state',async()=>{},20);
 t.after(()=>timeout.close());
 await timeout.ready;
 await assert.rejects(timeout.done,/timed out/);
});
