import { View, TouchableOpacity, StyleSheet, Text } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useStore } from '@/src/store';

const iconFor: Record<string, keyof typeof Ionicons.glyphMap> = {
  feed: 'home-outline',
  explore: 'search-outline',
  looks: 'grid-outline',
  cart: 'cart-outline',
  profile: 'person-outline',
};

export default function BottomBar({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const cartCount = useStore(s => s.getCartItems().reduce((n, it) => n + it.qty, 0));

  return (
    <View style={[s.bar, { paddingBottom: insets.bottom, height: 48 + insets.bottom }]}>
      {state.routes.map((route, index) => {
        const isFocused = state.index === index;
        const name = route.name;
        const icon = iconFor[name] || 'ellipse-outline';

        const onPress = () => {
          const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
          if (!isFocused && !event.defaultPrevented) navigation.navigate(route.name);
        };

        return (
          <TouchableOpacity key={route.key} style={s.slot} onPress={onPress}>
            <View>
              <Ionicons name={icon} size={26} color={isFocused ? '#000' : 'rgba(0,0,0,0.55)'} />
              {name === 'cart' && cartCount > 0 && (
                <View style={s.badge}><Text style={s.badgeTxt}>{cartCount > 99 ? '99+' : cartCount}</Text></View>
              )}
            </View>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

const s = StyleSheet.create({
  bar: { backgroundColor: '#fff', flexDirection: 'row', borderTopWidth: 1, borderTopColor: 'rgba(0,0,0,0.08)' },
  slot: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  badge: { position: 'absolute', right: -6, top: -4, minWidth: 16, height: 16, borderRadius: 8, backgroundColor: '#000', alignItems: 'center', justifyContent: 'center', paddingHorizontal: 3 },
  badgeTxt: { color: '#fff', fontSize: 10, fontWeight: '700' },
});
