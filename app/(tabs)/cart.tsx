import { View, Text, FlatList, Image, TouchableOpacity, StyleSheet } from 'react-native';
import { useStore } from '@/src/store';
import { useRouter } from 'expo-router';
import type { Product } from '@/src/types';

export default function Cart() {
  const router = useRouter();
  const { getCartItems, getCartTotal, addToCart, removeOneFromCart, removeLineFromCart, clearCart, placeOrder } = useStore();
  const items = getCartItems();
  const total = getCartTotal();

  return (
    <View style={{ flex: 1, backgroundColor: '#fff' }}>
      {items.length === 0 ? (
        <Text style={{ textAlign: 'center', marginTop: 24, color: 'rgba(0,0,0,0.6)' }}>Tu carrito está vacío.</Text>
      ) : (
        <FlatList
          data={items}
          keyExtractor={(it) => it.product.id}
          contentContainerStyle={{ padding: 12, paddingBottom: 96 }}
          renderItem={({ item }) => <Row item={item} onPlus={() => addToCart(item.product.id, 1)} onMinus={() => removeOneFromCart(item.product.id)} onRemove={() => removeLineFromCart(item.product.id)} />}
        />
      )}

      {/* Total / Acciones */}
      <View style={s.bottom}>
        <Text style={s.total}>Total: {total.toFixed(2)} €</Text>
        <View style={{ flexDirection: 'row', gap: 8 }}>
          <Action onPress={clearCart} label="Vaciar" />
          <Action
            onPress={async () => {
              await placeOrder();
              try { router.push('/(tabs)/profile?tab=orders'); } catch { router.push('/profile'); }
            }}
            label="Realizar pedido"
            primary
          />
        </View>
      </View>
    </View>
  );
}

function Row({ item, onPlus, onMinus, onRemove }: {
  item: { product: Product; qty: number };
  onPlus: () => void; onMinus: () => void; onRemove: () => void;
}) {
  const p = item.product;
  const img = p.images?.[0];
  return (
    <View style={s.row}>
      {img ? <Image source={{ uri: img }} style={s.thumb} /> : <View style={[s.thumb, { backgroundColor: '#eee' }]} />}
      <View style={{ flex: 1 }}>
        <Text numberOfLines={1} style={{ fontWeight: '700' }}>{p.title}</Text>
        <Text style={{ color: 'rgba(0,0,0,0.7)', marginTop: 2 }}>{p.brand}</Text>
        <Text style={{ fontWeight: '700', marginTop: 2 }}>{p.price.toFixed(2)} €</Text>
      </View>
      <View style={s.qty}>
        <TouchableOpacity onPress={onMinus} style={s.qBtn}><Text style={s.qTxt}>−</Text></TouchableOpacity>
        <Text style={s.qNum}>{item.qty}</Text>
        <TouchableOpacity onPress={onPlus} style={s.qBtn}><Text style={s.qTxt}>＋</Text></TouchableOpacity>
      </View>
      <TouchableOpacity onPress={onRemove}><Text style={{ color: '#d22' }}>Eliminar</Text></TouchableOpacity>
    </View>
  );
}

function Action({ label, onPress, primary }: { label: string; onPress: () => void; primary?: boolean }) {
  return (
    <TouchableOpacity onPress={onPress} style={[s.btn, primary && s.btnPri]}>
      <Text style={[s.btnTxt, primary && s.btnTxtPri]}>{label}</Text>
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: '#fff', padding: 10, borderRadius: 12, marginBottom: 10, elevation: 0.5 },
  thumb: { width: 64, height: 64, borderRadius: 8 },
  qty: { flexDirection: 'row', alignItems: 'center', gap: 6, marginRight: 8 },
  qBtn: { width: 28, height: 28, borderRadius: 14, borderWidth: 1, borderColor: 'rgba(0,0,0,0.15)', alignItems: 'center', justifyContent: 'center' },
  qTxt: { fontSize: 16, fontWeight: '700' },
  qNum: { minWidth: 18, textAlign: 'center' },
  bottom: { position: 'absolute', left: 0, right: 0, bottom: 0, padding: 12, backgroundColor: '#fff', borderTopWidth: 1, borderTopColor: 'rgba(0,0,0,0.08)', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  total: { fontSize: 16, fontWeight: '700' },
  btn: { paddingHorizontal: 14, height: 40, borderRadius: 10, borderWidth: 1, borderColor: 'rgba(0,0,0,0.15)', alignItems: 'center', justifyContent: 'center' },
  btnPri: { backgroundColor: '#E3C393', borderColor: '#E3C393' },
  btnTxt: { fontWeight: '700' },
  btnTxtPri: { color: '#000' },
});

