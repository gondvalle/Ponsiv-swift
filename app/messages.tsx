import { View, Text, StyleSheet, ScrollView } from 'react-native';

export default function Messages() {
  const msgs = [
    { id: '1', from: 'Ponsiv', text: '¡Bienvenida! Aquí verás tus mensajes.' },
    { id: '2', from: 'Atención al cliente', text: 'Tu pedido #1023 está en camino 🚚' },
  ];
  return (
    <ScrollView contentContainerStyle={{ padding: 12 }}>
      {msgs.map(m => (
        <View key={m.id} style={s.card}>
          <Text style={s.from}>{m.from}</Text>
          <Text style={s.text}>{m.text}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const s = StyleSheet.create({
  card: { backgroundColor: '#fff', padding: 12, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: 'rgba(0,0,0,0.06)' },
  from: { fontWeight: '700', marginBottom: 4 },
  text: { color: 'rgba(0,0,0,0.8)' },
});

