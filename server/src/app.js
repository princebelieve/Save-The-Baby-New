import express from 'express';
import {hash,random,HttpError,requireThat,PACKS,SUPPLIES,validateSave,verifyPurchase,addSupply,profile} from './domain.js';

export function createApp({db, client, oauth, play, baseUrl, clientId, commerceEnabled=false}) {
 const app=express(); app.disable('x-powered-by'); app.set('trust proxy',1);
 app.use(express.json({limit:'100kb'}));
 app.use((req,_res,next)=>{req.body ??= {}; next();});
 app.use((req,res,next)=>{res.set({'Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'none'; frame-ancestors 'none'"}); next();});
 app.get('/health',(_req,res)=>res.json({ok:true}));
 app.get('/account-deletion',(_req,res)=>res.type('html').send('<!doctype html><title>Delete Save The Baby account</title><h1>Delete your Save The Baby account</h1><p>In the game, open Settings, Account &amp; Coins, then Delete Online Account. Confirm to delete your cloud save and purchased coin balance.</p><p>If you cannot access the game, email info@sbi.globalcreest.com with your Player ID and ask for account deletion. We may ask for proof of account ownership. Purchase accounting records required for fraud prevention and legal obligations may be retained; cloud progress and active sessions are deleted.</p>'));
 app.use(async(req,_res,next)=>{
  const bucket=hash(`${req.ip}:${Math.floor(Date.now()/60000)}`);
  const rate=await db.collection('rates').findOneAndUpdate({_id:bucket},{$inc:{count:1},$setOnInsert:{expires:new Date(Date.now()+120000)}},{upsert:true,returnDocument:'after'});
  requireThat(rate.count<=100,429,'Too many requests. Please wait a minute.'); next();
 });
 const flows=db.collection('flows'), users=db.collection('users'), sessions=db.collection('sessions'), purchases=db.collection('purchases');
 const auth=async(req,_res,next)=>{
  const token=(req.get('authorization')||'').replace(/^Bearer /,'');
  requireThat(token.length>=32,401,'Sign in again');
  const session=await sessions.findOne({_id:hash(token),expires:{$gt:new Date()}});
  requireThat(session,401,'Sign in again');
  req.user=await users.findOne({_id:session.userId}); requireThat(req.user,401,'Account not found'); req.sessionHash=session._id; next();
 };
 const transaction=async(work)=>{const session=client.startSession(); try{return await session.withTransaction(()=>work(session),{readConcern:{level:'snapshot'},writeConcern:{w:'majority'}});}finally{await session.endSession();}};
 app.post('/auth/start',async(req,res)=>{
  const challenge=req.body.challenge; requireThat(typeof challenge==='string'&&/^[a-f0-9]{64}$/.test(challenge),400,'Invalid login challenge');
  const id=random(); await flows.insertOne({_id:id,challenge,nonce:random(),expires:new Date(Date.now()+300000),status:'created'});
  res.json({flow:id,url:`${baseUrl}/auth/google/start?flow=${id}`});
 });
 app.get('/auth/google/start',async(req,res)=>{
  const browser=random();
  const flow=await flows.findOneAndUpdate({_id:req.query.flow,status:'created',expires:{$gt:new Date()}},{$set:{status:'browser',browserHash:hash(browser)}},{returnDocument:'after'});
  requireThat(flow,400,'Login expired. Return to the game and try again.');
  res.cookie('sb_oauth',browser,{httpOnly:true,secure:baseUrl.startsWith('https:'),sameSite:'lax',maxAge:300000,path:'/auth/google'});
  res.redirect(oauth.generateAuthUrl({scope:['openid','email','profile'],state:flow._id,nonce:flow.nonce,prompt:'select_account',access_type:'online'}));
 });
 app.get('/auth/google/callback',async(req,res)=>{
  const cookie=(req.get('cookie')||'').split(';').map(x=>x.trim()).find(x=>x.startsWith('sb_oauth='))?.slice(9);
  requireThat(cookie,400,'Login browser session is missing');
  const flow=await flows.findOneAndUpdate({_id:req.query.state,status:'browser',browserHash:hash(cookie),expires:{$gt:new Date()}},{$set:{status:'exchanging'}},{returnDocument:'after'});
  requireThat(flow,400,'Login expired or already used');
  requireThat(!req.query.error && typeof req.query.code==='string',400,'Google sign-in canceled');
  const {tokens}=await oauth.getToken(req.query.code);
  const ticket=await oauth.verifyIdToken({idToken:tokens.id_token,audience:clientId}); const claims=ticket.getPayload();
  requireThat(claims?.sub && claims.email_verified && claims.nonce===flow.nonce,401,'Invalid Google identity');
  const userId=hash(`google:${claims.sub}`);
  await users.updateOne({_id:userId},{$set:{name:String(claims.name||'Player').slice(0,100)},$setOnInsert:{wallet:0,save:null,revision:0,created:new Date()}},{upsert:true});
  await flows.updateOne({_id:flow._id,status:'exchanging'},{$set:{status:'complete',userId}});
  res.clearCookie('sb_oauth',{path:'/auth/google'});
  res.type('html').send('<!doctype html><title>Save The Baby</title><h1>Signed in</h1><p>Return to Save The Baby to finish loading your progress.</p>');
 });
 app.post('/auth/poll',async(req,res)=>{
  const {flow:id,verifier}=req.body; requireThat(typeof verifier==='string' && verifier.length>=32 && verifier.length<=256,400,'Invalid login proof');
  const flow=await flows.findOne({_id:id,challenge:hash(verifier),expires:{$gt:new Date()}}); requireThat(flow,400,'Login expired');
  if(flow.status!=='complete') return res.status(202).json({pending:true});
  const claimed=await flows.findOneAndDelete({_id:id,status:'complete'}); requireThat(claimed,409,'Login already completed');
  const token=random(); await sessions.insertOne({_id:hash(token),userId:flow.userId,expires:new Date(Date.now()+30*86400000)});
  res.json({token,...profile(await users.findOne({_id:flow.userId}))});
 });
 app.get('/v1/me',auth,(req,res)=>res.json(profile(req.user)));
 app.post('/v1/logout',auth,async(req,res)=>{await sessions.deleteOne({_id:req.sessionHash});res.json({ok:true});});
 app.delete('/v1/account',auth,async(req,res)=>{
  await transaction(async session=>{await users.deleteOne({_id:req.user._id},{session}); await sessions.deleteMany({userId:req.user._id},{session});});
  // Token hashes and accounting records remain to prevent refunded/replayed purchases from being credited again.
  res.json({ok:true});
 });
 app.put('/v1/save',auth,async(req,res)=>{
  const {revision,save}=req.body; requireThat(Number.isSafeInteger(revision)&&revision>=0,400,'Invalid save revision');
  const clean=validateSave(save);
  const user=await users.findOneAndUpdate({_id:req.user._id,revision},{$set:{save:clean,updated:new Date()},$inc:{revision:1}},{returnDocument:'after'});
  requireThat(user,409,'Another device has a newer save. Download it before uploading again.'); res.json(profile(user));
 });
 app.get('/v1/catalog',auth,(_req,res)=>res.json({packs:PACKS,supplies:SUPPLIES,commerceEnabled}));
 app.post('/v1/purchases/google',auth,async(req,res)=>{
  requireThat(commerceEnabled,503,'Coin purchases are not enabled yet.');
  const {productId,purchaseToken}=req.body; requireThat(Object.hasOwn(PACKS,productId)&&typeof purchaseToken==='string'&&purchaseToken.length>=10&&purchaseToken.length<=4096,400,'Invalid product or purchase token');
  const key=hash(purchaseToken); let purchase=await purchases.findOne({_id:key});
  if(purchase) requireThat(purchase.userId===req.user._id&&purchase.productId===productId,403,'Purchase belongs to another account');
  if(!purchase){
   const verified=await play.verify(productId,purchaseToken); verifyPurchase(verified,hash(req.user._id));
   requireThat(verified.consumptionState===0,409,'Purchase was already consumed without a matching game record');
   try {await transaction(async session=>{
    await purchases.insertOne({_id:key,userId:req.user._id,productId,coins:PACKS[productId],token:purchaseToken,consumed:false,revoked:false,created:new Date()},{session});
    const update=await users.updateOne({_id:req.user._id},{$inc:{wallet:PACKS[productId]}},{session}); requireThat(update.matchedCount===1,401,'Account no longer exists');
   });} catch(error) {if(error.code!==11000) throw error;}
   purchase=await purchases.findOne({_id:key});
   requireThat(purchase?.userId===req.user._id&&purchase.productId===productId,403,'Purchase belongs to another account');
  }
  if(!purchase.consumed&&!purchase.revoked){
   // If a previous consume succeeded but its response was lost, verification recovers it.
   const current=await play.verify(productId,purchaseToken);
   if(current.consumptionState!==1) await play.consume(productId,purchaseToken);
   await purchases.updateOne({_id:key},{$set:{consumed:true}});
  }
  res.json({...profile(await users.findOne({_id:req.user._id})),credited:!purchase.revoked});
 });
 app.post('/v1/wallet/spend',auth,async(req,res)=>{
  const {kind,revision,requestId}=req.body; requireThat(Object.hasOwn(SUPPLIES,kind)&&Number.isSafeInteger(revision)&&typeof requestId==='string'&&/^[a-f0-9-]{16,80}$/.test(requestId),400,'Invalid supply request');
  const key=hash(`${req.user._id}:${requestId}`);
  await transaction(async session=>{
   const previous=await db.collection('spends').findOne({_id:key},{session});
   if(previous) {requireThat(previous.kind===kind,409,'Request was already used');return;}
   const user=await users.findOne({_id:req.user._id},{session}); requireThat(user?.save,409,'Save progress before purchasing supplies');
   requireThat(user.revision===revision,409,'Another device has a newer save');
   const price=SUPPLIES[kind].price; requireThat(user.wallet>=price,409,'Not enough purchased coins');
   requireThat(kind!=='lives'||Number(user.save.campaign.lives)<5,409,'Lives are already full');
   await users.updateOne({_id:user._id,revision},{$inc:{wallet:-price,revision:1},$set:{save:addSupply(user.save,kind),updated:new Date()}},{session});
   await db.collection('spends').insertOne({_id:key,userId:user._id,kind,price,created:new Date()},{session});
  });
  res.json(profile(await users.findOne({_id:req.user._id})));
 });
 app.use((error,_req,res,_next)=>{const status=error.status||500; if(status>=500) console.error('Request failed:',error.name);res.status(status).json({error:status>=500?'Service unavailable. Please retry.':error.message});});
 return app;
}
