// app/(tabs)/looks/edit.tsx
import { useEffect, useState } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useStore } from '@/src/store';

export default function EditLook() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id?: string }>();
  const looks = useStore(s => s.looks);
  const updateLook = useStore(s => (s as any).updateLook) as (id: string, changes: { title?: string }) => Promise<void>;
  const deleteLook = useStore(s => (s as any).deleteLook) as (id: string) => Promise<void>;

  const look = id ? looks[String(id)] : undefined;

  const [title, setTitle] = useState('');

  useEffect(() => {
    if (look) setTitle(look.title);
  }, [look?.id]);

  const onSave = async () => {
    if (!id) return;
    try {
      await updateLook(String(id), { title: title.trim() || 'Mi look' });
      Alert.alert('Guardado', 'El look ha sido actualizado.');
      router.back();
    } catch (e) {}
  };

  const onDelete = async () => {
    if (!id) return;
    Alert.alert('Eliminar look', 'Esta acción no se puede deshacer. ¿Eliminar?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Eliminar', style: 'destructive', onPress: async () => {
          try {
            await deleteLook(String(id));
            Alert.alert('Eliminado', 'El look ha sido eliminado.');
            router.back();
          } catch (e) {}
        }
      },
    ]);
  };

  if (!look) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
        <Text>No se encontró el look.</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#fff' }}>
      {/* Header simple */}
      <View style={s.header}>
        <TouchableOpacity onPress={() => router.back()} style={s.hBtn}>
          <Ionicons name="chevron-back" size={22} />
        </TouchableOpacity>
        <Text style={s.hTitle}>Editar look</Text>
        <View style={s.hBtn} />
      </View>

      <View style={{ padding: 16, gap: 12 }}>
        <Text style={s.label}>Título</Text>
        <TextInput
          style={s.input}
          value={title}
          onChangeText={setTitle}
          placeholder="Título del look"
        />

        <TouchableOpacity style={[s.primaryBtn]} onPress={onSave}>
          <Text style={s.primaryText}>Guardar cambios</Text>
        </TouchableOpacity>

        <TouchableOpacity style={[s.dangerBtn]} onPress={onDelete}>
          <Text style={s.dangerText}>Eliminar</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  header: { height: 52, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 8, borderBottomWidth: 1, borderBottomColor: 'rgba(0,0,0,0.06)' },
  hBtn: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  hTitle: { fontSize: 16, fontWeight: '700' },

  label: { fontSize: 13, color: 'rgba(0,0,0,0.7)' },
  input: { height: 44, paddingHorizontal: 12, borderRadius: 10, borderWidth: 1, borderColor: 'rgba(0,0,0,0.12)', backgroundColor: '#fff' },

  primaryBtn: { height: 48, borderRadius: 12, backgroundColor: '#111', alignItems: 'center', justifyContent: 'center', marginTop: 8 },
  primaryText: { color: '#fff', fontWeight: '700' },
  dangerBtn: { height: 48, borderRadius: 12, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: 'rgba(255,0,0,0.35)', marginTop: 6 },
  dangerText: { color: '#c00000', fontWeight: '700' },
});

