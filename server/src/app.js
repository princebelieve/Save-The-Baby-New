import express from 'express';
import {hash,random,HttpError,requireThat,PACKS,SUPPLIES,MAX_ETHAN_ASSISTS,validateSave,verifyPurchase,addSupply,profile} from './domain.js';

const accountPageStyles = `<style>
  :root { color-scheme: light; font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif; color: #342719; background: #e8dfca; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; padding: 28px 16px; display: grid; place-items: center; background: radial-gradient(ellipse at top, #fff8e8 0%, #e8dfca 78%); }
  main { width: min(100%, 680px); padding: clamp(24px, 5vw, 44px); border: 1px solid #c7a76c; border-radius: 22px; background: #fffaf0; box-shadow: 0 18px 48px #3a271b30, inset 0 0 0 5px #f1e4c8; }
  .brand { margin: 0 0 18px; color: #8b5127; font-size: .76rem; font-weight: 800; letter-spacing: .14em; text-transform: uppercase; }
  h1 { margin: 0; color: #48301c; font-family: Georgia, "Times New Roman", serif; font-size: clamp(1.9rem, 6vw, 2.65rem); line-height: 1.12; }
  .step { display: inline-block; margin: 18px 0 4px; padding: 7px 11px; border: 1px solid #d2ad69; border-radius: 999px; background: #f4e7c8; color: #6f431f; font-size: .82rem; font-weight: 750; }
  p { color: #594a3b; font-size: 1rem; line-height: 1.65; }
  .intro { margin: 12px 0 18px; font-size: 1.08rem; }
  .details { margin: 18px 0; padding: 4px 18px; border-left: 4px solid #c47b37; border-radius: 4px 12px 12px 4px; background: #f7eedc; }
  .details p { margin: 12px 0; }
  .consent { display: flex; align-items: flex-start; gap: 12px; margin: 22px 0; padding: 16px; border: 1px solid #ddc99d; border-radius: 14px; background: #fffdf7; color: #403326; font-size: .96rem; line-height: 1.5; }
  .consent input { width: 20px; height: 20px; margin: 1px 0 0; flex: 0 0 auto; accent-color: #80502b; }
  .button { display: inline-flex; min-height: 52px; align-items: center; justify-content: center; padding: 12px 20px; border: 1px solid #68401f; border-radius: 12px; background: linear-gradient(#9b6333, #744520); color: #fff8e8; font: inherit; font-weight: 750; text-decoration: none; cursor: pointer; box-shadow: 0 4px 0 #4f301b; }
  .button:hover, .button:focus-visible { background: #603b20; outline: 3px solid #e0b45e; outline-offset: 3px; }
  a:not(.button) { color: #76502b; font-weight: 650; }
  @media (max-width: 480px) { body { padding: 12px; } main { padding: 24px 20px; border-radius: 18px; } .button { width: 100%; text-align: center; } }
  @media (prefers-reduced-motion: no-preference) { .button { transition: background-color .15s ease, transform .15s ease; } .button:hover { transform: translateY(-1px); } }
</style>`;

function sendAuthError(res) {
 res.set('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'").status(400).type('html').send(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#e8dfca"><title>Sign-in expired · Save The Baby</title>${accountPageStyles}</head><body><main><p class="brand">S. B. Ibhadode Technologies</p><h1>Start sign-in again</h1><p class="intro">This sign-in step expired or was already used.</p><p>Return to Save The Baby and tap <strong>Create or Connect Google Account</strong> to open a fresh sign-in.</p></main></body></html>`);
}

export function createApp({db, client, oauth, play, baseUrl, clientId, commerceEnabled=false}) {
 const app=express(); app.disable('x-powered-by'); app.set('trust proxy',1);
 app.use(express.json({limit:'100kb'}));
 app.use(express.urlencoded({extended:false,limit:'8kb'}));
 app.use((req,_res,next)=>{req.body ??= {}; next();});
 app.use((req,res,next)=>{res.set({'Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'none'; frame-ancestors 'none'; form-action 'self'"}); next();});
 app.get('/health',(_req,res)=>res.json({ok:true}));
 app.get('/account-deletion',(_req,res)=>res.set('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; form-action 'self'").type('html').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#132b35">
  <title>Delete your Save The Baby account</title>
  <style>
    :root { color-scheme: light; font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif; color: #183047; background: #f4f1e8; }
    * { box-sizing: border-box; }
    body { margin: 0; min-height: 100vh; padding: 32px 18px; display: grid; place-items: center; background: radial-gradient(ellipse at top, #fffdf5 0%, #f4f1e8 72%); }
    main { width: min(100%, 680px); padding: clamp(24px, 6vw, 48px); border: 1px solid #e6dfcd; border-radius: 24px; background: #fffefa; box-shadow: 0 20px 60px #18304718; }
    .brand { margin: 0 0 18px; color: #9b5b26; font-size: .78rem; font-weight: 800; letter-spacing: .14em; text-transform: uppercase; }
    h1 { margin: 0; color: #173b45; font-family: Georgia, serif; font-size: clamp(2rem, 6vw, 3rem); line-height: 1.08; }
    .intro { margin: 16px 0 28px; color: #51636b; font-size: 1.08rem; line-height: 1.65; }
    .steps { margin: 0 0 26px; padding: 22px 24px 22px 48px; border-radius: 16px; background: #f1f6f1; line-height: 1.8; }
    .steps li + li { margin-top: 5px; }
    .button { display: inline-flex; min-height: 52px; align-items: center; justify-content: center; padding: 12px 20px; border: 0; border-radius: 12px; background: #176b61; color: #fff; font-weight: 750; text-decoration: none; box-shadow: 0 5px 0 #0c4e48; }
    .button:hover, .button:focus-visible { background: #10574f; outline: 3px solid #e1ac55; outline-offset: 3px; }
    .note { margin: 28px 0 0; padding-top: 20px; border-top: 1px solid #e6dfcd; color: #5b6669; font-size: .94rem; line-height: 1.65; }
    a:not(.button) { color: #135e68; }
    @media (prefers-reduced-motion: no-preference) { .button { transition: background-color .15s ease, transform .15s ease; } .button:hover { transform: translateY(-1px); } }
  </style>
</head>
<body>
  <main>
    <p class="brand">S. B. Ibhadode Technologies</p>
    <h1>Delete your Save The Baby account</h1>
    <p class="intro">You can delete your online account and the cloud data connected to it from inside the game.</p>
    <ol class="steps">
      <li>Open Save The Baby and sign in to the account you want to delete.</li>
      <li>From the title screen or campaign map, open <strong>Settings → Account &amp; Coins</strong>.</li>
      <li>Choose <strong>Delete Online Account</strong> and confirm.</li>
    </ol>
    <a class="button" href="mailto:info@sbi.globalcreest.com?subject=Save%20The%20Baby%20account%20deletion&amp;body=Please%20delete%20my%20Save%20The%20Baby%20online%20account.%0A%0AMy%20Player%20ID%3A%20">Email support to request deletion</a>
    <p class="note">If you cannot access the game, email <a href="mailto:info@sbi.globalcreest.com?subject=Save%20The%20Baby%20account%20deletion">info@sbi.globalcreest.com</a> with your Player ID and ask for account deletion. We may ask you to verify account ownership. Deletion removes your cloud progress, active sessions, profile and purchased coin balance. Purchase tokens and accounting records needed to prevent fraud or meet legal obligations may be retained.</p>
  </main>
</body>
</html>`));
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
  const accountMode=req.body.accountMode??'self';
  requireThat(['self','guardian'].includes(accountMode),400,'Invalid account mode');
  const id=random(); await flows.insertOne({_id:id,challenge,accountMode,nonce:random(),expires:new Date(Date.now()+300000),status:'created'});
  res.json({flow:id,url:`${baseUrl}/auth/google/start?flow=${id}`});
 });
 app.get('/auth/google/start',async(req,res)=>{
  const browser=random(),noticeToken=random();
  const flow=await flows.findOneAndUpdate({_id:req.query.flow,status:'created',expires:{$gt:new Date()}},{$set:{status:'notice',browserHash:hash(browser),noticeHash:hash(noticeToken)}},{returnDocument:'after'});
  requireThat(flow,400,'Login expired. Return to the game and try again.');
  res.cookie('sb_oauth',browser,{httpOnly:true,secure:baseUrl.startsWith('https:'),sameSite:'lax',maxAge:300000,path:'/auth/google'});
  const parent=flow.accountMode==='guardian';
  res.set('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; form-action 'self'").type('html').send(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#e8dfca"><title>Save The Baby account</title>${accountPageStyles}</head><body><main>
<p><strong>Account setup — step 1 of 2</strong></p>
<p>${parent?'Please hand this device to a parent or legal guardian. The parent must use their own Google account, not the child’s account.':'Continue with your own Google account. If you are under 18, ask your parent or guardian to manage this account.'}</p>
<p>S.B. Ibhadode Technologies stores the Google account identifier, display name, game progress and purchase records using Render and MongoDB Atlas. Google handles payment. Cloud saves and purchased coins belong to the signed-in account. Do not enter a child’s name or email here.</p>
<p>Account creation does not approve future payments. Google Play applies the purchasing account’s parental controls. You can delete the online account from Settings → Account &amp; Coins → Delete Online Account, or contact info@sbi.globalcreest.com.</p>
<p><a href="https://sbi.globalcreest.com/save-the-baby/privacy-policy">Read the privacy policy</a>. You may close this page and continue playing without an online account.</p>
<form method="post" action="/auth/google/authorize"><input type="hidden" name="flow" value="${flow._id}"><input type="hidden" name="noticeToken" value="${noticeToken}">
<p><label><input type="checkbox" name="acknowledged" value="yes" required> ${parent?'I am the parent or legal guardian, I am 18 or older, and I will manage this cloud account and its purchases using my own Google account.':'I am 18 or older and will manage this cloud account and its purchases.'} I have read the account notice.</label></p>
<p><strong>Step 2:</strong> Google will let you choose an existing account or choose “Create account”. The Save The Baby cloud account is created automatically after the first successful Google sign-in.</p>
<button class="button" type="submit">Continue to Google sign-in</button></form></main></body></html>`);
 });
 app.post('/auth/google/authorize',async(req,res)=>{
  const cookie=(req.get('cookie')||'').split(';').map(x=>x.trim()).find(x=>x.startsWith('sb_oauth='))?.slice(9);
  if(req.body.acknowledged!=='yes'||typeof req.body.flow!=='string'||typeof req.body.noticeToken!=='string') return sendAuthError(res);
  // The single-use notice token proves the form came from the notice page. Do
  // not require the original cookie to survive the external browser handoff;
  // establish/refresh the callback cookie here before redirecting to Google.
  const flowQuery={_id:req.body.flow,noticeHash:hash(req.body.noticeToken),expires:{$gt:new Date()}};
  let flow=await flows.findOne(flowQuery);
  if(!flow||!['notice','browser'].includes(flow.status)) return sendAuthError(res);
  let browserToken='';
  if(flow.status==='notice') {
   browserToken=random();
   const advanced=await flows.findOneAndUpdate({...flowQuery,status:'notice'},{$set:{status:'browser',browserHash:hash(browserToken),ownerAcknowledgedAt:new Date(),noticeVersion:1}},{returnDocument:'after'});
   flow=advanced||await flows.findOne({...flowQuery,status:'browser'});
   if(!flow?.noticeVersion||!flow?.ownerAcknowledgedAt) return sendAuthError(res);
  }
  if(!browserToken&&cookie&&hash(cookie)===flow.browserHash) browserToken=cookie;
  if(!browserToken) {
   browserToken=random();
   const rebound=await flows.updateOne({...flowQuery,status:'browser',browserHash:flow.browserHash},{$set:{browserHash:hash(browserToken)}});
   if(!rebound.modifiedCount) return sendAuthError(res);
  }
  res.cookie('sb_oauth',browserToken,{httpOnly:true,secure:baseUrl.startsWith('https:'),sameSite:'lax',maxAge:300000,path:'/auth/google'});
  res.redirect(303,oauth.generateAuthUrl({scope:['openid','email','profile'],state:flow._id,nonce:flow.nonce,prompt:'select_account',access_type:'online'}));
 });
 app.get('/auth/google/callback',async(req,res)=>{
  const cookie=(req.get('cookie')||'').split(';').map(x=>x.trim()).find(x=>x.startsWith('sb_oauth='))?.slice(9);
  requireThat(cookie,400,'Login browser session is missing');
  const flow=await flows.findOneAndUpdate({_id:req.query.state,status:'browser',browserHash:hash(cookie),expires:{$gt:new Date()}},{$set:{status:'exchanging'}},{returnDocument:'after'});
  requireThat(flow,400,'Login expired or already used');
  requireThat(flow.noticeVersion===1&&flow.ownerAcknowledgedAt,403,'Read the adult account notice before signing in.');
  requireThat(!req.query.error && typeof req.query.code==='string',400,'Google sign-in canceled');
  const {tokens}=await oauth.getToken(req.query.code);
  const ticket=await oauth.verifyIdToken({idToken:tokens.id_token,audience:clientId}); const claims=ticket.getPayload();
  requireThat(claims?.sub && claims.email_verified && claims.nonce===flow.nonce,401,'Invalid Google identity');
  const userId=hash(`google:${claims.sub}`);
  // This is an adult-owner declaration, NOT verified age or verifiable parental consent.
  await users.updateOne({_id:userId},{$set:{name:String(claims.name||'Player').slice(0,100),accountNotice:{version:1,mode:flow.accountMode,acknowledgedAt:flow.ownerAcknowledgedAt}},$setOnInsert:{wallet:0,save:null,revision:0,created:new Date()}},{upsert:true});
  await flows.updateOne({_id:flow._id,status:'exchanging'},{$set:{status:'complete',userId}});
  res.clearCookie('sb_oauth',{path:'/auth/google'});
  res.set('Content-Security-Policy',"default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'").type('html').send(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#e8dfca"><title>Signed in · Save The Baby</title>${accountPageStyles}</head><body><main><p class="brand">S. B. Ibhadode Technologies</p><h1>You’re signed in</h1><p class="intro">Your Google account is connected to Save The Baby.</p><p>Return to the game to finish loading your cloud account and progress.</p></main></body></html>`);
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
   requireThat(kind!=='ethan'||Number(user.save.campaign.ethan||0)<MAX_ETHAN_ASSISTS,409,'Ethan assists are already full');
   requireThat(kind!=='lives'||Number(user.save.campaign.lives)<5,409,'Lives are already full');
   await users.updateOne({_id:user._id,revision},{$inc:{wallet:-price,revision:1},$set:{save:addSupply(user.save,kind),updated:new Date()}},{session});
   await db.collection('spends').insertOne({_id:key,userId:user._id,kind,price,created:new Date()},{session});
  });
  res.json(profile(await users.findOne({_id:req.user._id})));
 });
 app.use((error,_req,res,_next)=>{const status=error.status||500; if(status>=500) console.error('Request failed:',error.name);res.status(status).json({error:status>=500?'Service unavailable. Please retry.':error.message});});
 return app;
}
