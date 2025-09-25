import { Stack } from "expo-router";
import { usePathname } from "expo-router";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import TopBar from "@/src/components/TopBar";
import { useEffect } from "react";
import { ActivityIndicator, View, Image } from "react-native";
import { useStore } from "@/src/store";

export default function RootLayout() {
  const pathname = usePathname();
  const bootstrap = useStore((s) => s.bootstrap);
  const ready = useStore((s) => s.ready);

  useEffect(() => { bootstrap(); }, []);
  const isLogin = pathname === "/login";

  if (!ready) {
    return (
      <SafeAreaProvider>
        <StatusBar style="dark" />
        <View style={{ flex:1, alignItems:'center', justifyContent:'center', gap:16 }}>
          <Image source={require('@/assets/logos/Ponsiv.png')} style={{ width:140, height:36, resizeMode:'contain' }} />
          <ActivityIndicator />
        </View>
      </SafeAreaProvider>
    );
  }

  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      <Stack>
        {/* Tabs: TopBar visible salvo en /login */}
        <Stack.Screen
          name="(tabs)"
          options={{ header: () => (!isLogin ? <TopBar /> : null) }}
        />
        {/* Login sin header */}
        <Stack.Screen name="login" options={{ headerShown: false }} />
        {/* Rutas con header propio */}
        <Stack.Screen name="messages" options={{ header: () => <TopBar /> }} />
        <Stack.Screen name="detail/[id]" options={{ header: () => <TopBar /> }} />
      </Stack>
    </SafeAreaProvider>
  );
}
