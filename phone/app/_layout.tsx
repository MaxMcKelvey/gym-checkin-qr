import "../global.css";

import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

export default function RootLayout() {
  return (
    <>
      <StatusBar style="dark" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: "#ffffff" },
          headerTintColor: "#111827",
          headerShadowVisible: false,
          contentStyle: { backgroundColor: "#ffffff" },
        }}
      >
        <Stack.Screen
          name="index"
          options={{
            title: "Gym",
          }}
        />
        <Stack.Screen
          name="settings"
          options={{
            title: "Settings",
            presentation: "modal",
          }}
        />
      </Stack>
    </>
  );
}
