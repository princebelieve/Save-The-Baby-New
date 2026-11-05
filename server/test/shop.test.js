import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createApp} from '../src/app.js';
import {SUPPLIES,hash} from '../src/domain.js';
import {MemoryDb} from '../test-support/memory.js';

test('offline prices and authoritative server catalog stay consistent',()=>{
 const config=JSON.parse(readFileSync(new URL('../../configs/economy.json',import.meta.url)));
 const ids={life:'life',lives:'life_refill',rocket:'rocket_booster',bomb:'bomb_booster',thunder:'thunder_booster',ethan:'ethan_assist',continue:'continue'};
 for(const [kind,id] of Object.entries(ids)) {
  assert.equal(config.items[id].price,SUPPLIES[kind].price,kind);
  assert.equal(config.items[id].amount,SUPPLIES[kind].amount,kind);
 }
});

test('combined spending is atomic, replay safe, price checked and rejects full lives',async t=>{
 const db=new MemoryDb(),token='shop-test-token'.repeat(4);
 await db.collection('users').insertOne({_id:'shop-user',wallet:1200,revision:0,save:{campaign:{coins:150,lives:0,boosters:{}}}});
 await db.collection('sessions').insertOne({_id:hash(token),userId:'shop-user',expires:new Date(Date.now()+60000)});
 const app=createApp({db,client:db,oauth:{},play:{},baseUrl:'http://localhost',clientId:'test'});
 const server=app.listen(0,'127.0.0.1');await new Promise(resolve=>server.once('listening',resolve));
 t.after(()=>{server.closeAllConnections();server.close();});
 const buy=async data=>{const r=await fetch(`http://127.0.0.1:${server.address().port}/v1/wallet/spend`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify(data)});return {status:r.status,body:await r.json()};};
 const first={kind:'life',revision:0,expectedPrice:200,useEarned:true,requestId:'1111111111111111'};
 const concurrent=await Promise.all([buy(first),buy(first)]);
 assert.ok(concurrent.every(r=>r.status===200));
 let user=await db.collection('users').findOne({_id:'shop-user'});
 assert.equal(user.wallet,1150);assert.equal(user.save.campaign.coins,0);assert.equal(user.save.campaign.lives,1);assert.equal(user.revision,1);
 assert.equal((await buy({...first,kind:'lives',revision:1,expectedPrice:100,requestId:'2222222222222222'})).status,409);
 assert.equal((await db.collection('users').findOne({_id:'shop-user'})).wallet,1150);
 const refill=await buy({kind:'lives',revision:1,expectedPrice:900,useEarned:true,requestId:'3333333333333333'});
 assert.equal(refill.status,200);assert.equal(refill.body.wallet,250);assert.equal(refill.body.save.campaign.lives,5);
 assert.equal((await buy({kind:'life',revision:2,expectedPrice:200,useEarned:true,requestId:'4444444444444444'})).status,409);
 assert.equal((await buy({kind:'continue',revision:2,expectedPrice:500,useEarned:true,requestId:'5555555555555555'})).status,409);
 user=await db.collection('users').findOne({_id:'shop-user'});
 assert.equal(user.wallet,250);assert.equal(user.revision,2);
 // Recoverable continuation is stored in the authoritative save, not granted
 // merely because a payment UI or HTTP request was closed.
 await db.collection('users').updateOne({_id:'shop-user'},{$set:{wallet:750}});
 const continued=await buy({kind:'continue',revision:2,expectedPrice:500,useEarned:true,requestId:'6666666666666666'});
 assert.equal(continued.status,200);assert.equal(continued.body.wallet,250);assert.equal(continued.body.save.campaign.continue_credits,1);
});
