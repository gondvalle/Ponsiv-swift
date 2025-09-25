import { useEffect, useMemo, useState, useCallback } from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity, Dimensions, Animated, ScrollView } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
// TODO: Migrar a la nueva API de expo-file-system antes de SDK 55
import * as FileSystem from 'expo-file-system/legacy';
import { Asset } from 'expo-asset';
import { Ionicons } from '@expo/vector-icons';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { useStore } from '@/src/store';
import CollapsibleHeaderScrollView from '@/src/components/CollapsibleHeaderScrollView';
import type { Product } from '@/src/types';
import assetsIndex from '@/src/data/assetsIndex';

const G = Dimensions.get('window');

export default function Profile() {
  const { tab } = useLocalSearchParams<{ tab?: string }>();
  const {
    currentUserId,
    getUser,
    updateUserAvatar,
    getLooks,
    getLikedProductIds,
    getWardrobeIds,
    products,
    orders,
  } = useStore();

  const [active, setActive] = useState(0);
  const [user, setUser] = useState<any>(null);
  const [likeIds, setLikeIds] = useState<string[]>([]);
  const [wardrobeIds, setWardrobeIds] = useState<string[]>([]);

  // ✅ función de carga centralizada
  const loadProfileData = useCallback(async () => {
    if (!currentUserId) { setUser(null); setLikeIds([]); setWardrobeIds([]); return; }
    const u = await getUser(currentUserId);
    setUser(u || null);
    setLikeIds(await getLikedProductIds(currentUserId));
    setWardrobeIds(await getWardrobeIds(currentUserId));
  }, [currentUserId, getUser, getLikedProductIds, getWardrobeIds]);

  // Carga inicial si cambia el usuario
  useEffect(() => { loadProfileData(); }, [loadProfileData]);

  // Tab inicial desde query (?tab=orders)
  useEffect(() => {
    if (tab === 'orders') setActive(3);
  }, [tab]);

  // ✅ Refresca cada vez que la pantalla gana foco (al volver desde el feed)
  useFocusEffect(useCallback(() => {
    loadProfileData();
  }, [loadProfileData]));

  // ✅ usar expo-asset en web
  const defaultAvatar = () => Asset.fromModule(require('@/assets/logos/Ponsiv.png')).uri;
  const avatarUri = user?.avatar_path || defaultAvatar();

  async function changeAvatar() {
    try {
      await ImagePicker.requestMediaLibraryPermissionsAsync();
      const img = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, quality: 0.9 });
      if (img.canceled) return;
      const src = img.assets[0].uri;
      const destDir = FileSystem.documentDirectory + 'avatars/';
      await FileSystem.makeDirectoryAsync(destDir, { intermediates: true }).catch(() => {});
      const dest = destDir + `user_${currentUserId}.jpg`;
      try { await FileSystem.copyAsync({ from: src, to: dest }); await updateUserAvatar(currentUserId!, dest); }
      catch { await updateUserAvatar(currentUserId!, src); }
      await loadProfileData();
    } catch {
      await updateUserAvatar(currentUserId!, defaultAvatar());
      await loadProfileData();
    }
  }

  const myLooks = useMemo(() => {
    const name = user?.name || '';
    return getLooks().filter(lk => lk.author?.name === name);
  }, [user, getLooks]);

  const likeProducts: Product[] = likeIds.map(id => products[id]).filter(Boolean) as Product[];
  const wardrobeProducts: Product[] = wardrobeIds.map(id => products[id]).filter(Boolean) as Product[];

  const tabs = [
    { key: 'looks',    label: 'Looks',   icon: 'grid-outline' as const },
    { key: 'likes',    label: 'Likes',   icon: 'heart-outline' as const },
    { key: 'wardrobe', label: 'Armario', icon: 'briefcase-outline' as const },
    { key: 'orders',   label: 'Pedidos', icon: 'reader-outline' as const },
  ];

  const computedHeaderHeight = user?.bio ? 265 : 215;

  return (
    <CollapsibleHeaderScrollView
      headerHeight={computedHeaderHeight}
      headerContainerStyle={{ backgroundColor: '#fff' }}
      renderHeader={({ opacity, progress }) => (
        <Animated.View style={{ flex: 1, paddingHorizontal: 16, paddingTop: 8, opacity }}>
          <View style={{ height: 110, flexDirection: 'row', justifyContent: 'center', alignItems: 'center' }}>
            <TouchableOpacity onPress={changeAvatar} activeOpacity={0.8}>
              <Animated.Image
                source={{ uri: avatarUri }}
                style={{ width: 90, height: 90, borderRadius: 45, opacity: opacity as any }}
              />
            </TouchableOpacity>
          </View>
          <Animated.Text style={{ textAlign: 'center', fontSize: 20, fontWeight: '700', opacity: opacity as any }}>
            {user?.name || 'Usuario'}
          </Animated.Text>
          <Animated.Text style={{ textAlign: 'center', fontSize: 13, color: 'rgba(0,0,0,0.6)', opacity: opacity as any }}>
            @{user?.handle || 'ponsiver'}
          </Animated.Text>
          {!!user?.bio && (
            <Animated.Text style={{ textAlign: 'center', fontSize: 12, color: 'rgba(0,0,0,0.7)', marginTop: 4, opacity: opacity as any }} numberOfLines={2}>
              {user.bio}
            </Animated.Text>
          )}
          <View style={{ flexDirection: 'row', justifyContent: 'space-around', marginTop: 8 }}>
            <Metric n={myLooks.length} label="Outfits" />
            <Metric n={likeProducts.length} label="Likes" />
            <Metric n={wardrobeProducts.length} label="Armario" />
          </View>
        </Animated.View>
      )}
      stickyHeight={60}
      renderSticky={() => (
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-around', width: '100%', minWidth: 0, paddingHorizontal: 8, backgroundColor: '#fff', borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: 'rgba(0,0,0,0.08)' }}>
          {tabs.map((t, i) => {
            const focused = active === i;
            return (
              <TouchableOpacity key={t.key} onPress={() => setActive(i)} style={{ flex: 1, alignItems: 'center', paddingVertical: 10 }}>
                <Ionicons name={t.icon} size={22} color={focused ? '#000' : 'rgba(0,0,0,0.55)'} />
                <Text style={{ fontSize: 11, marginTop: 4, opacity: focused ? 1 : 0.6 }}>{t.label}</Text>
              </TouchableOpacity>
            );
          })}
        </View>
      )}
      contentContainerStyle={{ paddingBottom: 24 }}
    >
      {/* Pestañas dentro del scroll */}
      

      {/* Contenido */}
      {active === 0 && (
        <GridLooks
          looks={myLooks.map(lk => ({ id: lk.id, img: lk.cover_image, title: lk.title, subtitle: `Por ${lk.author?.name || 'Usuario'}` }))}
        />
      )}
      {active === 1 && <GridProducts products={likeProducts} />}
      {active === 2 && (
        <GridProducts products={wardrobeProducts} resolveImage={wardrobeImageFor} />
      )}
      {active === 3 && <Orders orders={orders} productsMap={products} />}
    </CollapsibleHeaderScrollView>
  );
}

// Selecciona la imagen para el Armario: si existe *_solo.*, usarla; si no, la primera disponible
function wardrobeImageFor(p: Product): string | undefined {
  const brand = p.brand || '';
  const stem = p.id || '';
  const prefix = `productos/${brand}/${stem}/fotos/`;
  const entries = Object.entries(assetsIndex as any)
    .filter(([k]) => k.startsWith(prefix))
    .sort((a, b) => a[0].localeCompare(b[0]));
  if (entries.length === 0) return p.images?.[0] || undefined;
  const solo = entries.find(([k]) => /_solo\.[a-z0-9]+$/i.test(k));
  if (solo) return solo[1] as string;
  const first = entries.find(([k]) => !/_solo\.[a-z0-9]+$/i.test(k));
  return (first ? first[1] : entries[0][1]) as string;
}

function Metric({ n, label }: { n: number; label: string }) {
  return (
    <View style={{ alignItems: 'center' }}>
      <Text style={{ fontSize: 18, fontWeight: '700' }}>{n}</Text>
      <Text style={{ fontSize: 12, color: 'rgba(0,0,0,0.6)' }}>{label}</Text>
    </View>
  );
}

function GridLooks({ looks }: { looks: { id: string; img?: string; title: string; subtitle?: string }[] }) {
  const router = useRouter();
  return (
    <View style={grid.sGrid}>
      {looks.length === 0 ? (
        <Text style={grid.empty}>Aún no tienes looks.</Text>
      ) : looks.map(it => (
        <TouchableOpacity key={it.id} style={grid.card} activeOpacity={0.8} onPress={() => router.push(`/looks/edit?id=${encodeURIComponent(it.id)}`)}>
          {it.img ? <Image source={{ uri: it.img }} style={grid.cover} /> : <View style={[grid.cover, { backgroundColor: '#eee' }]} />}
          <Text style={grid.title} numberOfLines={1}>{it.title}</Text>
          {!!it.subtitle && <Text style={grid.subtitle} numberOfLines={1}>{it.subtitle}</Text>}
        </TouchableOpacity>
      ))}
    </View>
  );
}

function GridProducts({ products, resolveImage }: { products: Product[]; resolveImage?: (p: Product) => string | undefined }) {
  return (
    <View style={grid.sGrid}>
      {products.length === 0 ? (
        <Text style={grid.empty}>Nada por aquí todavía.</Text>
      ) : products.map(p => (
        <View key={p.id} style={grid.card}>
          {(() => { const img = resolveImage ? resolveImage(p) : (p.images?.[0]); return img ? <Image source={{ uri: img }} style={grid.cover} /> : <View style={[grid.cover, { backgroundColor: '#eee' }]} />; })()}
          <Text style={grid.title} numberOfLines={1}>{p.title}</Text>
          <Text style={grid.subtitle} numberOfLines={1}>{p.brand} · {p.price.toFixed(2)} €</Text>
        </View>
      ))}
    </View>
  );
}

function Orders({ orders, productsMap }: { orders: any[]; productsMap: Record<string, Product> }) {
  if (!orders?.length) {
    return <Text style={{ textAlign: 'center', color: 'rgba(0,0,0,0.6)', marginTop: 8 }}>Aún no tienes pedidos.</Text>;
  }
  return (
    <View style={{ gap: 8 }}>
      {orders.map((o: any) => {
        const p = productsMap[o.productId];
        const img = p?.images?.[0];
        const statusStyle = o.status === 'Entregado' ? ord.badgeOk : ord.badgeWarn;
        return (
          <View key={o.id} style={ord.item}>
            {img ? <Image source={{ uri: img }} style={ord.thumb} /> : <View style={[ord.thumb, { backgroundColor: '#eee' }]} />}
            <View style={{ flex: 1 }}>
              <Text style={ord.t1} numberOfLines={1}>{p?.title || o.title}</Text>
              <Text style={ord.t2}>{o.brand} · Talla {o.size}</Text>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 2 }}>
                <Text style={ord.t3}>Pedido: {o.date}</Text>
                <View style={[ord.badge, statusStyle]}>
                  <Text style={ord.badgeTxt}>{o.status}</Text>
                </View>
              </View>
            </View>
          </View>
        );
      })}
    </View>
  );
}

const grid = StyleSheet.create({
  sGrid: { paddingHorizontal: 12, paddingBottom: 20, flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  // Ajuste: restamos también el padding horizontal del ScrollView (8 * 2)
  card: { width: (G.width - (12 * 2) - (8 * 2) - 10) / 2, backgroundColor: '#fff', borderRadius: 16, overflow: 'hidden', paddingBottom: 6 },
  cover: { width: '100%', height: 280},
  title: { fontSize: 14, fontWeight: '700', paddingHorizontal: 8, marginTop: 6 },
  subtitle: { fontSize: 12, color: 'rgba(0,0,0,0.65)', paddingHorizontal: 8, marginTop: 2 },
  empty: { textAlign: 'center', color: 'rgba(0,0,0,0.6)', width: '100%', marginTop: 12 },
});

const ord = StyleSheet.create({
  item: { flexDirection: 'row', gap: 10, backgroundColor: '#fff', padding: 10, borderRadius: 12, borderWidth: 1, borderColor: 'rgba(0,0,0,0.06)' },
  thumb: { width: 56, height: 56, borderRadius: 8 },
  t1: { fontWeight: '700' },
  t2: { color: 'rgba(0,0,0,0.7)', marginTop: 2 },
  t3: { color: 'rgba(0,0,0,0.6)', marginTop: 2 },
  badge: { paddingHorizontal: 8, height: 22, borderRadius: 6, alignItems: 'center', justifyContent: 'center' },
  badgeTxt: { fontSize: 12, fontWeight: '700' },
  badgeWarn: { backgroundColor: '#FFF3C4' },
  badgeOk: { backgroundColor: '#D8F5D4' },
});
