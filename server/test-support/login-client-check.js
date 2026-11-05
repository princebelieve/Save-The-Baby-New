import {spawn} from 'node:child_process';
import {createServer} from 'node:http';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createApp} from '../src/app.js';
import {MemoryDb} from './memory.js';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const profile=resolve(root,'.test-data/google-login');await mkdir(profile,{recursive:true});
const db=new MemoryDb();
await db.collection('users').insertOne({_id:'login-test-user',name:'Returning player',wallet:500,revision:0,save:null});
const app=createApp({db,client:db,oauth:{},play:{},baseUrl:'http://localhost:3000',clientId:'test'});
const stats={polls:0,dropped:0};
app.post('/test/complete',async(req,res)=>{await db.collection('flows').updateOne({_id:req.body.flow},{$set:{status:'complete',userId:'login-test-user'}});res.json({ok:true});});
app.get('/test/stats',(_req,res)=>res.json(stats));
const api=app.listen(0,'127.0.0.1');await new Promise(resolve=>api.once('listening',resolve));
const proxy=createServer(async(req,res)=>{
 try {
  const chunks=[];for await(const chunk of req)chunks.push(chunk);
  const response=await fetch(`http://127.0.0.1:${api.address().port}${req.url}`,{method:req.method,headers:{'Content-Type':'application/json',...(req.headers.authorization?{Authorization:req.headers.authorization}:{})},...(chunks.length?{body:Buffer.concat(chunks)}:{})});
  const body=await response.text();
  if(req.url==='/auth/poll') {
   stats.polls++;
   // The real server has already committed the session. Simulate losing its
   // HTTP response while Android is handing control back from the browser.
   if(response.status===200&&stats.dropped===0){stats.dropped++;res.destroy();return;}
   if(response.status===200&&stats.dropped===1){stats.dropped++;res.writeHead(503,{'Content-Type':'application/json'});res.end(JSON.stringify({error:'Temporary connection interruption'}));return;}
  }
  res.writeHead(response.status,{'Content-Type':'application/json'});res.end(body);
 } catch {res.writeHead(503,{'Content-Type':'application/json'});res.end(JSON.stringify({error:'Test proxy unavailable'}));}
});
proxy.listen(0,'127.0.0.1');await new Promise(resolve=>proxy.once('listening',resolve));
const executable=process.env.GODOT_EXECUTABLE||'C:/Users/ASUS/My Tools/Godot/4.6.3/Godot_v4.6.3-stable_win64.exe';
let output='';
async function run(phase) {
 const child=spawn(executable,['--headless','--path',root,'res://tests/google_login_checks.tscn','--',`--test-api=http://127.0.0.1:${proxy.address().port}`,`--phase=${phase}`],{env:{...process.env,APPDATA:profile},windowsHide:true});
 let phaseOutput='';const receive=chunk=>{const text=chunk.toString();output+=text;phaseOutput+=text;process.stdout.write(text);};child.stdout.on('data',receive);child.stderr.on('data',receive);
 const timeout=setTimeout(()=>child.kill(),45000);
 const code=await new Promise(resolve=>child.on('close',resolve));clearTimeout(timeout);
 if(code!==0||phaseOutput.includes('SCRIPT ERROR:')||!phaseOutput.includes(`GOOGLE_LOGIN_${phase.toUpperCase()}_PASSED`))throw new Error(`Google login ${phase} checks failed`);
}
try {await run('prepare');await run('resume');console.log('Google login client: process restart, lost response retry, preserved UI, session persistence and logout passed.');}
catch(error){console.error(error.message);process.exitCode=1;}
finally {proxy.closeAllConnections();proxy.close();api.closeAllConnections();api.close();await writeFile(resolve(root,'.test-data/google-login-client.log'),output);}
