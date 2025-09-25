import { useEffect, useRef, useState } from 'react';
import { View, Dimensions, FlatList, NativeScrollEvent, NativeSyntheticEvent } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useScrollToTop } from '@react-navigation/native';
import ProductSlide from '@/src/components/ProductSlide';
import { useStore } from '@/src/store';
import type { Product } from '@/src/types';

const { height: winH } = Dimensions.get('window');

export default function Feed() {
  const { products, sortProductsByLikes } = useStore();
  const params = useLocalSearchParams<{ mode?: string; ids?: string; startId?: string }>();

  const listRef = useRef<FlatList<Product>>(null);
  useScrollToTop(listRef);

  const [source, setSource] = useState<Product[]>([]);
  const [data, setData] = useState<Product[]>([]);
  // Altura real del área visible (descuenta TopBar y BottomBar automáticamente)
  const [slideH, setSlideH] = useState(winH);
  const chunkSize = useRef(0);

  useEffect(() => {
    const all = Object.values(products);
    if (!all.length) return;

    (async () => {
      let base: Product[] = all;

      // lee subset si viene de Explore
      if (params.ids) {
        try {
          const ids = JSON.parse(String(params.ids)) as string[];
          base = ids.map(id => products[id]).filter(Boolean) as Product[];
        } catch {}
      } else if (params.mode === 'trending') {
        base = await sortProductsByLikes(all);
      }

      // startId primero si llega
      if (params.startId) {
        base = reorderStart(base, String(params.startId));
      }

      if (!base.length) base = all;

      chunkSize.current = Math.max(1, base.length);
      setSource(base);
      setData([...shuffle(base), ...shuffle(base)]);
    })();
  }, [products, params.ids, params.mode, params.startId, sortProductsByLikes]);

  const onEndReached = () => {
    if (!source.length) return;
    setData(d => [...d, ...shuffle(source)]);
  };

  const onMomentumScrollEnd = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    const h = Math.max(1, slideH);
    const idx = Math.round(e.nativeEvent.contentOffset.y / h);
    const maxChunks = 3;
    if (data.length > maxChunks * chunkSize.current && idx > chunkSize.current) {
      setData(d => d.slice(chunkSize.current));
    }
  };

  return (
    <View
      style={{ flex: 1, backgroundColor: '#000' }}
      onLayout={e => setSlideH(e.nativeEvent.layout.height)}
    >
      <FlatList
        ref={listRef}
        data={data}
        keyExtractor={(it, i) => `${it.id}-${i}`}
        renderItem={({ item }) => (
          <View style={{ height: slideH }}>
            <ProductSlide product={item} />
          </View>
        )}
        pagingEnabled
        onEndReachedThreshold={0.4}
        onEndReached={onEndReached}
        onMomentumScrollEnd={onMomentumScrollEnd}
      />
    </View>
  );
}

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function reorderStart(arr: Product[], startId: string) {
  const idx = arr.findIndex(p => p.id === startId);
  if (idx <= 0) return arr;
  return [...arr.slice(idx), ...arr.slice(0, idx)];
}
