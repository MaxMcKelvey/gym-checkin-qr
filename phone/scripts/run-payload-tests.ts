import { runPayloadTests } from "../lib/payload.test";

const result = runPayloadTests();
if (result.failed > 0) {
  process.exit(1);
}
console.log(`All ${result.passed} payload checks passed`);
