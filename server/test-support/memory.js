// Deterministic test store. Production uses MongoDB transactions and unique _id indexes.
export class MemoryDb {
 constructor(){this.tables=new Map();this.tail=Promise.resolve();}
 collection(name){if(!this.tables.has(name))this.tables.set(name,new Map());return new Collection(this.tables.get(name));}
 startSession(){const db=this;return {async withTransaction(work){const previous=db.tail;let release;db.tail=new Promise(resolve=>release=resolve);await previous;const copy=structuredClone(db.tables);try{return await work();}catch(error){for(const [name,rows] of db.tables){rows.clear();for(const [id,row]of copy.get(name)||[])rows.set(id,row);}throw error;}finally{release();}},async endSession(){}};}
}
const matches=(row,query)=>Object.entries(query).every(([key,value])=>value&&typeof value==='object'&&'$gt'in value?row[key]>value.$gt:row[key]===value);
class Collection {
 constructor(rows){this.rows=rows;}
 async findOne(query){const row=[...this.rows.values()].find(row=>matches(row,query));return row?structuredClone(row):null;}
 async insertOne(row){if(this.rows.has(row._id)){const error=new Error('duplicate');error.code=11000;throw error;}this.rows.set(row._id,structuredClone(row));return {insertedId:row._id};}
 async updateOne(query,update,options={}){const row=await this.findOne(query);if(!row&&!options.upsert)return {matchedCount:0,modifiedCount:0};const result=row||{...query,...update.$setOnInsert};Object.assign(result,update.$set);for(const [key,value]of Object.entries(update.$inc||{}))result[key]=(result[key]||0)+value;this.rows.set(result._id,structuredClone(result));return {matchedCount:row?1:0,modifiedCount:1};}
 async findOneAndUpdate(query,update,options={}){const before=await this.findOne(query);if(!before&&!options.upsert)return null;await this.updateOne(query,update,options);return options.returnDocument==='after'?await this.findOne({_id:before?._id||query._id}):before;}
 async findOneAndDelete(query){const row=await this.findOne(query);if(row)this.rows.delete(row._id);return row;}
 async deleteOne(query){return {deletedCount:(await this.findOneAndDelete(query))?1:0};}
 async deleteMany(query){for(const [id,row]of this.rows)if(matches(row,query))this.rows.delete(id);}
}
