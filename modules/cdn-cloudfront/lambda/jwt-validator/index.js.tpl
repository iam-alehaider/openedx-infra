
'use strict';
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const { createVerify } = require('crypto');

const SSM_SINGLE_PATH = '${ssm_single_path}';
const SSM_MULTI_PATH  = '${ssm_multi_path}';
const EXPECTED_ISSUER   = '${expected_issuer}';
const EXPECTED_AUDIENCE = '${expected_audience}';
const REGION = 'us-east-1';

const ssm = new SSMClient({ region: REGION });
let cachedKeys = null;

async function loadKeys() {
  if (cachedKeys) return cachedKeys;
  const keys = {};
  if (SSM_SINGLE_PATH) {
    const r = await ssm.send(new GetParameterCommand({ Name: SSM_SINGLE_PATH, WithDecryption: true }));
    keys['__single__'] = r.Parameter.Value.replace(/\\n/g, '\n');
  }
  if (SSM_MULTI_PATH) {
    const r = await ssm.send(new GetParameterCommand({ Name: SSM_MULTI_PATH, WithDecryption: true }));
    Object.assign(keys, JSON.parse(r.Parameter.Value));
  }
  cachedKeys = keys;
  return keys;
}

const API_PATH_PREFIX = '/api/';
const UNAUTHORIZED = {
  status: '401',
  statusDescription: 'Unauthorized',
  headers: {
    'www-authenticate': [{ key: 'WWW-Authenticate', value: 'Bearer realm="openedx"' }],
    'content-type':     [{ key: 'Content-Type',     value: 'application/json' }],
    'cache-control':    [{ key: 'Cache-Control',     value: 'no-store' }],
  },
  body: JSON.stringify({ error: 'invalid_token', message: 'A valid Bearer token is required.' }),
};

function b64urlDecode(str) {
  return Buffer.from(str.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

async function verifyRS256(token) {
  const keys = await loadKeys();
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Malformed JWT');
  const [headerB64, payloadB64, sigB64] = parts;
  const header = JSON.parse(b64urlDecode(headerB64).toString('utf8'));
  if (header.alg !== 'RS256') throw new Error('Unexpected algorithm: ' + header.alg);

  const key = header.kid
    ? (keys[header.kid] || keys['__single__'])
    : keys['__single__'];
  if (!key) throw new Error('No key for kid: ' + (header.kid || 'none'));

  const verifier = createVerify('RSA-SHA256');
  verifier.update(headerB64 + '.' + payloadB64);
  if (!verifier.verify(key, b64urlDecode(sigB64))) throw new Error('Signature invalid');

  const payload = JSON.parse(b64urlDecode(payloadB64).toString('utf8'));
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) throw new Error('Token expired');
  if (payload.nbf && payload.nbf > now) throw new Error('Token not yet valid');
  if (EXPECTED_ISSUER && payload.iss !== EXPECTED_ISSUER) throw new Error('Invalid issuer');
  if (EXPECTED_AUDIENCE) {
    const aud = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
    if (!aud.includes(EXPECTED_AUDIENCE)) throw new Error('Invalid audience');
  }
  return payload;
}

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  if (!request.uri.startsWith(API_PATH_PREFIX)) return request;
  if (request.method === 'OPTIONS') return request; // skip preflight
  const authHeader = (request.headers['authorization'] || [])[0]?.value || '';
  if (!authHeader.toLowerCase().startsWith('bearer ')) return UNAUTHORIZED;
  try {
    await verifyRS256(authHeader.slice(7).trim());
    return request;
  } catch (err) {
    console.log('JWT validation failed:', err.message);
    return UNAUTHORIZED;
  }
};
