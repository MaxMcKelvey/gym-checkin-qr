import { Ionicons } from "@expo/vector-icons";
import { Link, Stack, useFocusEffect } from "expo-router";
import { useCallback, useState } from "react";
import { ActivityIndicator, Pressable, Text, View } from "react-native";
import QRCode from "react-native-qrcode-svg";
import { SafeAreaView } from "react-native-safe-area-context";

import { usePayload } from "../hooks/usePayload";
import { isConfigured, loadSettings, type AppSettings } from "../lib/settings";

function SettingsButton() {
  return (
    <Link href="/settings" asChild>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Open settings"
        className="mr-2 rounded-full p-2 active:bg-gray-100"
      >
        <Ionicons name="settings-outline" size={24} color="#111827" />
      </Pressable>
    </Link>
  );
}

export default function HomeScreen() {
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const { payload, secondsUntilRefresh, error } = usePayload(
    settings ?? { secretB32: "", memberSuffix: "" },
  );

  const refreshSettings = useCallback(async () => {
    setSettings(await loadSettings());
  }, []);

  useFocusEffect(
    useCallback(() => {
      refreshSettings();
    }, [refreshSettings]),
  );

  if (!settings) {
    return (
      <View className="flex-1 items-center justify-center bg-white">
        <ActivityIndicator size="large" color="#111827" />
      </View>
    );
  }

  const configured = isConfigured(settings);

  return (
    <SafeAreaView className="flex-1 bg-white" edges={["bottom"]}>
      <Stack.Screen
        options={{
          headerRight: () => <SettingsButton />,
        }}
      />

      <View className="flex-1 items-center justify-center px-6">
        {!configured ? (
          <View className="items-center gap-4">
            <Ionicons name="key-outline" size={48} color="#9CA3AF" />
            <Text className="text-center text-lg font-medium text-gray-900">
              Configure your credentials
            </Text>
            <Text className="text-center text-base text-gray-500">
              Tap the settings gear to enter your base32 secret and member ID.
            </Text>
            <Link href="/settings" asChild>
              <Pressable className="mt-2 rounded-xl bg-gray-900 px-6 py-3 active:opacity-80">
                <Text className="text-base font-semibold text-white">
                  Open Settings
                </Text>
              </Pressable>
            </Link>
          </View>
        ) : error ? (
          <View className="items-center gap-3">
            <Text className="text-center text-lg font-medium text-red-600">
              Invalid configuration
            </Text>
            <Text className="text-center text-base text-gray-600">{error}</Text>
          </View>
        ) : payload ? (
          <View className="items-center gap-6">
            <View className="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-gray-100">
              <QRCode value={payload} size={280} backgroundColor="#FFFFFF" />
            </View>
            <Text className="text-xl font-semibold text-gray-900">
              Gym
            </Text>
            <Text className="font-mono text-sm tracking-wider text-gray-400">
              {payload}
            </Text>
            <Text className="text-sm text-gray-500">
              Refreshes in {secondsUntilRefresh}s
            </Text>
          </View>
        ) : null}
      </View>
    </SafeAreaView>
  );
}
