import {createPrivateKey} from 'node:crypto';

export function resolveBaseUrl(env) {
 const explicit=env.PUBLIC_BASE_URL?.trim();
 const supplied=explicit || env.RENDER_EXTERNAL_URL?.trim() || (env.RENDER_EXTERNAL_HOSTNAME?.trim()?`https://${env.RENDER_EXTERNAL_HOSTNAME.trim()}`:'');
 if(!supplied) throw new Error('Set PUBLIC_BASE_URL outside Render; Render supplies RENDER_EXTERNAL_URL automatically.');
 let url;
 try {url=new URL(supplied);} catch {throw new Error('PUBLIC_BASE_URL must be a valid public HTTPS origin.');}
 const local=env.NODE_ENV!=='production' && url.protocol==='http:' && ['localhost','127.0.0.1','[::1]'].includes(url.hostname);
 if((url.protocol!=='https:'&&!local)||url.username||url.password||url.pathname!=='/'||url.search||url.hash) throw new Error('PUBLIC_BASE_URL must be an HTTPS origin without credentials, path, query, or fragment.');
 return url.origin;
}

export function loadConfig(env=process.env) {
 for(const key of ['MONGODB_URI','GOOGLE_CLIENT_ID','GOOGLE_CLIENT_SECRET']) if(!env[key]?.trim()) throw new Error(`Missing ${key}. Set it in Render Environment.`);
 const baseUrl=resolveBaseUrl(env);
 const mongodbUri=env.MONGODB_URI.trim();
 if(!/^mongodb(?:\+srv)?:\/\//.test(mongodbUri)||mongodbUri.includes('<db_password>')||mongodbUri==='SET_IN_RENDER') throw new Error('MONGODB_URI must be the Atlas driver connection string with its password filled in.');
 let credentials;
 if(env.GOOGLE_SERVICE_ACCOUNT_JSON?.trim()) {
  try {credentials=JSON.parse(env.GOOGLE_SERVICE_ACCOUNT_JSON);} catch {throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON must contain the complete JSON file contents, not a filename.');}
  if(credentials?.type!=='service_account'||typeof credentials.client_email!=='string'||typeof credentials.private_key!=='string') throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON must be a service-account JSON key with client_email and private_key.');
  try {createPrivateKey(credentials.private_key);} catch {throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON contains an invalid private_key. Paste the original complete JSON file.');}
 }
 return {baseUrl,mongodbUri,database:env.MONGODB_DATABASE?.trim()||'save_the_baby',clientId:env.GOOGLE_CLIENT_ID.trim(),clientSecret:env.GOOGLE_CLIENT_SECRET.trim(),credentials};
}
