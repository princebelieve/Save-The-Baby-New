const {chromium}=require('../.tmp/playable-tools/node_modules/playwright');
const http=require('node:http');const fs=require('node:fs');const path=require('node:path');const assert=require('node:assert/strict');
const root=path.resolve('exports/marketing-v9/playable');
const server=http.createServer((req,res)=>{const file=path.join(root,req.url.split('?')[0]);if(!file.startsWith(root)){res.writeHead(403);return res.end();}try{res.setHeader('Content-Type','text/html');res.end(fs.readFileSync(file));}catch(e){res.writeHead(404);res.end();}});
(async()=>{await new Promise(r=>server.listen(0,'127.0.0.1',r));const base=`http://127.0.0.1:${server.address().port}`;
const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});let count=0;const errors=[];
try{
for(const viewport of [{width:320,height:640},{width:390,height:844},{width:844,height:390},{width:1280,height:900}]){
 const page=await browser.newPage({viewport});await page.context().route('https://play.google.com/**',r=>r.fulfill({body:'Store link verified'}));page.on('pageerror',e=>errors.push(e.message));await page.goto(base+'/web/index.html');
 assert.equal(await page.locator('.tile').count(),36);assert.equal(await page.locator('#install').isVisible(),false);
 assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'no horizontal overflow');
 await page.locator('[data-cell="2"]').click();await page.locator('[data-cell="8"]').click();
 await page.waitForFunction(()=>!busy);assert.equal(await page.locator('#moves').textContent(),'5');assert.ok(Number(await page.locator('#collected').textContent())>=3);
 assert.ok(await page.locator('#install').isVisible());
 if(await page.locator('#end').isHidden()){const before=await page.locator('#moves').textContent();await page.locator('#rocket').click();await page.waitForFunction(()=>!busy);assert.equal(await page.locator('#moves').textContent(),before);}
 for(let turn=0;turn<6&&await page.locator('#end').isHidden();turn++){const indices=await page.locator('.tile.hint').evaluateAll(nodes=>nodes.map(n=>n.dataset.cell));await page.locator(`[data-cell="${indices[0]}"]`).click();await page.locator(`[data-cell="${indices[1]}"]`).click();await page.waitForFunction(()=>!busy);}
 assert.ok(await page.locator('#end').isVisible());
 const popup=page.waitForEvent('popup');await page.locator('#end-install').click();const store=await popup;await store.waitForURL('https://play.google.com/**');assert.equal(new URL(store.url()).hostname,'play.google.com');await store.close();
 await page.locator('#again').click();assert.equal(await page.locator('#collected').textContent(),'0');assert.equal(await page.locator('#moves').textContent(),'6');
 await page.screenshot({path:path.join(root,`preview-${viewport.width}.png`)});await page.close();count++;
}
for(const mode of ['google','mraid']){
 const page=await browser.newPage({viewport:{width:390,height:844}});page.on('pageerror',e=>errors.push(e.message));
 if(mode==='google')await page.route('https://tpc.googlesyndication.com/**',r=>r.fulfill({contentType:'application/javascript',body:'window.exitCalls=0;window.ExitApi={exit(){window.exitCalls++;}};'}));
 else await page.addInitScript(()=>{window.exitCalls=0;window.events={};window.mraid={getState:()=> 'loading',isViewable:()=>true,addEventListener:(n,f)=>{window.events[n]=f;},open:u=>{window.exitCalls++;window.storeUrl=u;}};});
 await page.goto(base+`/${mode}/index.html`);
 if(mode==='mraid'){assert.ok(await page.locator('.tile').first().isDisabled());await page.evaluate(()=>window.events.ready());assert.equal(await page.locator('.tile').first().isDisabled(),false);await page.evaluate(()=>window.events.viewableChange(false));assert.ok(await page.locator('.tile').first().isDisabled());await page.evaluate(()=>window.events.viewableChange(true));}
 assert.equal(await page.evaluate(()=>window.exitCalls),0);await page.locator('[data-cell="2"]').click();await page.locator('[data-cell="8"]').click();await page.waitForFunction(()=>!busy);
 await page.locator('#install').click();assert.equal(await page.evaluate(()=>window.exitCalls),1);
 if(mode==='mraid')assert.ok((await page.evaluate(()=>window.storeUrl)).includes('com.savethebaby.game'));
 await page.close();count++;
}
assert.deepEqual(errors,[]);fs.writeFileSync(path.join(root,'browser-checks.json'),JSON.stringify({passed:count,viewports:4,adExitBridges:2,scriptErrors:errors},null,2));console.log(`${count} browser scenarios passed; no script errors.`);
}finally{await browser.close();server.close();}
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});
