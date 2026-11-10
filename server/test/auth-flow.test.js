import test from 'node:test';
import assert from 'node:assert/strict';
import {createApp} from '../src/app.js';
import {hash} from '../src/domain.js';
import {MemoryDb} from '../test-support/memory.js';

async function fixture(t) {
 const db=new MemoryDb(),nonces=new Map();
 const oauth={generateAuthUrl({state,nonce,prompt}){assert.equal(prompt,'select_account');nonces.set(state,nonce);return `https://accounts.google.com/?state=${state}`;},async getToken(code){return {tokens:{id_token:code}};},async verifyIdToken({idToken}){return {getPayload:()=>({sub:'existing-google-account',name:'Returning player',nonce:nonces.get(idToken)})};}};
 const app=createApp({db,client:db,oauth,play:{},baseUrl:'https://example.test',clientId:'test'});
 const server=app.listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));
 t.after(()=>{server.closeAllConnections();return new Promise(resolve=>server.close(resolve));});
 const base=`http://127.0.0.1:${server.address().port}`;
 const post=async(path,body,token)=>fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify(body)});
 async function start() {
  const verifier='proof-for-this-device-'.repeat(4);
  const response=await post('/auth/start',{challenge:hash(verifier),accountMode:'self'});
  const flow=await response.json();assert.equal(flow.expiresIn,900);
  const noticeResponse=await fetch(base+`/auth/google/start?flow=${flow.flow}`);
  const notice=await noticeResponse.text();
  assert.match(notice,/<h1>Sign in with Google<\/h1>/);
  assert.match(notice,/sign in with your existing Google account/);
  const noticeToken=notice.match(/name="noticeToken" value="([^"]+)"/)[1];
  const authorized=await fetch(base+'/auth/google/authorize',{method:'POST',redirect:'manual',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({flow:flow.flow,noticeToken,acknowledged:'yes'})});
  assert.equal(authorized.status,303);
  return {flow:flow.flow,verifier,cookie:authorized.headers.get('set-cookie').split(';')[0]};
 }
 const callback=state=>fetch(base+`/auth/google/callback?state=${state.flow}&code=${state.flow}`,{headers:{Cookie:state.cookie,'User-Agent':'Chrome Android'}});
 const poll=state=>post('/auth/poll',{flow:state.flow,verifier:state.verifier});
 return {db,base,post,start,callback,poll};
}

test('existing Google sign-in keeps progress and exposes a persistent Android return button',async t=>{
 const f=await fixture(t);
 const userId=hash('google:existing-google-account');
 const save={campaign:{coins:1234,highest_unlocked_level:435}};
 await f.db.collection('users').insertOne({_id:userId,name:'Before',wallet:500,revision:7,save});
 const state=await f.start();
 const response=await f.callback(state);assert.equal(response.status,200);
 const html=await response.text();
 assert.equal(response.headers.get('cache-control'),'no-store');
 assert.equal(response.headers.get('x-auth-return-version'),'2');
 assert.match(html,/id="return-to-game"/);
 assert.match(html,/>Return to Save the Baby Game<\/a>/);
 assert.match(html,/intent:\/\/auth\/complete#Intent;scheme=savethebaby;package=com\.savethebaby\.game;/);
 assert.doesNotMatch(html,/http-equiv="refresh"/);
 assert.ok(!html.includes(state.verifier));
 assert.ok(!html.includes(state.cookie));
 const login=await (await f.poll(state)).json();
 assert.equal(login.userId,userId);assert.equal(login.wallet,500);assert.equal(login.revision,7);assert.deepEqual(login.save,save);
 const fallback=await fetch(f.base+'/auth/return',{headers:{'User-Agent':'Chrome Android'}});
 assert.equal(fallback.status,200);assert.match(await fallback.text(),/Return to Save the Baby Game/);
});

test('first-time Google registration retains the return button after the game redeems login',async t=>{
 const f=await fixture(t),state=await f.start();
 const response=await f.callback(state);
 assert.equal(response.status,200);
 const html=await response.text();
 assert.match(html,/data-sign-in-state="complete"/);
 assert.match(html,/>Return to Save the Baby Game<\/a>/);
 assert.doesNotMatch(html,/http-equiv="refresh"/);
 const profile=await (await f.poll(state)).json();
 assert.equal(profile.save,null);
 assert.equal(profile.wallet,0);
 const fallback=await fetch(f.base+'/auth/return');
 assert.equal(fallback.status,200);
 assert.match(await fallback.text(),/href="savethebaby:\/\/auth\/complete"/);
});

test('lost and concurrent poll responses recover the same session, never a false expired login',async t=>{
 const f=await fixture(t),state=await f.start();await f.callback(state);
 const first=await (await f.poll(state)).json(); // Simulate the mobile app losing this HTTP response.
 const retries=await Promise.all(Array.from({length:4},()=>f.poll(state)));
 for(const response of retries){assert.equal(response.status,200);assert.equal((await response.json()).token,first.token);}
 assert.equal(f.db.tables.get('sessions').size,1);
 assert.equal((await f.post('/auth/poll',{flow:state.flow,verifier:'wrong'.repeat(12)})).status,400);
 assert.equal((await f.post('/auth/poll',{flow:{$ne:null},verifier:state.verifier})).status,400);
 assert.equal((await f.post('/v1/logout',{},first.token)).status,200);
 assert.equal((await f.poll(state)).status,401,'old login proof cannot resurrect a logged-out session');
 assert.equal(f.db.tables.get('sessions').size,0);
});

test('Google cancellation reaches the game as a terminal failure with a visible return button',async t=>{
 const f=await fixture(t),state=await f.start();
 const canceled=await fetch(f.base+`/auth/google/callback?state=${state.flow}&error=access_denied`,{headers:{Cookie:state.cookie,'User-Agent':'Chrome Android'}});
 assert.equal(canceled.status,400);const page=await canceled.text();assert.match(page,/Return to Save the Baby Game/);assert.doesNotMatch(page,/http-equiv="refresh"/);
 const poll=await f.poll(state);assert.equal(poll.status,400);assert.match((await poll.json()).error,/canceled/);
});

test('a database failure cannot consume the login proof without creating its session',async t=>{
 const f=await fixture(t),state=await f.start();await f.callback(state);
 // Force a failure after claiming the flow inside the same transaction.
 const collection=f.db.collection.bind(f.db);
 // createApp captures collections; fail the first write to their shared Map.
 const rows=f.db.tables.get('sessions')||new Map();f.db.tables.set('sessions',rows);
 const set=rows.set.bind(rows);let reject=true;
 rows.set=(...args)=>{if(reject){reject=false;throw new Error('Test database write failure');}return set(...args);};
 const failed=await f.poll(state);assert.equal(failed.status,500);
 assert.equal((await collection('flows').findOne({_id:state.flow})).status,'complete');
 const retry=await f.poll(state);assert.equal(retry.status,200);assert.ok((await retry.json()).token);
});
