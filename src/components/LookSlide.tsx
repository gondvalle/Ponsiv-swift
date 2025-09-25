// src/components/LookSlide.tsx
import React, { useEffect, useMemo, useState } from 'react';
import {
  View,
  Image,
  Text,
  StyleSheet,
  TouchableOpacity,
  Share,
  Pressable,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useStore } from '@/src/store';
import * as Linking from 'expo-linking';
import type { Look } from '@/src/types';

export default function LookSlide({ look }: { look: Look }) {
  const { currentUserId, toggleLike, isProductLiked } = useStore();
  const uid = currentUserId;

  const [liked, setLiked] = useState(false);
  const [uiHidden, setUiHidden] = useState(false);

  const normalizeWebUri = (u: string | null | undefined) => {
    const s = String(u || '');
    if (!s) return s;
    if (Platform.OS !== 'web') return s;
    if (/^(https?:|data:|file:|blob:)/i.test(s)) return s;
    if (s.startsWith('/')) return s;
    return '/' + s.replace(/^\.\/+/, '');
  };

  const cover = useMemo(() => ({ uri: normalizeWebUri(look.cover_image) }), [look.cover_image]);
  const avatarSrc = useMemo(
    () => (look.author?.avatar ? { uri: normalizeWebUri(look.author.avatar) } : undefined),
    [look.author?.avatar]
  );
  const authorName = look.author?.name || 'Usuario';

  useEffect(() => {
    (async () => {
      if (uid) setLiked(await isProductLiked(uid, look.id)); // reutiliza likes con id de look
      else setLiked(false);
    })();
  }, [uid, look.id, isProductLiked]);

  const onLike = async () => {
    if (!uid) return;
    const v = await toggleLike(uid, look.id);
    setLiked(v);
  };

  const onShare = async () => {
    try {
      const url = Linking.createURL(`/looks/${look.id}`);
      await Share.share({ message: `${look.title}\n${url}` });
    } catch {}
  };

  const onComment = () => {
    // Aquí puedes navegar a comentarios si lo implementas
    // router.push(`/looks/${look.id}/comments`)
  };

  return (
    <View style={s.wrap}>
      {/* Imagen a pantalla completa con pulsación larga para vista limpia */}
      <Pressable
        onLongPress={() => setUiHidden(true)}
        onPressOut={() => setUiHidden(false)}
        delayLongPress={180}
        style={s.absFill}
      >
        {cover?.uri ? (
          <Image source={cover} style={s.img} resizeMode="cover" />
        ) : (
          <View style={[s.img, { backgroundColor: '#ddd' }]} />
        )}
      </Pressable>

      {/* Tarjeta blanca (título + avatar+autor) */}
      <View style={[s.info, uiHidden && s.hidden]} pointerEvents={uiHidden ? 'none' : 'auto'}>
        <Text style={s.title}>{look.title}</Text>

        <View style={s.authorRow}>
          {avatarSrc ? (
            <Image source={avatarSrc} style={s.avatar} />
          ) : (
            <View style={[s.avatar, s.avatarPh]}>
              <Ionicons name="person" size={14} color="#888" />
            </View>
          )}
          <Text style={s.authorName} numberOfLines={1}>{authorName}</Text>
        </View>
      </View>

      {/* Tres botones: like, compartir, comentar */}
      <View style={[s.col, uiHidden && s.hidden]} pointerEvents={uiHidden ? 'none' : 'auto'}>
        <Circle onPress={onLike} name={liked ? 'heart' : 'heart-outline'} active={liked} />
        <Circle onPress={onShare} name="share-social-outline" />
        <Circle onPress={onComment} name="chatbubble-ellipses-outline" />
      </View>
    </View>
  );
}

function Circle({
  onPress,
  name,
  active,
}: {
  onPress: () => void;
  name: keyof typeof Ionicons.glyphMap;
  active?: boolean;
}) {
  return (
    <TouchableOpacity onPress={onPress} style={[cs.wrap, active && cs.active]}>
      <Ionicons name={name} size={20} color={active ? '#fff' : '#000'} />
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: '#000' },
  absFill: { position: 'absolute', left: 0, top: 0, right: 0, bottom: 0 },

  // “Más largas”: usamos la imagen como cover a pantalla completa (igual que feed)
  img: { width: '100%', height: '100%' },

  // Tarjeta blanca autoajustable (crece con el título)
  info: {
    position: 'absolute',
    left: '5%',
    bottom: '6%',
    width: '68%',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 12,
    minHeight: 76,
  },
  hidden: { opacity: 0 },

  title: { fontSize: 16, fontWeight: '700', color: '#111' },

  authorRow: {
    marginTop: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  avatar: { width: 22, height: 22, borderRadius: 11 },
  avatarPh: { backgroundColor: '#f0f0f0', alignItems: 'center', justifyContent: 'center' },
  authorName: { fontSize: 13, color: '#111', fontWeight: '600', flexShrink: 1 },

  col: { position: 'absolute', right: '3.5%', top: '25%', gap: 14 },
});

const cs = StyleSheet.create({
  wrap: {
    width: 40, height: 40, borderRadius: 20,
    backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center',
  },
  active: { backgroundColor: '#000' },
});
