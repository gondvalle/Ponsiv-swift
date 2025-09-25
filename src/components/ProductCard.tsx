import { View, Text, TouchableOpacity, Image, Platform } from 'react-native';
import type { Product } from '../types';

export default function ProductCard({ product, onPress }: { product: Product; onPress: () => void }) {
  const normalizeWebUri = (u: string | null | undefined) => {
    const s = String(u || '');
    if (!s) return s;
    if (Platform.OS !== 'web') return s;
    if (/^(https?:|data:|file:|blob:)/i.test(s)) return s;
    if (s.startsWith('/')) return s;
    return '/' + s.replace(/^\.\/+/, '');
  };
  return (
    <TouchableOpacity onPress={onPress} style={{ width: 120, marginRight: 12 }}>
      {product.images?.[0] ? (
        <Image source={{ uri: normalizeWebUri(product.images[0]) }} style={{ width: 120, height: 120, borderRadius: 8 }} resizeMode="cover" />
      ) : (
        <View style={{ width: 120, height: 120, borderRadius: 8, backgroundColor: '#eee' }} />
      )}
      <Text numberOfLines={1} style={{ fontWeight: 'bold', marginTop: 4 }}>{product.brand}</Text>
      <Text numberOfLines={1}>{product.title}</Text>
      <Text style={{ fontWeight: 'bold' }}>{product.price}€</Text>
    </TouchableOpacity>
  );
}
