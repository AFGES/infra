// patch.js
const { createRequire } = require('node:module');
const { X509Certificate } = require('node:crypto');
const fs = require('node:fs');

function getLicenseManager() {
  try {
    const mod = require('@n8n_io/license-sdk');
    if (mod?.LicenseManager) return mod.LicenseManager;
  } catch {}

  const directPaths = [
    '/usr/local/lib/node_modules/n8n/node_modules/@n8n_io/license-sdk/dist/LicenseManager.js',
    './dist/LicenseManager.js',
  ];

  for (const p of directPaths) {
    try {
      if (fs.existsSync(p)) {
        const mod = require(p);
        if (mod?.LicenseManager) return mod.LicenseManager;
      }
    } catch {}
  }

  const n8nRoots = [
    '/usr/local/lib/node_modules/n8n/package.json',
    '/usr/local/lib/node_modules/n8n/dist/index.js',
  ];

  for (const root of n8nRoots) {
    try {
      const req = createRequire(root);
      const mod = req('@n8n_io/license-sdk');
      if (mod?.LicenseManager) return mod.LicenseManager;
    } catch {}
  }

  return null;
}

const LicenseManager = getLicenseManager();

if (LicenseManager) {
  try {
    let certPem = process.env.N8N_LICENSE_ISSUER_CERT;
    const certPath = process.env.N8N_LICENSE_ISSUER_CERT_PATH || '/etc/ssl/certs/license-ca.pem';

    if (!certPem && fs.existsSync(certPath)) {
      certPem = fs.readFileSync(certPath, 'utf8');
    }

    if (certPem) {
      const customCert = new X509Certificate(certPem.trim());
      LicenseManager.prototype.getIssuerCert = function () {
        return customCert;
      };
      console.log('[license-patch] Custom issuer certificate injected.');
    } else {
      console.warn('[license-patch] No certificate provided in N8N_LICENSE_ISSUER_CERT or ' + certPath);
    }
  } catch (err) {
    console.error('[license-patch] Error injecting certificate:', err.message);
  }
}
