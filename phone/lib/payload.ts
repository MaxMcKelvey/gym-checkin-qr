import { hmac } from "@noble/hashes/hmac";
import { sha1 } from "@noble/hashes/sha1";
import { decode as b32decode } from "hi-base32";

import { EPOCH, MEMBER_SUFFIX_LENGTH, RADIX32 } from "./constants";

export function toRadix32(n: number, width: number): string {
  if (n < 0) {
    throw new Error(`M must be non-negative, got ${n}`);
  }

  let s = "";
  let x = n;
  if (x === 0) {
    s = "0";
  }
  while (x > 0) {
    const r = x % 32;
    x = Math.floor(x / 32);
    s = RADIX32[r] + s;
  }
  return s.padStart(width, "0");
}

export function normalizeMemberSuffix(value: string): string {
  const suffix = value.trim().toUpperCase();
  if (!/^[0-9A-V]*$/.test(suffix)) {
    throw new Error("Member suffix must use radix-32 characters (0-9, A-V)");
  }
  return suffix.padStart(MEMBER_SUFFIX_LENGTH, "0").slice(-MEMBER_SUFFIX_LENGTH);
}

export function isValidMemberSuffix(value: string): boolean {
  return /^[0-9A-V]{5}$/.test(normalizeMemberSuffix(value));
}

export function minuteCounter(unixSeconds: number): number {
  return Math.floor((unixSeconds - EPOCH) / 60);
}

export function decodeSecretB32(secretB32: string): Uint8Array {
  const normalized = secretB32.trim().toUpperCase().replace(/=+$/, "");
  if (!normalized) {
    throw new Error("Secret is required");
  }
  return new Uint8Array(b32decode.asBytes(normalized));
}

export function buildPayload(
  unixSeconds: number,
  key: Uint8Array,
  memberSuffix: string,
): string {
  const m = minuteCounter(unixSeconds);
  const member = normalizeMemberSuffix(memberSuffix);

  const msg = new Uint8Array(8);
  let value = BigInt(m);
  for (let i = 7; i >= 0; i -= 1) {
    msg[i] = Number(value & 0xffn);
    value >>= 8n;
  }

  const digest = hmac(sha1, key, msg);
  const offset = digest[19] & 0x0f;
  const binary =
    ((digest[offset] & 0x7f) << 24) |
    (digest[offset + 1] << 16) |
    (digest[offset + 2] << 8) |
    digest[offset + 3];
  const rolling = toRadix32(binary % 1_000_000, 4);
  const counter = toRadix32(m, 4);

  return `@1${rolling}${counter}${member}`;
}

export function buildPayloadFromConfig(
  unixSeconds: number,
  secretB32: string,
  memberSuffix: string,
): string {
  const key = decodeSecretB32(secretB32);
  return buildPayload(unixSeconds, key, memberSuffix);
}
