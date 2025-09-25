import { Tabs, usePathname } from "expo-router";
import BottomBar from "@/src/components/BottomBar";

export default function TabsLayout() {
  const pathname = usePathname();
  const isLogin = pathname === "/login";
  return (
    <Tabs tabBar={(props) => isLogin ? null : <BottomBar {...props} />} screenOptions={{ headerShown: false }}>
      <Tabs.Screen name="feed" options={{ title: "" }} />
      <Tabs.Screen name="explore" options={{ title: "" }} />
      <Tabs.Screen name="looks" options={{ title: "" }} />
      <Tabs.Screen name="cart" options={{ title: "" }} />
      <Tabs.Screen name="profile" options={{ title: "" }} />
    </Tabs>
  );
}
