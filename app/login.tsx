// app/login.tsx
import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Image,
  ActivityIndicator,
  Platform,
  KeyboardAvoidingView,
  ScrollView,
} from 'react-native';
import { router } from 'expo-router';
import { useStore } from '@/src/store';

export default function Login() {
  const { authenticateUser, createUser } = useStore();
  const [mode, setMode] = useState<'login'|'signup'>('login');
  const [email, setEmail] = useState('');
  const [pass, setPass] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  // UX extras
  const [focus, setFocus] = useState<{email?: boolean; pass?: boolean; name?: boolean}>({});
  const [showPass, setShowPass] = useState(false);

  const canSubmit = (() => {
    if (pending) return false;
    if (!email.trim() || !pass) return false;
    if (mode === 'signup' && !name.trim()) return false;
    return true;
  })();

  async function onSubmit() {
    setError(null);
    setPending(true);
    try {
      if (mode === 'login') {
        const uid = await authenticateUser(email.trim(), pass);
        if (!uid) {
          setError('Email o contraseña incorrectos.');
          setPending(false);
          return;
        }
      } else {
        const uid = await createUser({
          email: email.trim(),
          password: pass,
          name: name.trim() || undefined,
          handle: undefined,
          age: null,
          city: null,
          sex: null
        });
        if (uid < 0) {
          setError(uid === -2 ? 'Ese email ya existe. Prueba a iniciar sesión.' : 'No se pudo crear la cuenta.');
          setPending(false);
          return;
        }
      }
      // Deja que el index redirija según sesión
      router.replace('/');
    } catch {
      setError('Ha ocurrido un error inesperado.');
    } finally {
      setPending(false);
    }
  }

  return (
    <View style={s.screen}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
          <View style={s.card}>
            <View style={s.header}>
              <Image
                source={require('@/assets/logos/Ponsiv.png')}
                style={s.logo}
              />
              <Text style={s.title}>{mode === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}</Text>
              <Text style={s.subtitle}>
                {mode === 'login'
                  ? 'Accede para guardar tus looks y carrito.'
                  : 'Únete para empezar a crear y guardar looks.'}
              </Text>
            </View>

            {mode === 'signup' && (
              <View style={s.field}>
                <Text style={s.label}>Nombre</Text>
                <TextInput
                  value={name}
                  onChangeText={setName}
                  placeholder="Tu nombre"
                  style={[s.input, focus.name && s.inputFocus]}
                  onFocus={() => setFocus((f) => ({ ...f, name: true }))}
                  onBlur={() => setFocus((f) => ({ ...f, name: false }))}
                  autoCapitalize="words"
                  returnKeyType="next"
                />
              </View>
            )}

            <View style={s.field}>
              <Text style={s.label}>Email</Text>
              <TextInput
                value={email}
                onChangeText={setEmail}
                placeholder="mail@ejemplo.com"
                keyboardType="email-address"
                autoCapitalize="none"
                autoCorrect={false}
                textContentType="emailAddress"
                inputMode="email"
                style={[s.input, focus.email && s.inputFocus]}
                onFocus={() => setFocus((f) => ({ ...f, email: true }))}
                onBlur={() => setFocus((f) => ({ ...f, email: false }))}
                returnKeyType="next"
              />
            </View>

            <View style={s.field}>
              <Text style={s.label}>Contraseña</Text>
              <View style={s.passWrap}>
                <TextInput
                  value={pass}
                  onChangeText={setPass}
                  placeholder="********"
                  secureTextEntry={!showPass}
                  textContentType="password"
                  style={[s.input, s.inputWithAddon, focus.pass && s.inputFocus]}
                  onFocus={() => setFocus((f) => ({ ...f, pass: true }))}
                  onBlur={() => setFocus((f) => ({ ...f, pass: false }))}
                  returnKeyType="done"
                  onSubmitEditing={canSubmit ? onSubmit : undefined}
                />
                <TouchableOpacity
                  onPress={() => setShowPass((v) => !v)}
                  style={s.addon}
                  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                >
                  <Text style={s.addonTxt}>{showPass ? 'Ocultar' : 'Mostrar'}</Text>
                </TouchableOpacity>
              </View>
            </View>

            {error && (
              <View style={s.errorBox}>
                <Text style={s.errorTxt}>{error}</Text>
              </View>
            )}

            <TouchableOpacity onPress={onSubmit} disabled={!canSubmit} style={[s.btnPri, !canSubmit && s.btnDisabled]}>
              {pending ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={s.btnPriTxt}>{mode === 'login' ? 'Entrar' : 'Crear cuenta'}</Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => { setMode(mode === 'login' ? 'signup' : 'login'); setError(null); }}
              style={s.switch}
            >
              <Text style={s.switchTxt}>
                {mode === 'login' ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}
                <Text style={s.switchLink}>{mode === 'login' ? 'Regístrate' : 'Inicia sesión'}</Text>
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const s = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#F6F7F9',
  },
  scroll: {
    flexGrow: 1,
    padding: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  card: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 16,
    backgroundColor: '#fff',
    padding: 20,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOpacity: 0.08,
        shadowRadius: 16,
        shadowOffset: { width: 0, height: 8 },
      },
      android: { elevation: 4 },
      default: { boxShadow: '0 8px 24px rgba(0,0,0,0.08)' as any },
    }),
  },
  header: { alignItems: 'center', marginBottom: 8 },
  logo: { width: 700, height: 200, resizeMode: 'contain', marginBottom: 1, marginTop: -50 },
  title: { fontSize: 20, fontWeight: '700', marginBottom: 4, marginTop: -60  },
  subtitle: { fontSize: 13, color: 'rgba(0,0,0,0.6)', textAlign: 'center' },

  field: { marginTop: 12 },
  label: { fontSize: 12, color: 'rgba(0,0,0,0.65)', marginBottom: 6 },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.12)',
    borderRadius: 12,
    height: 48,
    paddingHorizontal: 12,
    fontSize: 16,
  },
  inputFocus: {
    borderColor: '#111',
  },
  passWrap: { position: 'relative' },
  inputWithAddon: { paddingRight: 84 },
  addon: {
    position: 'absolute',
    right: 8,
    top: 6,
    height: 36,
    paddingHorizontal: 10,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addonTxt: { fontSize: 13, fontWeight: '600', color: '#111' },

  errorBox: {
    backgroundColor: '#FDECEC',
    borderColor: '#F6B4B4',
    borderWidth: 1,
    padding: 10,
    borderRadius: 10,
    marginTop: 12,
  },
  errorTxt: { color: '#B00020' },

  btnPri: {
    height: 48,
    borderRadius: 12,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 16,
  },
  btnPriTxt: { color: '#fff', fontWeight: '700', fontSize: 16 },
  btnDisabled: { opacity: 0.6 },

  switch: { marginTop: 14, alignItems: 'center' },
  switchTxt: { color: 'rgba(0,0,0,0.75)' },
  switchLink: { color: '#111', fontWeight: '700' },
});
