import fs from 'fs';
import path from 'path';
import {
  Environment,
  SignedDataVerifier,
  VerificationException,
  VerificationStatus,
} from '@apple/app-store-server-library';

export const PREMIUM_PRODUCT_ID =
  process.env.PREMIUM_PRODUCT_ID || 'com.nathanfennel.My-Funny-Valentine.premium';

const BUNDLE_ID =
  process.env.APP_BUNDLE_ID || 'com.nathanfennel.My-Funny-Valentine';

const APP_APPLE_ID = process.env.APP_APPLE_ID
  ? Number(process.env.APP_APPLE_ID)
  : undefined;

export interface VerifiedSubscription {
  originalTransactionId: string;
  productId: string;
  /** Epoch milliseconds, or null for a non-expiring entitlement. */
  expiresAt: number | null;
  /** True when the entitlement is currently valid (not expired, not revoked). */
  isActive: boolean;
  environment: 'Sandbox' | 'Production';
}

/**
 * Apple's root certificates, DER-encoded.
 *
 * Provide them either as `APPLE_ROOT_CERTS` (comma-separated base64 DER, which
 * is what you want on Vercel) or as `.cer` files in a `certs/` directory.
 * Download them from https://www.apple.com/certificateauthority/
 *
 * Returns an empty list when unconfigured — callers must fail closed.
 */
export function loadAppleRootCertificates(): Buffer[] {
  const fromEnv = process.env.APPLE_ROOT_CERTS;
  if (fromEnv && fromEnv.trim().length > 0) {
    return fromEnv
      .split(',')
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0)
      .map((entry) => Buffer.from(entry, 'base64'));
  }

  const certsDir = process.env.APPLE_ROOT_CERTS_DIR || path.join(process.cwd(), 'certs');
  try {
    return fs
      .readdirSync(certsDir)
      .filter((file) => file.endsWith('.cer') || file.endsWith('.der'))
      .map((file) => fs.readFileSync(path.join(certsDir, file)));
  } catch {
    return [];
  }
}

function environmentFromEnv(): Environment {
  return process.env.APP_STORE_ENVIRONMENT === 'Production'
    ? Environment.PRODUCTION
    : Environment.SANDBOX;
}

function buildVerifier(environment: Environment): SignedDataVerifier | null {
  const roots = loadAppleRootCertificates();
  if (roots.length === 0) {
    return null;
  }

  // appAppleId is required for (and only meaningful in) production.
  const appAppleId = environment === Environment.PRODUCTION ? APP_APPLE_ID : undefined;

  return new SignedDataVerifier(
    roots,
    /* enableOnlineChecks */ true,
    environment,
    BUNDLE_ID,
    appAppleId
  );
}

function isEnvironmentMismatch(error: unknown): boolean {
  return (
    error instanceof VerificationException &&
    error.status === VerificationStatus.INVALID_ENVIRONMENT
  );
}

/**
 * Verify a StoreKit 2 signed transaction (`Transaction.jwsRepresentation`).
 *
 * Returns null when the transaction cannot be verified, when it is not for the
 * premium product, or when Apple root certificates are not configured. Callers
 * must treat null as "not entitled" — this fails closed by design.
 */
export async function verifySignedTransaction(
  signedTransaction: string
): Promise<VerifiedSubscription | null> {
  const configured = environmentFromEnv();
  const environmentsToTry: Environment[] =
    configured === Environment.PRODUCTION
      ? [Environment.PRODUCTION, Environment.SANDBOX]
      : [Environment.SANDBOX, Environment.PRODUCTION];

  let lastError: unknown;

  for (const environment of environmentsToTry) {
    const verifier = buildVerifier(environment);
    if (!verifier) {
      console.error(
        'App Store verification is not configured: no Apple root certificates found. ' +
          'Set APPLE_ROOT_CERTS or provide certs/*.cer. Refusing to grant premium.'
      );
      return null;
    }

    try {
      const payload = await verifier.verifyAndDecodeTransaction(signedTransaction);

      if (payload.productId !== PREMIUM_PRODUCT_ID) {
        console.warn(
          `Verified transaction is for ${payload.productId}, not ${PREMIUM_PRODUCT_ID}`
        );
        return null;
      }

      if (!payload.originalTransactionId) {
        console.warn('Verified transaction has no originalTransactionId');
        return null;
      }

      const expiresAt = payload.expiresDate ?? null;
      const revoked =
        payload.revocationDate !== undefined && payload.revocationDate !== null;
      const expired = expiresAt !== null && expiresAt <= Date.now();

      return {
        originalTransactionId: payload.originalTransactionId,
        productId: payload.productId,
        expiresAt,
        isActive: !revoked && !expired,
        environment:
          environment === Environment.PRODUCTION ? 'Production' : 'Sandbox',
      };
    } catch (error) {
      lastError = error;
      // A sandbox transaction checked against production (or vice versa) is
      // expected during TestFlight; try the other environment before failing.
      if (isEnvironmentMismatch(error)) {
        continue;
      }
      break;
    }
  }

  console.warn('Transaction verification failed:', lastError);
  return null;
}
