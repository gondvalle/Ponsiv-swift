// app/(tabs)/looks/index.tsx
import { useEffect, useState } from 'react';
import { View, TextInput, StyleSheet, ScrollView, Text, Image, TouchableOpacity, Dimensions, Alert } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useStore } from '@/src/store';

const G = Dimensions.get('window');

export default function Looks() {
  const router = useRouter();
  const { getLooks, searchLooks, addLook, currentUserId, getUser } = useStore();
  const [q, setQ] = useState('');
  const looks = q ? searchLooks(q) : getLooks();
  const params = useLocalSearchParams();

  useEffect(() => { if (params.create === '1') pickAndCreate(); }, [params.create]);

  async function pickAndCreate() {
    try {
      await ImagePicker.requestMediaLibraryPermissionsAsync();
      const img = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, quality: 0.9 });
      if (img.canceled) return;
      const uri = img.assets[0].uri;

      let author = 'Usuario', avatar = 'assets/logos/Ponsiv.png';
      if (currentUserId) {
        const u = await getUser(currentUserId);
        author = (u?.name || 'Usuario');
        avatar = (u?.avatar_path || 'assets/logos/Ponsiv.png') as string;
      }
      await addLook('Mi look', author, uri, [], avatar);
      Alert.alert('Look creado');
    } catch {}
  }

  const openViewer = (startId: string) => {
    const ids = looks.map(l => l.id); // subset actual (si hay búsqueda, solo esos)
    const qs = encodeURIComponent(JSON.stringify(ids));
    // 👉 navega dentro del MISMO tab (esta carpeta), no crea un tab nuevo
    router.push(`/looks/view?ids=${qs}&startId=${startId}`);
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#fff' }}>
      <View style={s.searchCard}>
        <TextInput style={s.input} value={q} onChangeText={setQ} placeholder="Buscar looks, estilos o prendas..." />
      </View>

      <ScrollView contentContainerStyle={s.grid}>
        {looks.length === 0 ? (
          <Text style={{ textAlign: 'center', color: 'rgba(0,0,0,0.6)' }}>No hay looks que coincidan con tu búsqueda.</Text>
        ) : looks.map(look => (
          <TouchableOpacity
            key={look.id}
            style={s.card}
            activeOpacity={0.8}
            onPress={() => openViewer(look.id)}
          >
            {look.cover_image ? (
              <Image source={{ uri: look.cover_image }} style={s.cover} />
            ) : (<View style={[s.cover,{backgroundColor:'#eee'}]} />)}
            <Text style={s.title} numberOfLines={1}>{look.title}</Text>
            <View style={s.row}>
              {look.author?.avatar ? (
                <Image source={{ uri: look.author.avatar }} style={s.avatar} />
              ) : (
                <View style={[s.avatar, { backgroundColor: '#fff' }]} />
              )}
              <Text style={s.author} numberOfLines={1}>Por {look.author?.name || 'Usuario'}</Text>
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

const s = StyleSheet.create({
  searchCard: { height: 44, margin: 12, borderRadius: 22, backgroundColor: 'rgba(245,247,251,1)', paddingHorizontal: 12, justifyContent: 'center' },
  input: { fontSize: 14 },
  grid: { paddingHorizontal: 12, paddingBottom: 20, flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  card: { width: (G.width - 12*2 - 10)/2, backgroundColor: '#fff', borderRadius: 16, overflow: 'hidden', paddingBottom: 6 },
  cover: { width: '100%', height: 280 },
  title: { fontSize: 14, fontWeight: '700', paddingHorizontal: 8, marginTop: 6 },
  row: { height: 26, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8, gap: 6 },
  avatar: { width: 20, height: 20, borderRadius: 10 },
  author: { fontSize: 12, color: 'rgba(0,0,0,0.65)', flex: 1 },
});
