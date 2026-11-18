/* Shared, deterministic match rules for the small promotional preview. */
class PreviewBoard {
 constructor(random=Math.random){this.random=random;this.reset();}
 reset(){this.cells=Array.from({length:36},(_,i)=>(Math.floor(i/6)*2+i%6)%5);this.cells[0]=0;this.cells[1]=0;this.cells[2]=1;this.cells[8]=0;this.moves=6;this.keys=0;this.score=0;this.tray=1;this.turns=0;}
 matches(){const hit=new Set();for(let r=0;r<6;r++)for(let c=0;c<6;c++){const i=r*6+c,v=this.cells[i];if(v<0||v>=5)continue;if(c<=3&&this.cells[i+1]===v&&this.cells[i+2]===v){hit.add(i);hit.add(i+1);hit.add(i+2);}if(r<=3&&this.cells[i+6]===v&&this.cells[i+12]===v){hit.add(i);hit.add(i+6);hit.add(i+12);}}return [...hit];}
 adjacent(a,b){return a>=0&&b>=0&&a<36&&b<36&&Math.abs(Math.floor(a/6)-Math.floor(b/6))+Math.abs(a%6-b%6)===1;}
 swap(a,b){if(!this.adjacent(a,b)||this.moves<=0)return null;[this.cells[a],this.cells[b]]=[this.cells[b],this.cells[a]];const rockets=[a,b].filter(i=>this.cells[i]===5);let hit=this.matches();for(const i of rockets)for(let c=0;c<6;c++)hit.push(Math.floor(i/6)*6+c);hit=[...new Set(hit)];if(!hit.length){[this.cells[a],this.cells[b]]=[this.cells[b],this.cells[a]];return null;}this.moves--;this.turns++;return hit;}
 clear(hit,allowSpecial=false){const unique=[...new Set(hit)];let keys=0;for(const i of unique){if(this.cells[i]===0)keys++;this.cells[i]=-1;}this.keys+=keys;this.score+=unique.length*10;let special=null;if(allowSpecial&&unique.length>=4){special=unique[0];this.cells[special]=5;}return {keys,special};}
 refill(){for(let c=0;c<6;c++){let row=5;for(let r=5;r>=0;r--){const v=this.cells[r*6+c];if(v>=0)this.cells[row--*6+c]=v;}while(row>=0)this.cells[row--*6+c]=Math.floor(this.random()*5);}}
 rocket(){if(!this.tray)return null;this.tray--;this.turns++;let best=0,count=-1;for(let r=0;r<6;r++){const n=this.cells.slice(r*6,r*6+6).filter(v=>v===0).length;if(n>count){count=n;best=r;}}return Array.from({length:6},(_,c)=>best*6+c);}
 hint(){for(let a=0;a<36;a++)for(const b of [a+1,a+6]){if(!this.adjacent(a,b))continue;[this.cells[a],this.cells[b]]=[this.cells[b],this.cells[a]];const ok=this.matches().length||this.cells[a]===5||this.cells[b]===5;[this.cells[a],this.cells[b]]=[this.cells[b],this.cells[a]];if(ok)return [a,b];}return [];}
 ensureMove(){if(this.hint().length)return;this.cells[0]=0;this.cells[1]=0;this.cells[2]=1;this.cells[8]=0;}
}
if(typeof module!=='undefined')module.exports=PreviewBoard;
