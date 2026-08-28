/** Shared constants from docs/algorithm.md */

export const EPOCH = 1767225600; // 2026-01-01 00:00:00 UTC

export const RADIX32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV";

export const MEMBER_SUFFIX_LENGTH = 5;

export const SETTINGS_KEYS = {
  secretB32: "@gym/secretB32",
  memberSuffix: "@gym/memberSuffix",
  /** @deprecated Legacy decimal member id storage */
  memberId: "@gym/memberId",
} as const;
