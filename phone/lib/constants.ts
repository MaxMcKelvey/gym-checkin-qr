/** Shared constants from docs/algorithm.md */

export const RADIX32 = "0123456789ABCDEFGHIJKLMNOPQRSTUV";

export const MEMBER_SUFFIX_LENGTH = 5;

export const SETTINGS_KEYS = {
  secretB32: "@gym/secretB32",
  memberSuffix: "@gym/memberSuffix",
  /** @deprecated Legacy decimal member id storage */
  memberId: "@gym/memberId",
} as const;
