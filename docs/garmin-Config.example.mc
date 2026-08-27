// Copy to source/Config.mc and set your credentials (see docs/extract-credentials.md).
module Config {
    const USE_FIXTURE = false;

    const SECRET_B32 = "YOUR_BASE32_SECRET_HERE";
    // Last 5 chars of the LA Fitness check-in code (radix-32 alphabet)
    const MEMBER_SUFFIX = "00000";
}
