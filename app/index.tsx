import { Redirect } from 'expo-router';
import { useStore } from '@/src/store';

export default function Index() {
  const currentUserId = useStore((s) => s.currentUserId);
  // Pathless group: '(tabs)' is not part of the URL. Use '/feed'.
  return <Redirect href={currentUserId ? '/feed' : '/login'} />;
}
