import { router } from "expo-router";
import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  Text,
  TextInput,
  View,
} from "react-native";

import { normalizeMemberSuffix } from "../lib/payload";
import { loadSettings, saveSettings, type AppSettings } from "../lib/settings";

export default function SettingsScreen() {
  const [loading, setLoading] = useState(true);
  const [secretB32, setSecretB32] = useState("");
  const [memberIdText, setMemberIdText] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadSettings().then((settings) => {
      setSecretB32(settings.secretB32);
      setMemberIdText(settings.memberSuffix);
      setLoading(false);
    });
  }, []);

  const handleSave = async () => {
    if (!secretB32.trim()) {
      Alert.alert("Secret required", "Enter your RFC 4648 base32 secret.");
      return;
    }
    if (!memberIdText.trim()) {
      Alert.alert("Member suffix required", "Enter the 5-character ID suffix.");
      return;
    }

    setSaving(true);
    try {
      const memberSuffix = normalizeMemberSuffix(memberIdText);
      const settings: AppSettings = {
        secretB32: secretB32.trim(),
        memberSuffix,
      };
      await saveSettings(settings);
      router.back();
    } catch {
      Alert.alert(
        "Invalid member suffix",
        "Use 5 radix-32 characters: 0-9 and A-V (e.g. O5TUJ).",
      );
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <View className="flex-1 items-center justify-center bg-white">
        <ActivityIndicator size="large" color="#111827" />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      className="flex-1 bg-white"
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ gap: 24, padding: 24 }}
        keyboardShouldPersistTaps="handled"
      >
        <View className="gap-2">
          <Text className="text-sm font-medium text-gray-700">
            Base32 secret
          </Text>
          <TextInput
            autoCapitalize="characters"
            autoCorrect={false}
            className="rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 font-mono text-base text-gray-900"
            placeholder="Base32 secret from CheckinValues"
            placeholderTextColor="#9CA3AF"
            secureTextEntry
            value={secretB32}
            onChangeText={setSecretB32}
          />
          <Text className="text-sm text-gray-500">
            From LA Fitness Android app CheckinValues — see docs/extract-credentials.md
            in the repo. Stored locally on this device only.
          </Text>
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium text-gray-700">Member suffix</Text>
          <TextInput
            autoCapitalize="characters"
            autoCorrect={false}
            className="rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 font-mono text-base text-gray-900"
            placeholder="O5TUJ"
            placeholderTextColor="#9CA3AF"
            maxLength={5}
            value={memberIdText}
            onChangeText={setMemberIdText}
          />
          <Text className="text-sm text-gray-500">
            Last 5 characters of the check-in code (radix-32). Compare with the
            official app QR if unsure.
          </Text>
        </View>

        <Pressable
          accessibilityRole="button"
          className="items-center rounded-xl bg-gray-900 py-4 active:opacity-80 disabled:opacity-50"
          disabled={saving}
          onPress={handleSave}
        >
          {saving ? (
            <ActivityIndicator color="#ffffff" />
          ) : (
            <Text className="text-base font-semibold text-white">
              Save &amp; Close
            </Text>
          )}
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
