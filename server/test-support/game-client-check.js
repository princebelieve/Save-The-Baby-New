import {spawn} from 'node:child_process';
import {createServer} from 'node:http';
import assert from 'node:assert/strict';
import {writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createApp} from '../src/app.js';
import {hash} from '../src/domain.js';
import {MemoryDb} from './memory.js';
const db=new MemoryDb(),token='game-client-test-token-00000000000000000000';
await db.collection('users').insertOne({_id:'test-user',name:'Test Player',wallet:500,revision:0,save:null});
await db.collection('sessions').insertOne({_id:hash(token),userId:'test-user',expires:new Date(Date.now()+300000)});
const app=createApp({db,client:db,oauth:{},play:{},baseUrl:'http://localhost:3000',clientId:'test'});
let spendRequests=0;
const server=createServer((req,res)=>{
 if(req.url==='/v1/wallet/spend'&&++spendRequests===2) {
  res.end=()=>{res.socket.destroy();return res;};
 }
 app(req,res);
}).listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const executable=process.env.GODOT_EXECUTABLE||'C:/Users/ASUS/My Tools/Godot/4.6.3/Godot_v4.6.3-stable_win64.exe';
const child=spawn(executable,['--headless','--path',root,'res://tests/cloud_account_checks.tscn','--',`--test-api=http://127.0.0.1:${server.address().port}`],{env:{...process.env,APPDATA:resolve(root,'.test-data/online')},windowsHide:true});
let output=''; const receive=chunk=>{output+=chunk; process.stdout.write(chunk);}; child.stdout.on('data',receive);child.stderr.on('data',receive);
const timeout=setTimeout(()=>child.kill(),60000);
const result=await new Promise(resolve=>child.on('exit',code=>resolve(code)));
clearTimeout(timeout);server.closeAllConnections();server.close();
await writeFile(resolve(root,'.test-data/cloud-account-checks.log'),output);
console.log(output.slice(-2500));
assert.equal(spendRequests,3,'Client retries the committed combined debit exactly once');
const user=await db.collection('users').findOne({_id:'test-user'});
assert.equal(user.wallet,250,'Lost response cannot debit the wallet twice');
process.exitCode=result||(!output.includes('Cloud account checks passed')?1:0);
