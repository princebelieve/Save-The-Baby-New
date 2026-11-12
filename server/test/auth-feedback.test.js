import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';

function fixture() {
 const timers=new Map(),windowEvents={}; let id=0;
 const element=text=>({textContent:text,attributes:{},events:{},setAttribute(k,v){this.attributes[k]=v;},removeAttribute(k){delete this.attributes[k];},addEventListener(k,v){this.events[k]=v;}});
 const button=element('Sign in with Google'),link=element('Return to game'),main={append(value){this.status=value;}},form=element('');
 form.querySelector=()=>button;
 runInNewContext(readFileSync(new URL('../src/auth-feedback.js',import.meta.url),'utf8'),{
  document:{createElement:()=>element(''),querySelector:selector=>({'main':main,'form':form,'#return-to-game':link}[selector])},
  window:{addEventListener(k,v){windowEvents[k]=v;}},
  setTimeout(fn){timers.set(++id,fn);return id;},clearTimeout(key){timers.delete(key);}
 });
 const trigger=(control,type)=>{let prevented=false;control.events[type]({target:control,currentTarget:control,preventDefault(){prevented=true;}});return prevented;};
 return {button,link,form,main,timers,windowEvents,trigger};
}

test('Google submit gives feedback, suppresses duplicates and restores after browser Back',()=>{
 const f=fixture();
 assert.equal(f.trigger(f.form,'submit'),false,'first valid submit keeps native navigation');
 assert.equal(f.button.textContent,'Opening Google…');
 assert.equal(f.button.attributes['aria-busy'],'true');
 assert.equal(f.trigger(f.form,'submit'),true);
 f.windowEvents.pageshow();
 assert.equal(f.button.textContent,'Sign in with Google');
 assert.equal(f.button.attributes['aria-busy'],undefined);
 assert.equal(f.trigger(f.form,'submit'),false);
});

test('return link keeps native app launch and allows retry after missing handler',()=>{
 const f=fixture();
 assert.equal(f.trigger(f.link,'click'),false);
 assert.equal(f.link.textContent,'Opening game…');
 assert.equal(f.trigger(f.link,'click'),true);
 [...f.timers.values()][0]();
 assert.equal(f.link.textContent,'Return to game');
 assert.match(f.main.status.textContent,/try again/);
 assert.equal(f.trigger(f.link,'click'),false);
});
