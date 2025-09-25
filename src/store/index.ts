// src/store/index.ts
import { create } from "zustand";
import { Platform } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Crypto from "expo-crypto";
import { loadProducts } from "@/src/data/loadProducts";
import assetsIndex from "@/src/data/assetsIndex";
import type { Product, Look, Order, User } from "@/src/types";

// -------------------------
//  DETECCIÓN DE WEB vs NATIVO
// -------------------------
const isWeb = Platform.OS === "web";
const SQLite: any = isWeb ? null : require("expo-sqlite");

// --- DB nativa (Android/iOS). En web no se inicializa.
const db: any = isWeb
  ? null
  : (
      (SQLite.openDatabaseSync && SQLite.openDatabaseSync("ponsiv.db")) ||
      (SQLite.openDatabase && SQLite.openDatabase("ponsiv.db")) ||
      null
    );

// -------------------------
//  Tipos auxiliares para persistencia de LOOKS
// -------------------------
type LookRow = {
  id: string;
  title: string;
  author_name: string | null;
  author_avatar: string | null;
  cover_image: string;
  description: string | null;
  created_by: number | null;
  created_at: number; // epoch ms
};

// -------------------------
//  Helpers imágenes (persistencia/hidratación)
// -------------------------
function persistImage(val: any): string | null {
  if (val == null) return null;

  if (typeof val === "string") {
    if (val.startsWith("asset:")) return val;
    if ((assetsIndex as any)[val]) return `asset:${val}`;
    return val; // URI
  }

  const entry = Object.entries(assetsIndex as any).find(([, v]) => v === val);
  return entry ? `asset:${entry[0]}` : String(val);
}

function hydrateImage(persisted: string | null): any {
  if (!persisted) return null;

  if (persisted.startsWith("asset:")) {
    const key = persisted.slice(6);
    return (assetsIndex as any)[key] ?? null;
  }
  if ((assetsIndex as any)[persisted]) return (assetsIndex as any)[persisted];

  if (/^\d+$/.test(persisted)) {
    const entry = Object.entries(assetsIndex as any).find(
      ([, v]) => String(v) === persisted
    );
    if (entry) return entry[1];
  }
  return persisted; // URI
}

// -------------------------
//  BACKEND EN MEMORIA PARA WEB (persistente con AsyncStorage)
// -------------------------
type MemDB = {
  users: User[];
  likes: Array<{ user_id: number; product_id: string }>;
  wardrobe: Array<{ user_id: number; product_id: string }>;
  cart: Array<{ user_id: number; product_id: string; quantity: number }>;
  looks: LookRow[]; // ✅ persistimos looks también en web
  seq: number; // autoincrement para users.id
};

const MEM_KEY = "memdb:v1";
let mem: MemDB | null = null;

async function memLoad() {
  if (!isWeb) return;
  if (mem) return;
  try {
    const raw = await AsyncStorage.getItem(MEM_KEY);
    if (raw) mem = JSON.parse(raw) as any;
  } catch {}
  if (!mem || typeof mem !== 'object') {
    mem = { users: [], likes: [], wardrobe: [], cart: [], looks: [], seq: 0 };
  }
  // 🔧 Migración/saneo de estructuras antiguas
  mem.users    = Array.isArray(mem.users)    ? mem.users    : [];
  mem.likes    = Array.isArray(mem.likes)    ? mem.likes    : [];
  mem.wardrobe = Array.isArray(mem.wardrobe) ? mem.wardrobe : [];
  mem.cart     = Array.isArray(mem.cart)     ? mem.cart     : [];
  mem.looks    = Array.isArray(mem.looks)    ? mem.looks    : []; // 👈 clave
  mem.seq = Number.isFinite(mem.seq)
    ? mem.seq
    : mem.users.reduce((m: number, u: any) => Math.max(m, Number(u?.id) || 0), 0);
}

async function memSave() {
  if (!isWeb || !mem) return;
  try {
    await AsyncStorage.setItem(MEM_KEY, JSON.stringify(mem));
  } catch {}
}

// -------------------------
//  HELPERS SQL <-> WEB MOCK
// -------------------------
async function dbRun(sql: string, params: any[] = []): Promise<void> {
  if (!isWeb) {
    if (db?.runAsync) {
      await db.runAsync(sql, params as any);
      return;
    }
    return new Promise((resolve, reject) => {
      db.transaction((tx: any) => {
        tx.executeSql(
          sql,
          params,
          () => resolve(),
          (_: any, err: any) => {
            reject(err);
            return false;
          }
        );
      });
    });
  }

  await memLoad();

  // CREATE TABLE ... -> ignorar en web
  if (/^\s*CREATE\s+TABLE/i.test(sql)) return;

  // INSERT user
  if (/^\s*INSERT\s+INTO\s+users\b/i.test(sql)) {
    const [email, password_hash, name, handle, age, city, sex] = params;
    if (mem!.users.find((u) => u.email === email)) return; // UNIQUE(email)
    const id = ++mem!.seq;
    const user: User = {
      id,
      email,
      password_hash,
      name,
      handle,
      avatar_path: null,
      age: age ?? null,
      city: city ?? null,
      sex: sex ?? null,
    } as User;
    mem!.users.push(user);
    await memSave();
    return;
  }
  
  // LOOKS: UPDATE (fixed column order)
  if (/^\s*UPDATE\s+looks\s+SET\s+title=\?,\s*author_name=\?,\s*author_avatar=\?,\s*cover_image=\?,\s*description=\?\s+WHERE\s+id=\?/i.test(sql)) {
    const [title, author_name, author_avatar, cover_image, description, id] = params;
    if (!Array.isArray(mem!.looks)) mem!.looks = [];
    const idx = mem!.looks.findIndex((l) => l.id === String(id));
    if (idx >= 0) {
      const prev = mem!.looks[idx];
      mem!.looks[idx] = {
        ...prev,
        id: String(id),
        title: String(title),
        author_name: author_name != null ? String(author_name) : prev.author_name,
        author_avatar: persistImage(author_avatar ?? prev.author_avatar),
        cover_image: (persistImage(cover_image ?? prev.cover_image) as any),
        description: description != null ? String(description) : prev.description,
      } as LookRow;
      await memSave();
    }
    return;
  }

  // LOOKS: DELETE
  if (/^\s*DELETE\s+FROM\s+looks\s+WHERE\s+id=\?/i.test(sql)) {
    const [id] = params;
    mem!.looks = (Array.isArray(mem!.looks) ? mem!.looks : []).filter((r) => r.id !== String(id));
    await memSave();
    return;
  }

  // UPDATE users SET avatar_path=? WHERE id=?
  if (/^\s*UPDATE\s+users\s+SET\s+avatar_path=/i.test(sql)) {
    const [path, id] = params;
    const u = mem!.users.find((u) => u.id === Number(id));
    if (u) {
      u.avatar_path = path;
      await memSave();
    }
    return;
  }

  // LIKES
  if (/^\s*INSERT\s+OR\s+IGNORE\s+INTO\s+likes\b/i.test(sql)) {
    const [user_id, product_id] = params;
    if (
      !mem!.likes.find(
        (r) => r.user_id === Number(user_id) && r.product_id === String(product_id)
      )
    ) {
      mem!.likes.push({ user_id: Number(user_id), product_id: String(product_id) });
      await memSave();
    }
    return;
  }
  if (/^\s*DELETE\s+FROM\s+likes\b/i.test(sql)) {
    const [user_id, product_id] = params;
    mem!.likes = mem!.likes.filter(
      (r) => !(r.user_id === Number(user_id) && r.product_id === String(product_id))
    );
    await memSave();
    return;
  }

  // WARDROBE
  if (/^\s*INSERT\s+OR\s+IGNORE\s+INTO\s+wardrobe\b/i.test(sql)) {
    const [user_id, product_id] = params;
    if (
      !mem!.wardrobe.find(
        (r) => r.user_id === Number(user_id) && r.product_id === String(product_id)
      )
    ) {
      mem!.wardrobe.push({
        user_id: Number(user_id),
        product_id: String(product_id),
      });
      await memSave();
    }
    return;
  }
  if (/^\s*DELETE\s+FROM\s+wardrobe\b/i.test(sql)) {
    const [user_id, product_id] = params;
    mem!.wardrobe = mem!.wardrobe.filter(
      (r) => !(r.user_id === Number(user_id) && r.product_id === String(product_id))
    );
    await memSave();
    return;
  }

  // CART upsert
  if (/^\s*INSERT\s+INTO\s+cart\b/i.test(sql) && /ON\s+CONFLICT/i.test(sql)) {
    const [user_id, product_id, quantity] = params;
    const row = mem!.cart.find(
      (r) => r.user_id === Number(user_id) && r.product_id === String(product_id)
    );
    if (row) row.quantity = Number(quantity);
    else
      mem!.cart.push({
        user_id: Number(user_id),
        product_id: String(product_id),
        quantity: Number(quantity),
      });
    await memSave();
    return;
  }

  if (/^\s*UPDATE\s+cart\s+SET\s+quantity=/i.test(sql)) {
    const [quantity, user_id, product_id] = params;
    const row = mem!.cart.find(
      (r) => r.user_id === Number(user_id) && r.product_id === String(product_id)
    );
    if (row) row.quantity = Number(quantity);
    await memSave();
    return;
  }

  if (/^\s*DELETE\s+FROM\s+cart\b/i.test(sql)) {
    if (params.length === 2) {
      const [user_id, product_id] = params;
      mem!.cart = mem!.cart.filter(
        (r) => !(r.user_id === Number(user_id) && r.product_id === String(product_id))
      );
    } else if (params.length === 1) {
      const [user_id] = params;
      mem!.cart = mem!.cart.filter((r) => r.user_id !== Number(user_id));
    }
    await memSave();
    return;
  }

  // LOOKS: INSERT / UPSERT (INSERT INTO / INSERT OR REPLACE INTO)
  if (/^\s*INSERT\s+(?:OR\s+REPLACE\s+)?INTO\s+looks\b/i.test(sql)) {
    const [
      id,
      title,
      author_name,
      author_avatar,
      cover_image,
      description,
      created_by,
      created_at,
    ] = params;
    if (!Array.isArray(mem!.looks)) mem!.looks = [];
    
    const row: LookRow = {
      id: String(id),
      title: String(title),
      author_name: author_name ? String(author_name) : null,
      author_avatar: persistImage(author_avatar),           // ⬅️ persist
      cover_image: (persistImage(cover_image) as any),      // ⬅️ persist
      description: description ? String(description) : null,
      created_by: created_by != null ? Number(created_by) : null,
      created_at: Number(created_at),
    };
    const existsIdx = mem!.looks.findIndex((l) => l.id === row.id);
    if (existsIdx >= 0) mem!.looks[existsIdx] = row;
    else mem!.looks.push(row);
    await memSave();
    return;
  }
}

async function dbAll<T = any>(sql: string, params: any[] = []): Promise<T[]> {
  if (!isWeb) {
    if (db?.getAllAsync) {
      const rows = await db.getAllAsync<T>(sql, params as any);
      return rows || [];
    }
    return new Promise((resolve, reject) => {
      db.readTransaction((tx: any) => {
        tx.executeSql(
          sql,
          params,
          (_: any, { rows }: any) => resolve(rows._array as T[]),
          (_: any, err: any) => {
            reject(err);
            return false;
          }
        );
      });
    });
  }

  await memLoad();

  // SELECT product_id FROM likes WHERE user_id=?
  if (/^\s*SELECT\s+product_id\s+FROM\s+likes\s+WHERE\s+user_id=\?/i.test(sql)) {
    const [uid] = params;
    const rows = mem!.likes
      .filter((r) => r.user_id === Number(uid))
      .map((r) => ({ product_id: r.product_id })) as any[];
    return rows as T[];
  }

  // SELECT 1 AS x FROM likes WHERE user_id=? AND product_id=?
  if (
    /^\s*SELECT\s+1\s+AS\s+x\s+FROM\s+likes\s+WHERE\s+user_id=\?\s+AND\s+product_id=\?/i.test(
      sql
    )
  ) {
    const [uid, pid] = params;
    const ok = mem!.likes.some(
      (r) => r.user_id === Number(uid) && r.product_id === String(pid)
    );
    return ok ? ([{ x: 1 }] as any) : [];
  }

  // SELECT product_id FROM wardrobe WHERE user_id=?
  if (
    /^\s*SELECT\s+product_id\s+FROM\s+wardrobe\s+WHERE\s+user_id=\?/i.test(sql)
  ) {
    const [uid] = params;
    const rows = mem!.wardrobe
      .filter((r) => r.user_id === Number(uid))
      .map((r) => ({ product_id: r.product_id })) as any[];
    return rows as T[];
  }

  // SELECT 1 AS x FROM wardrobe WHERE user_id=? AND product_id=?
  if (
    /^\s*SELECT\s+1\s+AS\s+x\s+FROM\s+wardrobe\s+WHERE\s+user_id=\?\s+AND\s+product_id=\?/i.test(
      sql
    )
  ) {
    const [uid, pid] = params;
    const ok = mem!.wardrobe.some(
      (r) => r.user_id === Number(uid) && r.product_id === String(pid)
    );
    return ok ? ([{ x: 1 }] as any) : [];
  }

  // SELECT product_id, quantity FROM cart WHERE user_id=?
  if (
    /^\s*SELECT\s+product_id,\s*quantity\s+FROM\s+cart\s+WHERE\s+user_id=\?/i.test(
      sql
    )
  ) {
    const [uid] = params;
    const rows = mem!.cart
      .filter((r) => r.user_id === Number(uid))
      .map((r) => ({ product_id: r.product_id, quantity: r.quantity })) as any[];
    return rows as T[];
  }

  // SELECT product_id, COUNT(*) AS c FROM likes GROUP BY product_id
  if (
    /^\s*SELECT\s+product_id,\s*COUNT\(\*\)\s+AS\s+c\s+FROM\s+likes\s+GROUP\s+BY\s+product_id/i.test(
      sql
    )
  ) {
    const map = new Map<string, number>();
    mem!.likes.forEach((r) =>
      map.set(r.product_id, (map.get(r.product_id) || 0) + 1)
    );
    const rows = Array.from(map.entries()).map(([product_id, c]) => ({
      product_id,
      c,
    })) as any[];
    return rows as T[];
  }

  // SELECT ... FROM users ...
  if (/^\s*SELECT\s+\*\s+FROM\s+users\s+WHERE\s+id=\?/i.test(sql)) {
    const [id] = params;
    const u = mem!.users.find((u) => u.id === Number(id));
    return u ? ([u as any] as T[]) : [];
  }
  if (/^\s*SELECT\s+\*\s+FROM\s+users\s+WHERE\s+email=\?/i.test(sql)) {
    const [email] = params;
    const u = mem!.users.find((u) => u.email === String(email));
    return u ? ([u as any] as T[]) : [];
  }
  if (/^\s*SELECT\s+\*\s+FROM\s+users\s+WHERE\s+handle=\?/i.test(sql)) {
    const [handle] = params;
    const u = mem!.users.find((u) => u.handle === String(handle));
    return u ? ([u as any] as T[]) : [];
  }
  if (
    /^\s*SELECT\s+id,\s*password_hash\s+FROM\s+users\s+WHERE\s+email=\?/i.test(sql)
  ) {
    const [email] = params;
    const u = mem!.users.find((u) => u.email === String(email));
    return u ? ([{ id: u.id, password_hash: u.password_hash } as any] as T[]) : [];
  }

  // SELECT looks (ordenación por fecha desc)
  if (
    /^\s*SELECT\s+id,\s*title,\s*author_name,\s*author_avatar,\s*cover_image,\s*description,\s*created_by,\s*created_at\s+FROM\s+looks/i.test(
      sql
    )
  ) {
    // ✅ Asegura el array antes de iterar
    const arr = Array.isArray(mem!.looks) ? mem!.looks : [];
    const rows = [...arr].sort((a, b) => b.created_at - a.created_at);
    return rows as any;
  }

  return [];
}

function dbGet<T = any>(sql: string, params: any[] = []): Promise<T | undefined> {
  return dbAll<T>(sql, params).then((rows) => rows[0]);
}

async function sha256(s: string) {
  return Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, s);
}

async function ensureSchema() {
  if (isWeb) {
    await memLoad();
    return;
  }
  await dbRun(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    handle TEXT,
    avatar_path TEXT,
    age INTEGER, city TEXT, sex TEXT
  )`);
  await dbRun(
    `CREATE TABLE IF NOT EXISTS likes (user_id INTEGER NOT NULL, product_id TEXT NOT NULL, UNIQUE(user_id, product_id))`
  );
  await dbRun(
    `CREATE TABLE IF NOT EXISTS wardrobe (user_id INTEGER NOT NULL, product_id TEXT NOT NULL, UNIQUE(user_id, product_id))`
  );
  await dbRun(
    `CREATE TABLE IF NOT EXISTS cart (user_id INTEGER NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, UNIQUE(user_id, product_id))`
  );
  // ✅ tabla LOOKS global (visible para todos los usuarios)
  await dbRun(
    `CREATE TABLE IF NOT EXISTS looks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      author_name TEXT,
      author_avatar TEXT,
      cover_image TEXT NOT NULL,
      description TEXT,
      created_by INTEGER,
      created_at INTEGER NOT NULL
    )`
  );
}

// -------------------------
//  STORE
// -------------------------
type State = {
  products: Record<string, Product>;
  looks: Record<string, Look>;
  orders: Order[];
  cart: Record<string, number>;
  currentUserId: number | null;
  ready: boolean;

  // init
  bootstrap: () => Promise<void>;

  // auth
  createUser: (p: {
    email: string;
    password: string;
    name?: string;
    handle?: string;
    age?: number | null;
    city?: string | null;
    sex?: string | null;
  }) => Promise<number>;
  authenticateUser: (email: string, password: string) => Promise<number | null>;
  logout: () => Promise<void>;
  getUser: (id: number) => Promise<User | undefined>;
  getUserByEmail: (email: string) => Promise<User | undefined>;
  getUserByHandle: (handle: string) => Promise<User | undefined>;
  updateUserAvatar: (id: number, path: string) => Promise<void>;

  // likes / wardrobe
  isProductLiked: (uid: number, pid: string) => Promise<boolean>;
  toggleLike: (uid: number, pid: string) => Promise<boolean>;
  getLikedProductIds: (uid: number) => Promise<string[]>;
  isInWardrobe: (uid: number, pid: string) => Promise<boolean>;
  toggleWardrobe: (uid: number, pid: string) => Promise<boolean>;
  getWardrobeIds: (uid: number) => Promise<string[]>;

  // cart
  loadCart: (uid?: number | null) => Promise<void>;
  addToCart: (pid: string, qty?: number) => Promise<void>;
  removeOneFromCart: (pid: string) => Promise<void>;
  removeLineFromCart: (pid: string) => Promise<void>;
  clearCart: () => Promise<void>;
  getCartItems: () => Array<{ product: Product; qty: number }>;
  getCartTotal: () => number;
  placeOrder: () => Promise<void>;

  // trending / categories
  getAllLikeCounts: () => Promise<Record<string, number>>;
  sortProductsByLikes: (arr: Product[]) => Promise<Product[]>;

  // looks
  addLook: (
    title: string,
    authorName: string,
    cover_image: string,
    products?: string[],
    authorAvatar?: string,
    description?: string
  ) => Promise<string>;
  loadLooksFromDB: () => Promise<void>;
  purgeLegacyLooks: () => Promise<void>;
  getLooks: () => Look[];
  searchLooks: (q: string) => Look[];
  updateLook: (
    id: string,
    changes: {
      title?: string;
      cover_image?: string;
      description?: string | null;
      authorName?: string | null;
      authorAvatar?: string | null;
    }
  ) => Promise<void>;
  deleteLook: (id: string) => Promise<void>;
};

export const useStore = create<State>((set, getState) => ({
  products: {},
  looks: {},
  orders: [],
  cart: {},
  currentUserId: null,
  ready: false,

  bootstrap: async () => {
    await ensureSchema();
    const products = await loadProducts();

    let savedUid: number | null = null;
    try {
      const raw = await AsyncStorage.getItem("session:uid");
      if (raw) savedUid = Number(raw) || null;
    } catch {}

    set({ products, currentUserId: savedUid, ready: true });
    await getState().loadCart(savedUid || undefined);

    // ✅ cargar looks persistidos
    await getState().purgeLegacyLooks();
    await getState().loadLooksFromDB();
    // ✅ si no hay, sembramos ejemplos de forma persistente
    // looks seed deshabilitado: solo looks de usuarios
  },

  // AUTH
  createUser: async ({ email, password, name, handle, age, city, sex }) => {
    const exists = await dbGet<User>(`SELECT * FROM users WHERE email=?`, [email]);
    if (exists) return -2; // email ya usado

    const pw = await sha256(password);
    const nm = name || email.split("@")[0];
    const hd = handle || nm;

    await dbRun(
      `INSERT INTO users (email, password_hash, name, handle, age, city, sex) VALUES (?,?,?,?,?,?,?)`,
      [email, pw, nm, hd, age ?? null, city ?? null, sex ?? null]
    );

    const u = await dbGet<User>(`SELECT * FROM users WHERE email=?`, [email]);
    set({ currentUserId: u?.id ?? null });
    await AsyncStorage.setItem("session:uid", String(u?.id ?? ""));
    await getState().loadCart(u?.id ?? null);
    return u?.id ?? -1;
  },

  authenticateUser: async (email, password) => {
    const u = await dbGet<{ id: number; password_hash: string }>(
      `SELECT id, password_hash FROM users WHERE email=?`,
      [email]
    );
    if (!u) return null;

    const pw = await sha256(password);
    if (pw === (u as any).password_hash) {
      set({ currentUserId: (u as any).id });
      await AsyncStorage.setItem("session:uid", String((u as any).id));
      await getState().loadCart((u as any).id);
      return (u as any).id;
    }
    return null;
  },

  logout: async () => {
    await AsyncStorage.removeItem("session:uid");
    set({ currentUserId: null, cart: {} });
  },

  getUser: async (id) => dbGet<User>(`SELECT * FROM users WHERE id=?`, [id]),
  getUserByEmail: async (email) =>
    dbGet<User>(`SELECT * FROM users WHERE email=?`, [email]),
  getUserByHandle: async (handle) =>
    dbGet<User>(`SELECT * FROM users WHERE handle=?`, [handle]),
  updateUserAvatar: async (id, path) =>
    dbRun(`UPDATE users SET avatar_path=? WHERE id=?`, [path, id]),

  // LIKES / WARDROBE
  isProductLiked: async (uid, pid) =>
    !!(await dbGet(`SELECT 1 AS x FROM likes WHERE user_id=? AND product_id=?`, [
      uid,
      pid,
    ])),
  toggleLike: async (uid, pid) => {
    const liked = await getState().isProductLiked(uid, pid);
    if (liked) {
      await dbRun(`DELETE FROM likes WHERE user_id=? AND product_id=?`, [uid, pid]);
    } else {
      await dbRun(`INSERT OR IGNORE INTO likes (user_id, product_id) VALUES (?,?)`, [
        uid,
        pid,
      ]);
    }
    return !liked;
  },
  getLikedProductIds: async (uid) =>
    (
      await dbAll<{ product_id: string }>(
        `SELECT product_id FROM likes WHERE user_id=?`,
        [uid]
      )
    ).map((r) => r.product_id),

  isInWardrobe: async (uid, pid) =>
    !!(
      await dbGet(
        `SELECT 1 AS x FROM wardrobe WHERE user_id=? AND product_id=?`,
        [uid, pid]
      )
    ),
  toggleWardrobe: async (uid, pid) => {
    const has = await getState().isInWardrobe(uid, pid);
    if (has) {
      await dbRun(`DELETE FROM wardrobe WHERE user_id=? AND product_id=?`, [
        uid,
        pid,
      ]);
    } else {
      await dbRun(
        `INSERT OR IGNORE INTO wardrobe (user_id, product_id) VALUES (?,?)`,
        [uid, pid]
      );
    }
    return !has;
  },
  getWardrobeIds: async (uid) =>
    (
      await dbAll<{ product_id: string }>(
        `SELECT product_id FROM wardrobe WHERE user_id=?`,
        [uid]
      )
    ).map((r) => r.product_id),

  // CART
  loadCart: async (uid = getState().currentUserId) => {
    set({ cart: {} });
    if (!uid) return;
    const rows = await dbAll<{ product_id: string; quantity: number }>(
      `SELECT product_id, quantity FROM cart WHERE user_id=?`,
      [uid]
    );
    const cart: Record<string, number> = {};
    rows.forEach((r) => {
      cart[r.product_id] = r.quantity;
    });
    set({ cart });
  },
  addToCart: async (pid, qty = 1) => {
    const { cart, currentUserId } = getState();
    const newQty = (cart[pid] || 0) + qty;
    cart[pid] = newQty;
    set({ cart: { ...cart } });
    if (currentUserId) {
      await dbRun(
        `INSERT INTO cart (user_id, product_id, quantity) VALUES (?,?,?) ON CONFLICT(user_id, product_id) DO UPDATE SET quantity=excluded.quantity`,
        [currentUserId, pid, newQty]
      );
    }
  },
  removeOneFromCart: async (pid) => {
    const { cart, currentUserId } = getState();
    const newQty = Math.max(0, (cart[pid] || 0) - 1);
    if (newQty === 0) delete cart[pid];
    else cart[pid] = newQty;
    set({ cart: { ...cart } });
    if (currentUserId) {
      if (newQty > 0)
        await dbRun(
          `UPDATE cart SET quantity=? WHERE user_id=? AND product_id=?`,
          [newQty, currentUserId, pid]
        );
      else
        await dbRun(`DELETE FROM cart WHERE user_id=? AND product_id=?`, [
          currentUserId,
          pid,
        ]);
    }
  },
  removeLineFromCart: async (pid) => {
    const { cart, currentUserId } = getState();
    delete cart[pid];
    set({ cart: { ...cart } });
    if (currentUserId)
      await dbRun(`DELETE FROM cart WHERE user_id=? AND product_id=?`, [
        currentUserId,
        pid,
      ]);
  },
  clearCart: async () => {
    const { currentUserId } = getState();
    set({ cart: {} });
    if (currentUserId)
      await dbRun(`DELETE FROM cart WHERE user_id=?`, [currentUserId]);
  },
  getCartItems: () => {
    const { cart, products } = getState();
    return Object.entries(cart)
      .filter(([pid, q]) => products[pid] && (q as number) > 0)
      .map(([pid, q]) => ({ product: products[pid], qty: q as number }));
  },
  getCartTotal: () =>
    getState()
      .getCartItems()
      .reduce((s, it) => s + it.product.price * it.qty, 0),

  // PLACE ORDER: convierte el carrito en pedidos visibles en el perfil
  placeOrder: async () => {
    const items = getState().getCartItems();
    const now = new Date();
    const date = now.toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });
    const orders = items.map((it, idx) => ({
      id: `ord_${now.getTime()}_${idx}`,
      productId: it.product.id,
      brand: it.product.brand,
      title: it.product.title,
      size: (it.product.sizes && it.product.sizes[0]) || 'M',
      status: 'En reparto',
      date,
    }));
    // Reemplaza pedidos anteriores por los nuevos (según petición)
    set({ orders });
    await getState().clearCart();
  },

  // TRENDING
  getAllLikeCounts: async () => {
    const rows = await dbAll<{ product_id: string; c: number }>(
      `SELECT product_id, COUNT(*) AS c FROM likes GROUP BY product_id`
    );
    const out: Record<string, number> = {};
    rows.forEach((r) => (out[r.product_id] = Number(r.c || 0)));
    return out;
  },
  sortProductsByLikes: async (arr) => {
    const counts = await getState().getAllLikeCounts();
    return [...arr].sort((a, b) => {
      const ca = counts[a.id] || 0,
        cb = counts[b.id] || 0;
      if (cb !== ca) return cb - ca;
      return (a.title || "").localeCompare(b.title || "");
    });
  },

  // LOOKS (persistentes, globales)
  addLook: async (
    title,
    authorName,
    cover_image,
    products = [],
    authorAvatar,
    description
  ) => {
    // Genera id simple con conteo actual (suficiente para local). Si quieres 100% único, usa Crypto.randomUUID()
    const seq = Object.keys(getState().looks).length + 1;
    const lookId = `look_${String(seq).padStart(6, "0")}`;
    const created_at = Date.now();
    const created_by = getState().currentUserId ?? null;

    // ⬇️ persistimos claves/URIs para BD
    const persistedCover = persistImage(cover_image);
    const persistedAvatar = persistImage(authorAvatar);

    // Inserta en BD (global)
    await dbRun(
      `INSERT INTO looks (id, title, author_name, author_avatar, cover_image, description, created_by, created_at) VALUES (?,?,?,?,?,?,?,?)`,
      [
        lookId,
        title,
        authorName || null,
        persistedAvatar,
        persistedCover,
        description || null,
        created_by,
        created_at,
      ]
    );

    // Actualiza memoria (en caliente seguimos usando los valores originales)
    const look: Look = {
      id: lookId,
      title,
      author: {
        name: authorName,
        avatar: authorAvatar || (assetsIndex as any)["logos/Ponsiv.png"] || "",
      },
      products,
      cover_image,
      ...(description ? { description } : {}),
    } as any;

    set((state) => ({ looks: { ...state.looks, [look.id]: look } }));
    return look.id;
  },

  loadLooksFromDB: async () => {
    const rows = await dbAll<LookRow>(
      `SELECT id, title, author_name, author_avatar, cover_image, description, created_by, created_at FROM looks ORDER BY created_at DESC`
    );
    const map: Record<string, Look> = {};
    rows.forEach((r) => {
      const hydratedCover = hydrateImage(r.cover_image);
      // Filtra looks antiguos que referencian la ruta eliminada "assets/prendas"
      const legacyPrendas =
        (typeof r.cover_image === "string" && r.cover_image.includes("prendas")) ||
        (typeof hydratedCover === "string" && hydratedCover.includes("prendas"));
      if (legacyPrendas) return; // omitimos del estado para que no se intenten cargar

      map[r.id] = {
        id: r.id,
        title: r.title,
        author: {
          name: r.author_name || "Usuario",
          avatar:
            hydrateImage(r.author_avatar) ||
            (assetsIndex as any)["logos/Ponsiv.png"] ||
            "",
        },
        products: [],
        cover_image: hydratedCover,
        ...(r.description ? { description: r.description } : {}),
      } as any;
    });
    set({ looks: map });
  },

  // Borra de la BD (y del backend en memoria web) los looks con cover en la ruta antigua 'prendas'
  purgeLegacyLooks: async () => {
    try {
      // SQLite
      await dbRun(`DELETE FROM looks WHERE cover_image LIKE ?`, ["%prendas%"]);
    } catch {}
    // Web (memoria + AsyncStorage)
    try {
      await memLoad();
      if (mem) {
        mem.looks = (Array.isArray(mem.looks) ? mem.looks : []).filter(
          (r: any) => !(typeof r?.cover_image === 'string' && r.cover_image.includes('prendas'))
        );
        await memSave();
      }
    } catch {}
  },

  getLooks: () => Object.values(getState().looks).reverse(),
  searchLooks: (q) => {
    const Q = (q || "").toLowerCase();
    return getState()
      .getLooks()
      .filter(
        (lk) =>
          lk.title.toLowerCase().includes(Q) ||
          (lk.author?.name || "").toLowerCase().includes(Q)
      );
  },
  // Editar look (titulo/portada/descripcion/autor)
  updateLook: async (
    id,
    changes: {
      title?: string;
      cover_image?: string;
      description?: string | null;
      authorName?: string | null;
      authorAvatar?: string | null;
    }
  ) => {
    const prev = getState().looks[id];
    if (!prev) return;
    const next = {
      ...prev,
      title: changes.title ?? prev.title,
      cover_image: changes.cover_image ?? prev.cover_image,
      author: {
        name: changes.authorName ?? prev.author?.name ?? 'Usuario',
        avatar: changes.authorAvatar ?? prev.author?.avatar ?? '',
      },
      ...(changes.description != null ? { description: changes.description } : {}),
    } as any;

    // Persistencia: UPDATE fijo (mem web tiene rama espec�fica)
    const persistedCover = persistImage(next.cover_image);
    const persistedAvatar = persistImage(next.author?.avatar);
    await dbRun(
      `UPDATE looks SET title=?, author_name=?, author_avatar=?, cover_image=?, description=? WHERE id=?`,
      [
        next.title,
        next.author?.name || null,
        persistedAvatar,
        persistedCover,
        (next as any).description ?? null,
        id,
      ]
    );

    set((state) => ({ looks: { ...state.looks, [id]: next } }));
  },
  // Eliminar look por id
  deleteLook: async (id) => {
    await dbRun(`DELETE FROM looks WHERE id=?`, [id]);
    set((state) => {
      const { [id]: _omit, ...rest } = state.looks;
      return { looks: rest } as any;
    });
  },
}));
