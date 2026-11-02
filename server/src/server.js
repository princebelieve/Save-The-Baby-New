import {MongoClient} from 'mongodb';
import {OAuth2Client,GoogleAuth} from 'google-auth-library';
import {createApp} from './app.js';
import {requireThat} from './domain.js';

for(const key of ['MONGODB_URI','GOOGLE_CLIENT_ID','GOOGLE_CLIENT_SECRET','PUBLIC_BASE_URL']) if(!process.env[key]) throw new Error(`Missing ${key}`);
const baseUrl=process.env.PUBLIC_BASE_URL.replace(/\/$/,'');
requireThat(baseUrl.startsWith('https://')||baseUrl.startsWith('http://localhost:'),500,'PUBLIC_BASE_URL must use HTTPS');
const client=new MongoClient(process.env.MONGODB_URI); await client.connect();
const db=client.db(process.env.MONGODB_DATABASE||'save_the_baby');
for(const name of ['flows','sessions','rates']) await db.collection(name).createIndex({expires:1},{expireAfterSeconds:0});
await db.collection('purchases').createIndex({userId:1});
const oauth=new OAuth2Client(process.env.GOOGLE_CLIENT_ID,process.env.GOOGLE_CLIENT_SECRET,`${baseUrl}/auth/google/callback`);
const packageName='com.savethebaby.game';
const credentials=process.env.GOOGLE_SERVICE_ACCOUNT_JSON ? JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON) : undefined;
const google=new GoogleAuth({credentials,scopes:['https://www.googleapis.com/auth/androidpublisher']});
const url=(product,token)=>`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${encodeURIComponent(product)}/tokens/${encodeURIComponent(token)}`;
const play={
 async verify(product,token){const auth=await google.getClient(); const result=await auth.request({url:url(product,token)});return result.data;},
 async consume(product,token){const auth=await google.getClient();await auth.request({url:`${url(product,token)}:consume`,method:'POST'});}
};
const app=createApp({db,client,oauth,play,baseUrl,clientId:process.env.GOOGLE_CLIENT_ID,commerceEnabled:Boolean(credentials)});
const server=app.listen(Number(process.env.PORT||3000),'0.0.0.0',()=>console.log('Save The Baby API ready'));
// Reconcile consumed purchases too: refunds must not leave spendable paid credit behind.
let reconciling=false;
async function reconcile(){
 if(!credentials||reconciling)return; reconciling=true;
 try {for await(const purchase of db.collection('purchases').find({revoked:false})) {
  try {
   const current=await play.verify(purchase.productId,purchase.token);
   if(current.purchaseState===1){
    const session=client.startSession(); try {await session.withTransaction(async()=>{
     const changed=await db.collection('purchases').updateOne({_id:purchase._id,revoked:false},{$set:{revoked:true,revokedAt:new Date()}},{session});
     if(changed.modifiedCount)await db.collection('users').updateOne({_id:purchase.userId},{$inc:{wallet:-purchase.coins}},{session});
    },{readConcern:{level:'snapshot'},writeConcern:{w:'majority'}});}finally{await session.endSession();}
   } else if(current.purchaseState===0&&!purchase.consumed){
    if(current.consumptionState!==1)await play.consume(purchase.productId,purchase.token);
    await db.collection('purchases').updateOne({_id:purchase._id},{$set:{consumed:true}});
   }
  } catch {console.error('Purchase reconciliation failed; will retry');}
 }}finally{reconciling=false;}
}
const timer=setInterval(()=>reconcile().catch(()=>console.error('Reconciliation unavailable')),15*60000);timer.unref();
reconcile().catch(()=>console.error('Reconciliation unavailable'));
for(const signal of ['SIGTERM','SIGINT'])process.on(signal,()=>{clearInterval(timer);server.close(async()=>{await client.close();process.exit(0);});});
