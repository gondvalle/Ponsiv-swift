import { View, Dimensions } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useStore } from '@/src/store';
import ProductSlide from '@/src/components/ProductSlide';

const { height } = Dimensions.get('window');

export default function Detail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { products } = useStore();
  const p = products[id || ''];

  if (!p) return <View style={{ flex: 1, backgroundColor: '#000' }} />;

  return (
    <View style={{ flex: 1, backgroundColor: '#000' }}>
      <View style={{ height }}>
        <ProductSlide product={p} />
      </View>
    </View>
  );
}

