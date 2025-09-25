// src/components/TopBar.tsx
import {
  View,
  Image,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Modal,
  Pressable,
  Text,
  TextInput,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { router, usePathname } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { useStore } from '@/src/store';
import { useState } from 'react';

export default function TopBar() {
  const pathname = usePathname();
  const insets = useSafeAreaInsets();

  // Flecha atrás en mensajes y visor de looks
  const showBack = pathname === '/messages' || pathname === '/looks/view';
  const isLooks = pathname === '/looks';
  const isProfile = pathname === '/profile';

  // Modal "nuevo look"
  const [showModal, setShowModal] = useState(false);
  const [coverUri, setCoverUri] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');

  // Menú Logout en perfil
  const [showLogout, setShowLogout] = useState(false);

  // Pathless group: '(tabs)' is not part of the URL on web
  const goFeed = () => router.replace('/feed'); // logo -> feed en todas
  const goBack = () => router.back();           // flecha en mensajes y visor de looks
  const goMessages = () => router.push('/messages');

  const { currentUserId, getUser, addLook, logout } = useStore();

  const pickImage = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (perm.status !== 'granted') {
      Alert.alert('Permiso denegado', 'Activa el acceso a fotos para subir un look.');
      return;
    }
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      quality: 0.9,
    });
    if (!res.canceled) {
      setCoverUri(res.assets?.[0]?.uri ?? null);
    }
  };

  const openCreateLook = () => {
    setCoverUri(null);
    setTitle('');
    setDesc('');
    setShowModal(true);
  };

  const onCreate = async () => {
    if (!coverUri) {
      Alert.alert('Falta la foto', 'Selecciona una imagen para tu look.');
      return;
    }
    if (!title.trim()) {
      Alert.alert('Nombre requerido', 'Introduce un nombre para tu look.');
      return;
    }
    let authorName = 'Yo';
    if (currentUserId) {
      const u = await getUser(currentUserId);
      authorName = (u?.name || u?.handle || authorName);
    }
    await addLook(title.trim(), authorName, coverUri, [], undefined, desc.trim() || undefined);
    setShowModal(false);
  };

  const doLogout = async () => {
    setShowLogout(false);
    await logout();
    router.replace('/login'); // te lleva directo al login (TopBar no se muestra allí)
  };

  return (
    <View style={[s.bar, { paddingTop: insets.top }]}>
      <View style={s.left}>
        {showBack && (
          <TouchableOpacity onPress={goBack} style={s.iconBtn} hitSlop={8}>
            <Ionicons name="chevron-back" size={24} color="#000" />
          </TouchableOpacity>
        )}
        <TouchableOpacity onPress={goFeed} style={s.logoBtn} hitSlop={8}>
          <Image
            source={require('@/assets/logos/Ponsiv.png')}
            style={[s.logo, !showBack && s.logoTight]}
          />
        </TouchableOpacity>
      </View>

      <View style={s.right}>
        {isLooks ? (
          <TouchableOpacity onPress={openCreateLook} style={s.iconBtn} hitSlop={8}>
            <Ionicons name="add-circle" size={26} color="#000" />
          </TouchableOpacity>
        ) : (
          <>
            <TouchableOpacity onPress={goMessages} style={s.iconBtn} hitSlop={8}>
              <Ionicons name="chatbubble-ellipses-outline" size={24} color="#000" />
            </TouchableOpacity>

            {/* 👇 “Tres rayas” solo en perfil */}
            {isProfile && (
              <TouchableOpacity
                onPress={() => setShowLogout(true)}
                style={s.iconBtn}
                hitSlop={8}
                accessibilityLabel="Menú de perfil"
              >
                {/* Icono de 3 líneas (equivalente a ___ apiladas) */}
                <Ionicons name="reorder-three-outline" size={26} color="#000" />
              </TouchableOpacity>
            )}
          </>
        )}
      </View>

      {/* Modal crear look */}
      <Modal
        transparent
        visible={showModal}
        animationType="fade"
        onRequestClose={() => setShowModal(false)}
      >
        <Pressable style={s.backdrop} onPress={() => setShowModal(false)}>
          <Pressable style={s.sheet} onPress={() => {}}>
            <View style={s.sheetCard}>
              <Text style={s.h1}>Nuevo look</Text>

              {/* Selector imagen */}
              <TouchableOpacity style={s.imagePicker} onPress={pickImage}>
                {coverUri ? (
                  <Image source={{ uri: coverUri }} style={s.preview} />
                ) : (
                  <View style={s.previewPlaceholder}>
                    <Ionicons name="image-outline" size={28} color="#666" />
                    <Text style={s.previewTxt}>Añadir foto</Text>
                  </View>
                )}
              </TouchableOpacity>

              {/* Nombre (obligatorio) */}
              <Text style={s.label}>Nombre del look *</Text>
              <TextInput
                value={title}
                onChangeText={setTitle}
                placeholder="Ej. Look urbano minimal"
                placeholderTextColor="#9CA3AF"
                style={s.input}
              />

              {/* Descripción (opcional) */}
              <Text style={s.label}>Descripción (opcional)</Text>
              <TextInput
                value={desc}
                onChangeText={setDesc}
                placeholder="Añade detalles del look…"
                placeholderTextColor="#9CA3AF"
                style={[s.input, { height: 84, textAlignVertical: 'top' }]}
                multiline
              />

              <View style={s.row}>
                <TouchableOpacity style={s.btnGhost} onPress={() => setShowModal(false)}>
                  <Text style={s.btnGhostTxt}>Cancelar</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[s.btn, (!coverUri || !title.trim()) && s.btnDisabled]}
                  onPress={onCreate}
                  disabled={!coverUri || !title.trim()}
                >
                  <Text style={s.btnTxt}>Subir</Text>
                </TouchableOpacity>
              </View>
            </View>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Modal menú logout (perfil) */}
      <Modal
        transparent
        visible={showLogout}
        animationType="fade"
        onRequestClose={() => setShowLogout(false)}
      >
        <Pressable style={s.backdrop} onPress={() => setShowLogout(false)}>
          <View style={s.menuWrap} pointerEvents="box-none">
            <View style={s.menuCard}>
              <TouchableOpacity style={s.menuItem} onPress={doLogout}>
                <Ionicons name="log-out-outline" size={18} color="#000" />
                <Text style={s.menuTxt}>Cerrar sesión</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[s.menuItem, s.menuCancel]} onPress={() => setShowLogout(false)}>
                <Text style={[s.menuTxt, { fontWeight: '700' }]}>Cancelar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Pressable>
      </Modal>
    </View>
  );
}

const s = StyleSheet.create({
  bar: {
    height: 96,
    backgroundColor: '#fff',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(0,0,0,0.08)',
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingLeft: 12 },
  right: { paddingRight: 12, zIndex: 1, flexDirection: 'row', alignItems: 'center', gap: 4 },
  iconBtn: { padding: 4 },
  logoBtn: { paddingVertical: 4 },
  logo: { width: 300, height: 110, resizeMode: 'contain' },
  logoTight: { marginLeft: -100 },

  // Backdrop genérico
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.35)',
    justifyContent: 'flex-end',
  },
  sheet: { padding: 16 },
  sheetCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 16,
    marginBottom: 30,
  },
  h1: { fontSize: 18, fontWeight: '700', marginBottom: 12 },
  imagePicker: {
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.12)',
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 12,
  },
  preview: { width: '100%', height: 220, resizeMode: 'cover' },
  previewPlaceholder: {
    height: 140,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  previewTxt: { color: '#666' },
  label: { fontSize: 13, color: '#374151', marginTop: 8, marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.12)',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 15,
    color: '#111827',
  },
  row: {
    marginTop: 14,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
  },
  btn: {
    backgroundColor: '#111',
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  btnDisabled: { opacity: 0.4 },
  btnTxt: { color: '#fff', fontWeight: '700' },
  btnGhost: {
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: '#F3F4F6',
  },
  btnGhostTxt: { color: '#111' },

  // Menú logout
  menuWrap: { padding: 16, paddingBottom: 30 },
  menuCard: {
    backgroundColor: '#fff',
    borderRadius: 14,
    paddingVertical: 6,
    overflow: 'hidden',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  menuCancel: {
    borderTopWidth: 1,
    borderTopColor: 'rgba(0,0,0,0.06)',
    justifyContent: 'center',
  },
  menuTxt: { fontSize: 15, color: '#111' },
});
