import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

export const haptics = {
  select: () => { if (Platform.OS !== 'web') { try { Haptics.selectionAsync(); } catch {} } },
  success: () => { if (Platform.OS !== 'web') { try { Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success); } catch {} } },
};
