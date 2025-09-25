// src/components/ProductSlide.tsx
import { View, Image, Text, StyleSheet, TouchableOpacity, Share, Modal, Pressable, Platform, FlatList, Dimensions } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useStore } from '@/src/store';
import { useEffect, useMemo, useState } from 'react';
import * as Haptics from 'expo-haptics';
import * as Linking from 'expo-linking';
import type { Product } from '@/src/types';
import assetsIndex from '@/src/data/assetsIndex';

const { width: winW } = Dimensions.get('window');

// Normaliza URIs en web para evitar rutas relativas (p.ej. en /feed)
const normalizeWebUri = (u: string | null | undefined) => {
  const s = String(u || "");
  if (!s) return s;
  // En nativo no tocamos
  if (Platform.OS !== 'web') return s;
  // Si ya es absoluta o esquema conocido, la dejamos
  if (/^(https?:|data:|file:|blob:)/i.test(s)) return s;
  // Si empieza por '/', ya es absoluta desde raíz
  if (s.startsWith('/')) return s;
  // Asegura raíz absoluta
  return '/' + s.replace(/^\.\/+/, '');
};

export default function ProductSlide({ product }: { product: Product }) {
  const { currentUserId, toggleLike, isProductLiked, addToCart, toggleWardrobe, isInWardrobe } = useStore();
  const uid = currentUserId;

  const [liked, setLiked] = useState(false);
  const [inWardrobe, setInWardrobe] = useState(false);
  const [sizeModal, setSizeModal] = useState(false);

  // ➕ nuevo: ocultar UI en pulsación larga sobre la foto
  const [uiHidden, setUiHidden] = useState(false);

  // ✅ helpers haptics safe-web
  const hSelect = () => {
    if (Platform.OS !== 'web') {
      try { Haptics.selectionAsync(); } catch {}
    }
  };
  const hSuccess = () => {
    if (Platform.OS !== 'web') {
      try { Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {}
    }
  };

  useEffect(() => {
    (async () => {
      if (uid) {
        setLiked(await isProductLiked(uid, product.id));
        setInWardrobe(await isInWardrobe(uid, product.id));
      } else {
        setLiked(false); setInWardrobe(false);
      }
    })();
  }, [uid, product.id]);

  const onLike = async () => {
    if (!uid) return;
    const v = await toggleLike(uid, product.id);
    setLiked(v);
    hSelect();
  };

  const onShare = async () => {
    try {
      const url = Linking.createURL(`/detail/${product.id}`);  // ponsiv://detail/ID
      await Share.share({ message: `${product.title} — ${product.price.toFixed(2)} €\n${url}` });
    } catch {}
  };

  const onCart = async () => {
    if (product.sizes?.length) { setSizeModal(true); return; }
    await addToCart(product.id, 1);
    hSuccess();
  };

  const onWardrobe = async () => {
    if (!uid) return;
    const v = await toggleWardrobe(uid, product.id);
    setInWardrobe(v);
    hSelect();
  };

  const pickSize = async (size: string) => {
    setSizeModal(false);
    await addToCart(product.id, 1); // si quieres persistir talla, ampliar esquema
    hSuccess();
  };

  // Determina las fotos a mostrar segun la convención de app.py (FEED no usa la marca _solo)
  const imagesToShow = useMemo(() => {
    const brand = product.brand || '';
    const stem = product.id || '';
    const prefix = `productos/${brand}/${stem}/fotos/`;

    const entries = Object.entries(assetsIndex as any)
      .filter(([k]) => k.startsWith(prefix))
      .sort((a, b) => a[0].localeCompare(b[0]));

    if (!entries.length) return product.images?.length ? [product.images[0]] : [];

    // Usar swipe si hay al menos dos fotos numeradas NN_*.ext (incluye *_solo)
    const numbered = entries.filter(([k]) => /\/(\d{2})_.+\.[a-z0-9]+$/i.test(k));
    if (numbered.length >= 2)
      return numbered
        .map(([, uri]) => normalizeWebUri(uri as string))
        .filter(Boolean) as string[];

    // En cualquier otro caso, usar solo la primera disponible
    const firstNonSolo = entries.find(([k]) => !/_solo\.[a-z0-9]+$/i.test(k));
    return [normalizeWebUri((firstNonSolo || entries[0])[1] as string)].filter(Boolean) as string[];
  }, [product.brand, product.id, product.images]);

  return (
    <View style={s.wrap}>
      {/* Imagen a pantalla completa (long-press dentro de cada item) */}
      <View style={s.absFill}>
        {imagesToShow.length > 1 ? (
          <FlatList
            data={imagesToShow}
            keyExtractor={(uri, i) => `${product.id}-img-${i}`}
            renderItem={({ item }) => (
              <View style={{ width: winW, height: '100%' }}>
                <Pressable
                  onLongPress={() => setUiHidden(true)}
                  onPressOut={() => setUiHidden(false)}
                  delayLongPress={180}
                  style={s.absFill}
                >
                  <Image source={{ uri: normalizeWebUri(item) }} style={s.img} resizeMode="cover" />
                </Pressable>
              </View>
            )}
            horizontal
            pagingEnabled
            nestedScrollEnabled
            snapToInterval={winW}
            decelerationRate="fast"
            disableIntervalMomentum
            showsHorizontalScrollIndicator={false}
            style={s.absFill}
          />
        ) : imagesToShow[0] ? (
          <Pressable
            onLongPress={() => setUiHidden(true)}
            onPressOut={() => setUiHidden(false)}
            delayLongPress={180}
            style={s.absFill}
          >
            <Image source={{ uri: normalizeWebUri(imagesToShow[0]) }} style={s.img} resizeMode="cover" />
          </Pressable>
        ) : (
          <View style={[s.img, { backgroundColor: '#eee' }]} />
        )}
      </View>

      {/* Tarjeta info (se oculta en vista limpia) */}
      <View style={[s.info, uiHidden && s.hidden]} pointerEvents={uiHidden ? 'none' : 'auto'}>
        {/* 🔁 título ahora puede ocupar varias líneas (se ajusta la altura); minHeight en s.info evita que sea más pequeña */}
        <Text style={s.title}>{product.title}</Text>
        <Text style={s.brand}>{product.brand}</Text>
        <Text style={s.price}>{product.price.toFixed(2)} €</Text>
      </View>

      {/* Chips derecha (se ocultan en vista limpia) */}
      <View style={[s.col, uiHidden && s.hidden]} pointerEvents={uiHidden ? 'none' : 'auto'}>
        <Circle onPress={onLike} name={liked ? 'heart' : 'heart-outline'} active={liked} />
        <Circle onPress={onShare} name="share-social-outline" />
        <Circle onPress={onCart} name="cart-outline" />
        <Circle onPress={onWardrobe} name={inWardrobe ? 'briefcase' : 'briefcase-outline'} active={inWardrobe} />
      </View>

      {/* Modal talla */}
      <Modal transparent visible={sizeModal} animationType="fade" onRequestClose={() => setSizeModal(false)}>
        <Pressable style={s.backdrop} onPress={() => setSizeModal(false)}>
          <View style={s.sheet} pointerEvents="box-none">
            <View style={s.sheetCard}>
              <Text style={{ fontWeight:'700', fontSize:16, marginBottom:8 }}>Elige tu talla</Text>
              <View style={{ flexDirection:'row', flexWrap:'wrap', gap:8 }}>
                {(product.sizes || []).map(sz => (
                  <TouchableOpacity key={sz} style={s.sizeBtn} onPress={() => pickSize(sz)}>
                    <Text style={s.sizeTxt}>{sz}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          </View>
        </Pressable>
      </Modal>
    </View>
  );
}

function Circle({ onPress, name, active }: { onPress: () => void; name: keyof typeof Ionicons.glyphMap; active?: boolean }) {
  return (
    <TouchableOpacity onPress={onPress} style={[cs.wrap, active && cs.active]}>
      <Ionicons name={name} size={20} color={active ? '#fff' : '#000'} />
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1 },

  // Capa interactiva para la imagen (detrás de la UI)
  absFill: { position: 'absolute', left: 0, top: 0, right: 0, bottom: 0 },

  img: { width: '100%', height: '100%' },

  // ⬇️ Caja blanca: ahora crece con el texto, pero no baja de una altura mínima
  info: {
    position: 'absolute',
    left: '5%',
    bottom: '6%',
    width: '60%',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 10,
    minHeight: 72,            // <- evita que sea más pequeña que antes
  },
  hidden: { opacity: 0 },

  // título multi-línea (sin numberOfLines) para que la tarjeta crezca si hace falta
  title: { fontSize: 15, fontWeight: '600', color: '#000' },
  brand: { fontSize: 13, color: 'rgba(0,0,0,0.7)', marginTop: 2 },
  price: { fontSize: 13, color: '#000', fontWeight: '700', marginTop: 2 },

  col: { position: 'absolute', right: '3.5%', top: '25%', gap: 14 },

  backdrop: { flex:1, backgroundColor:'rgba(0,0,0,0.35)', justifyContent:'flex-end' },
  sheet: { padding: 16 },
  sheetCard: { backgroundColor:'#fff', borderRadius:16, padding:16 },
  sizeBtn: { height: 36, paddingHorizontal: 14, borderWidth:1, borderColor:'rgba(0,0,0,0.15)', borderRadius: 18, alignItems:'center', justifyContent:'center' },
  sizeTxt: { fontWeight:'700' },
});

const cs = StyleSheet.create({
  wrap: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center' },
  active: { backgroundColor: '#000' },
});

