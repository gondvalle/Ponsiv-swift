import { View, Text, TouchableOpacity, Image, Platform } from 'react-native';
import type { Look } from '../types';

export default function LookCard({ look, onPress }: { look: Look; onPress: () => void }) {
  const normalizeWebUri = (u: string | null | undefined) => {
    const s = String(u || '');
    if (!s) return s;
    if (Platform.OS !== 'web') return s;
    if (/^(https?:|data:|file:|blob:)/i.test(s)) return s;
    if (s.startsWith('/')) return s;
    return '/' + s.replace(/^\.\/+/, '');
  };
  return (
    <TouchableOpacity onPress={onPress} style={{ flex: 1, margin: 8 }}>
      {look.cover_image ? (
        <Image source={{ uri: normalizeWebUri(look.cover_image) }} style={{ width: '100%', height: 180, borderRadius: 8 }} resizeMode="cover" />
      ) : (
        <View style={{ width: '100%', height: 180, borderRadius: 8, backgroundColor: '#eee' }} />
      )}
      <Text style={{ fontWeight: 'bold', marginTop: 4 }}>{look.title}</Text>
      <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 2 }}>
        {look.author?.avatar ? (
          <Image source={{ uri: normalizeWebUri(look.author.avatar) }} style={{ width: 24, height: 24, borderRadius: 12, marginRight: 4 }} />
        ) : (
          <View style={{ width: 24, height: 24, borderRadius: 12, marginRight: 4, backgroundColor: '#ccc' }} />
        )}
        <Text>{look.author?.name}</Text>
      </View>
    </TouchableOpacity>
  );
}
