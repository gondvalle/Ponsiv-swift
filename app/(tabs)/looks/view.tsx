// app/(tabs)/looks/view.tsx
import { useEffect, useRef, useState } from 'react';
import { View, Dimensions, FlatList, NativeScrollEvent, NativeSyntheticEvent } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useScrollToTop } from '@react-navigation/native';
import { useStore } from '@/src/store';
import LookSlide from '@/src/components/LookSlide';
import type { Look } from '@/src/types';

const { height: winH } = Dimensions.get('window');

export default function LooksView() {
  const { ids, startId } = useLocalSearchParams<{ ids?: string; startId?: string }>();
  const looksMap = useStore(s => s.looks);
  const getLooks = useStore(s => s.getLooks);

  const [source, setSource] = useState<Look[]>([]);
  const [data, setData] = useState<Look[]>([]);
  const [slideH, setSlideH] = useState(winH);
  const chunkSize = useRef(0);

  const listRef = useRef<FlatList<Look>>(null);
  useScrollToTop(listRef);

  useEffect(() => {
    let base: Look[] = [];

    if (ids) {
      try {
        const arr = JSON.parse(String(ids)) as string[];
        base = arr.map(id => looksMap[id]).filter(Boolean) as Look[];
      } catch {}
    }
    if (!base.length) base = getLooks();

    if (startId) {
      const idx = base.findIndex(l => l.id === String(startId));
      if (idx > 0) base = [...base.slice(idx), ...base.slice(0, idx)];
    }

    chunkSize.current = Math.max(1, base.length || 0);
    setSource(base);
    setData([...base, ...base]);
  }, [ids, startId, looksMap, getLooks]);

  const onEndReached = () => {
    if (!source.length) return;
    setData(d => [...d, ...source]);
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
    <View style={{ flex: 1, backgroundColor: '#000' }} onLayout={e => setSlideH(e.nativeEvent.layout.height)}>
      <FlatList
        ref={listRef}
        data={data}
        keyExtractor={(it, i) => `${it.id}-${i}`}
        renderItem={({ item }) => (
          <View style={{ height: slideH }}>
            <LookSlide look={item} />
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
