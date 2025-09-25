import React, { useMemo, useRef } from 'react';
import { StyleProp, ViewStyle } from 'react-native';
import { Animated, StyleSheet, View } from 'react-native';

type HeaderRenderArgs = {
  // Animated interpolations; typed as any for compatibility across RN TS versions
  progress: any;
  height: any;
  opacity: any;
};

type Props = {
  headerHeight?: number;
  renderHeader: (args: HeaderRenderArgs) => React.ReactNode;
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  contentContainerStyle?: StyleProp<ViewStyle>;
  headerContainerStyle?: StyleProp<ViewStyle>;
  // Optional sticky bar under the header that stays pinned when scrolling
  stickyHeight?: number;
  renderSticky?: (args: HeaderRenderArgs) => React.ReactNode;
  stickyContainerStyle?: StyleProp<ViewStyle>;
};

/**
 * CollapsibleHeaderScrollView
 * - Renders an absolutely-positioned header that collapses from `headerHeight` to 0 as you scroll down.
 * - Content scrolls normally under it, with an initial top padding equal to the header height.
 * - On scroll up, the header smoothly reappears.
 *
 * Note: useNativeDriver=false because we animate height.
 */
export default function CollapsibleHeaderScrollView({
  headerHeight = 200,
  renderHeader,
  children,
  style,
  contentContainerStyle,
  headerContainerStyle,
  stickyHeight = 0,
  renderSticky,
  stickyContainerStyle,
}: Props) {
  const scrollY = useRef(new Animated.Value(0)).current;
  const clamped = useMemo(() => Animated.diffClamp(scrollY, 0, headerHeight), [scrollY, headerHeight]);

  const height = clamped.interpolate({
    inputRange: [0, headerHeight],
    outputRange: [headerHeight, 0],
    extrapolate: 'clamp',
  });

  const opacity = clamped.interpolate({
    inputRange: [0, headerHeight],
    outputRange: [1, 0],
    extrapolate: 'clamp',
  });

  const progress = clamped.interpolate({
    inputRange: [0, headerHeight],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  });

  return (
    <View style={[styles.container, style]}>
      <Animated.ScrollView
        style={{ flex: 1 }}
        // Evita el “rebote” que genera huecos en los extremos (iOS/Android)
        bounces={false}
        alwaysBounceVertical={false}
        overScrollMode="never"
        contentInsetAdjustmentBehavior="never"
        contentContainerStyle={[{ paddingTop: headerHeight + (stickyHeight || 0) }, contentContainerStyle]}
        scrollEventThrottle={16}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: false }
        )}
      >
        {children}
      </Animated.ScrollView>

      <Animated.View style={[styles.header, { height }, headerContainerStyle]}>
        {renderHeader({ progress, height, opacity })}
      </Animated.View>

      {!!stickyHeight && !!renderSticky && (
        <Animated.View
          style={[
            styles.sticky,
            { height: stickyHeight, transform: [{ translateY: height }] },
            stickyContainerStyle,
          ]}
        >
          {renderSticky({ progress, height, opacity })}
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  header: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: '#fff',
    overflow: 'hidden',
  },
  sticky: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 9,
    backgroundColor: '#fff',
  },
});
