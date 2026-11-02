import test from 'node:test';
import assert from 'node:assert/strict';
import {resolveBaseUrl,loadConfig} from '../src/config.js';

test('Render URL is detected without PUBLIC_BASE_URL',()=>{
 assert.equal(resolveBaseUrl({RENDER_EXTERNAL_URL:'https://game.onrender.com/'}),'https://game.onrender.com');
 assert.equal(resolveBaseUrl({RENDER_EXTERNAL_HOSTNAME:'game.onrender.com'}),'https://game.onrender.com');
 assert.equal(resolveBaseUrl({PUBLIC_BASE_URL:'  ',RENDER_EXTERNAL_URL:'https://game.onrender.com'}),'https://game.onrender.com');
});
test('explicit domain overrides the Render default',()=>{
 assert.equal(resolveBaseUrl({PUBLIC_BASE_URL:'https://api.example.com/',RENDER_EXTERNAL_URL:'https://game.onrender.com'}),'https://api.example.com');
});
test('bad public origins fail without echoing their values',()=>{
 for(const value of ['not-a-url','http://example.com','https://user:secret@example.com','https://example.com/path','https://example.com/?token=secret']) {
  assert.throws(()=>resolveBaseUrl({PUBLIC_BASE_URL:value}),error=>!error.message.includes('secret'));
 }
 assert.throws(()=>resolveBaseUrl({}),/Set PUBLIC_BASE_URL/);
 assert.equal(resolveBaseUrl({PUBLIC_BASE_URL:'http://localhost:3000'}),'http://localhost:3000');
 assert.throws(()=>resolveBaseUrl({PUBLIC_BASE_URL:'http://localhost:3000',NODE_ENV:'production'}));
});
test('invalid credential JSON is rejected with a safe diagnostic',()=>{
 const env={MONGODB_URI:'mongodb+srv://cluster.example.invalid',GOOGLE_CLIENT_ID:'test',GOOGLE_CLIENT_SECRET:'test',RENDER_EXTERNAL_URL:'https://game.onrender.com'};
 assert.equal(loadConfig(env).baseUrl,'https://game.onrender.com');
 for(const value of ['private-secret-is-not-json','{"type":"service_account"}']) {
  assert.throws(()=>loadConfig({...env,GOOGLE_SERVICE_ACCOUNT_JSON:value}),error=>!error.message.includes(value));
 }
});
