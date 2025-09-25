// src/types/index.ts
export type Product = {
  id: string;
  brand: string;
  title: string;
  price: number;
  sizes: string[];
  images: string[];
  logo?: string | null;
  category?: string | null;
};

export type LookAuthor = { name: string; avatar: string };

export type Look = {
  id: string;
  title: string;
  author: LookAuthor;
  products: string[];
  cover_image: string;
};

export type User = {
  id: number;
  email: string;
  password_hash: string;
  name: string;
  handle: string;
  avatar_path?: string | null;
  age?: number | null;
  city?: string | null;
  sex?: string | null; // 'Mujer' | 'Hombre' | 'Otro'
};

export type Order = {
  id: string;
  productId: string;
  brand: string;
  title: string;
  size: string;
  status: string;
  date: string;
};
