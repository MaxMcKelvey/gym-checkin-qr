import AsyncStorage from "@react-native-async-storage/async-storage";

import { SETTINGS_KEYS } from "./constants";
import { isValidMemberSuffix, normalizeMemberSuffix } from "./payload";

export type AppSettings = {
  secretB32: string;
  memberSuffix: string;
};

export async function loadSettings(): Promise<AppSettings> {
  const [secretB32, memberSuffixRaw, legacyMemberIdRaw] = await Promise.all([
    AsyncStorage.getItem(SETTINGS_KEYS.secretB32),
    AsyncStorage.getItem(SETTINGS_KEYS.memberSuffix),
    AsyncStorage.getItem(SETTINGS_KEYS.memberId),
  ]);

  let memberSuffix = memberSuffixRaw ?? "";
  if (!memberSuffix && legacyMemberIdRaw) {
    memberSuffix = legacyMemberIdRaw;
  }

  return {
    secretB32: secretB32 ?? "",
    memberSuffix: memberSuffix.trim(),
  };
}

export async function saveSettings(settings: AppSettings): Promise<void> {
  const memberSuffix = normalizeMemberSuffix(settings.memberSuffix);
  await Promise.all([
    AsyncStorage.setItem(SETTINGS_KEYS.secretB32, settings.secretB32.trim()),
    AsyncStorage.setItem(SETTINGS_KEYS.memberSuffix, memberSuffix),
    AsyncStorage.removeItem(SETTINGS_KEYS.memberId),
  ]);
}

export function isConfigured(settings: AppSettings): boolean {
  return (
    settings.secretB32.trim().length > 0 &&
    isValidMemberSuffix(settings.memberSuffix)
  );
}
