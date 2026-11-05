import {createHash, randomBytes} from 'node:crypto';
export const hash = value => createHash('sha256').update(value).digest('hex');
export const random = () => randomBytes(32).toString('base64url');
export class HttpError extends Error { constructor(status, message) { super(message); this.status = status; } }
export const requireThat = (condition, status, message) => { if (!condition) throw new HttpError(status, message); };
export const PACKS = Object.freeze({coins_500: 500, coins_1500: 1500, coins_3500: 3500});
export const MAX_ETHAN_ASSISTS = 2;
export const SUPPLIES = Object.freeze({rocket: {price:150, amount:1}, bomb:{price:250, amount:1}, thunder:{price:350, amount:1}, ethan:{price:400, amount:1}, life:{price:200, amount:1}, lives:{price:900, amount:5}, continue:{price:500, amount:5}});
export function validateSave(save) {
 requireThat(save && typeof save === 'object' && !Array.isArray(save),400,'Invalid save');
 requireThat(Buffer.byteLength(JSON.stringify(save)) <= 96000,413,'Save is too large');
 const walk = (value, depth=0) => {
  requireThat(depth < 16,400,'Save nesting is too deep');
  if (value === null || typeof value === 'boolean') return;
  if (typeof value === 'number') { requireThat(Number.isFinite(value) && Math.abs(value) <= 1e12,400,'Invalid number'); return; }
  if (typeof value === 'string') { requireThat(value.length <= 16000,400,'Text is too long'); return; }
  requireThat(typeof value === 'object',400,'Invalid value');
  for (const [key, child] of Object.entries(value)) {
   requireThat(!key.startsWith('$') && !key.includes('.') && !['__proto__','prototype','constructor'].includes(key),400,'Invalid save key'); walk(child,depth+1);
  }
 };
 walk(save);
 requireThat(save.campaign && typeof save.campaign === 'object' && !Array.isArray(save.campaign),400,'Missing campaign');
 for (const [section, values] of Object.entries(save)) requireThat(values && typeof values==='object' && !Array.isArray(values),400,'Invalid save section');
 const campaign=save.campaign;
 for (const key of ['coins','ethan','total_stars','special_moves_created','life_regeneration_time','continue_credits']) if(key in campaign) requireThat(Number.isSafeInteger(campaign[key])&&campaign[key]>=0,400,`Invalid ${key}`);
 if ('ethan' in campaign) campaign.ethan = Math.min(MAX_ETHAN_ASSISTS, campaign.ethan);
 if('lives' in campaign) requireThat(Number.isSafeInteger(campaign.lives)&&campaign.lives>=0&&campaign.lives<=5,400,'Invalid lives');
 if('boosters' in campaign){requireThat(campaign.boosters&&typeof campaign.boosters==='object'&&!Array.isArray(campaign.boosters),400,'Invalid boosters');for(const count of Object.values(campaign.boosters))requireThat(Number.isSafeInteger(count)&&count>=0,400,'Invalid booster count');}
 return structuredClone(save);
}
export function verifyPurchase(data, expectedAccount) {
 requireThat(data.purchaseState === 0,409,'Payment is pending, canceled, or refunded');
 requireThat(data.obfuscatedExternalAccountId === expectedAccount,403,'Purchase belongs to another game account');
 requireThat((data.quantity ?? 1) === 1,400,'Unsupported purchase quantity');
}
export function addSupply(save, kind) {
 const result = validateSave(save);
 const campaign = result.campaign;
 if (kind === 'lives' || kind === 'life') campaign.lives = Math.min(5, Math.max(0,Number(campaign.lives)||0) + SUPPLIES[kind].amount);
 else if (kind === 'continue') campaign.continue_credits = (campaign.continue_credits || 0) + 1;
 else if (kind === 'ethan') campaign.ethan = Math.min(MAX_ETHAN_ASSISTS, Math.max(0,Number(campaign.ethan)||0) + 1);
 else { campaign.boosters ??= {}; campaign.boosters[kind] = Math.max(0,Number(campaign.boosters[kind])||0) + 1; }
 return result;
}
export function profile(user) { return {userId:user._id, name:user.name, revision:user.revision, save:user.save, wallet:user.wallet, billingAccount:hash(user._id)}; }
