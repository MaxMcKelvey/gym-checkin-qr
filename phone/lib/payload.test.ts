import { decodeSecretB32, buildPayload, normalizeMemberSuffix } from "./payload";

/** Synthetic public fixture — see docs/algorithm.md */
const FIXTURE_SECRET_B32 = "JBSWY3DPEHPK3PXP";
const FIXTURE_MEMBER_SUFFIX = "BOOAE";

const VECTORS: [number, string][] = [
  [1767225600, "@18K480000BOOAE"],
  [1767225659, "@18K480000BOOAE"],
  [1767225660, "@1UD6A0001BOOAE"],
  [1767229200, "@122DD001SBOOAE"],
];

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function runPayloadTests(): { passed: number; failed: number } {
  let failed = 0;

  const key = decodeSecretB32(FIXTURE_SECRET_B32);
  if (bytesToHex(key) !== "48656c6c6f21deadbeef") {
    console.error("FAIL key decode");
    failed += 1;
  }

  if (normalizeMemberSuffix("BOOAE") !== FIXTURE_MEMBER_SUFFIX) {
    console.error("FAIL member suffix normalize");
    failed += 1;
  }

  for (const [ts, expected] of VECTORS) {
    const got = buildPayload(ts, key, FIXTURE_MEMBER_SUFFIX);
    if (got !== expected) {
      console.error(`FAIL ts=${ts} got=${got} expected=${expected}`);
      failed += 1;
    }
  }

  return { passed: VECTORS.length + 2 - failed, failed };
}
