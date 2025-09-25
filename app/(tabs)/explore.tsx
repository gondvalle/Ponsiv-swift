import { useEffect, useMemo, useState, useCallback } from 'react';
import { View, Text, TextInput, StyleSheet, ScrollView, Image, TouchableOpacity } from 'react-native';
import { router } from 'expo-router';
import { useStore } from '@/src/store';
import assetsIndex from '@/src/data/assetsIndex';

const IOS_BG = 'rgba(245,247,251,1)';
const SUMMER_CATS = ['Vestidos','Camisetas','Tops','Bermudas'];

export default function Explore() {
  const { products, sortProductsByLikes } = useStore();

  // ✅ Memoizar la lista base para que NO cambie de identidad en cada render
  const all = useMemo(() => Object.values(products), [products]);

  const [q, setQ] = useState('');

  const filtered = useMemo(() => {
    if (!q.trim()) return all;
    const Q = q.toLowerCase();
    return all.filter(p =>
      (p.title || '').toLowerCase().includes(Q) ||
      (p.brand || '').toLowerCase().includes(Q) ||
      (p.category || '').toLowerCase().includes(Q)
    );
  }, [q, all]);

  // ✅ Banner: usa el índice estático (rápido y estable). Fallback a la primera imagen disponible
  const banner = useMemo<string | null>(() => {
    const fromIndex = (assetsIndex as any)['banners/verano.png'] as string | undefined;
    return fromIndex || all.find(p => (p.images?.length ?? 0) > 0)?.images[0] || null;
  }, [all]);

  const cats = useMemo(() => {
    const set = new Set<string>();
    for (const p of filtered) {
      if (p.category) set.add(p.category);
    }
    return Array.from(set);
  }, [filtered]);

  const [trending, setTrending] = useState(filtered);

  // ✅ Evitar bucles: depende de la “huella” de filtered (ids), no de su identidad de array
  const filteredKey = useMemo(() => filtered.map(p => p.id).join('|'), [filtered]);

  useEffect(() => {
    let alive = true;
    (async () => {
      const sorted = await sortProductsByLikes(filtered);
      if (alive) setTrending(sorted);
    })();
    return () => { alive = false; };
  }, [filteredKey, sortProductsByLikes]); // 👈 NO dependas del array “filtered” en sí

  // Handlers memoizados (evitan recreación innecesaria)
  const openTrendingCb = useCallback((arr: any[], startId: string) => {
    router.push({ pathname: '/feed', params: { mode: 'trending', startId } });
  }, []);
  const openCategoryCb = useCallback((items: any[], startId: string) => {
    router.push({ pathname: '/feed', params: { mode: 'category', startId, ids: JSON.stringify(items.map(p=>p.id)) } });
  }, []);
  const openSummerCb = useCallback((items: any[]) => {
    const summer = items.filter(p => SUMMER_CATS.includes(p.category||''));
    router.push({ pathname: '/feed', params: { mode: 'summer', ids: JSON.stringify(summer.map(p=>p.id)) } });
  }, []);
  const openByChipCb = useCallback((label: string, items: any[]) => {
    const map: Record<string,string[]> = { Camisas:['CAMISA'], Zapatillas:['ZAPATILLA','SNEAKER','NIKE','ADIDAS'], Pantalones:['PANTALON','PANTALÓN'], Chaquetas:['CHAQUETA','SOBRECAMISA'], Vestidos:['VESTIDO'], Tops:['TOP'], Camisetas:['CAMISETA'] };
    const kws = map[label] || [];
    const subset = kws.length ? items.filter(p => kws.some(k => (p.title||'').toUpperCase().includes(k))) : items;
    router.push({ pathname: '/feed', params: { mode: 'chip', ids: JSON.stringify(subset.map(p=>p.id)) } });
  }, []);

  return (
    <View style={{ flex: 1 }}>
      {/* Buscador */}
      <View style={s.searchCard}>
        <TextInput value={q} onChangeText={setQ} placeholder="Buscar marcas, estilos o prendas..." style={s.input} />
      </View>

      <ScrollView contentContainerStyle={{ padding: 12, gap: 12 }}>
        {/* Banner debajo del buscador */}
        {banner && (
          <TouchableOpacity activeOpacity={0.9} onPress={() => openSummerCb(all)}>
            <Image source={{ uri: banner }} style={s.banner} />
          </TouchableOpacity>
        )}

        {/* Chips */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ height: 40 }}>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            {['Todos','Camisas','Zapatillas','Pantalones','Chaquetas','Vestidos','Tops','Camisetas'].map(label => (
              <TouchableOpacity key={label} onPress={() => openByChipCb(label, all)} style={s.chip}><Text>{label}</Text></TouchableOpacity>
            ))}
          </View>
        </ScrollView>

        {/* Tendencias */}
        <Text style={s.h2}>Tendencias del momento</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={{ flexDirection: 'row', gap: 10 }}>
            {trending.map(p => (
              <Card key={p.id} product={p} onPress={() => openTrendingCb(trending, p.id)} showPrice />
            ))}
          </View>
        </ScrollView>

        {/* Categorías */}
        <Text style={s.h2}>Categorías</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={{ flexDirection: 'row', gap: 10 }}>
            {cats.map(cat => {
              const plist = filtered.filter(p => (p.category||'').toLowerCase() === cat.toLowerCase());
              if (!plist.length) return null;
              const cover = plist.find(p => (p.images?.length ?? 0) > 0) || plist[0];
              return <Card key={cat} product={cover} label={cat} onPress={() => openCategoryCb(plist, cover.id)} />;
            })}
          </View>
        </ScrollView>
      </ScrollView>
    </View>
  );
}

function Card({ product, label, onPress, showPrice }: any) {
  const handlePress = onPress ?? (() => router.push(`/detail/${product.id}`));
  return (
    <TouchableOpacity activeOpacity={0.9} onPress={handlePress} style={s.card}>
      {product.images?.[0] ? (
        <Image source={{ uri: product.images[0] }} style={s.cardImg} />
      ) : (<View style={[s.cardImg, { backgroundColor: '#eee' }]} />)}
      <View style={s.cardInfo}>
        <Text style={{ fontSize: 12 }}>{label || product.brand}</Text>
        {showPrice && <Text style={{ fontWeight: '700', fontSize: 13 }}>{product.price.toFixed(2)} €</Text>}
      </View>
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  searchCard: { height: 44, margin: 12, borderRadius: 22, backgroundColor: IOS_BG, paddingHorizontal: 12, justifyContent: 'center' },
  input: { fontSize: 14 },
  banner: { width: '100%', height: 140, borderRadius: 16 },
  h2: { fontSize: 16, fontWeight: '700', marginTop: 4 },
  chip: { backgroundColor: IOS_BG, paddingHorizontal: 12, borderRadius: 16, marginRight: 8, justifyContent: 'center' },
  card: { width: 120, height: 180, borderRadius: 12, backgroundColor: '#fff', overflow: 'hidden' },
  cardImg: { width: '100%', height: 126 },
  cardInfo: { padding: 8, gap: 4 },
});
