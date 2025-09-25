import { Product } from "@/src/types";
import assetsIndex from "@/src/data/assetsIndex"; // generado por generateAssetsIndex.js
import productsInfo from "@/src/data/productsIndex"; // generado por generateProductsIndex.js

const imagesFor = (brand: string, stem: string): string[] => {
  const prefix = `productos/${brand}/${stem}/fotos/`;
  const keys = Object.keys(assetsIndex as any).filter((k) => k.startsWith(prefix));
  // orden estable por nombre de archivo
  keys.sort((a, b) => a.localeCompare(b));
  return keys.map((k) => (assetsIndex as any)[k]).filter(Boolean) as string[];
};

const logoFor = (brand: string): string | null => {
  const png = (assetsIndex as any)[`logos/${brand}.png`];
  const jpg = (assetsIndex as any)[`logos/${brand}.jpg`];
  const jpeg = (assetsIndex as any)[`logos/${brand}.jpeg`];
  return (png || jpg || jpeg || null) as string | null;
};

export async function loadProducts(): Promise<Record<string, Product>> {
  const map: Record<string, Product> = {};

  Object.entries(productsInfo).forEach(([stem, data]: [string, any]) => {
    const brand: string = data.marca || "";
    const title: string = data.nombre || stem;
    const price: number = Number(data.precio || 0);
    const sizes: string[] = Array.isArray(data.tallas) ? data.tallas : [];
    const category: string | null = data.categoria || null;

    const imgs = brand ? imagesFor(brand, stem) : [];
    const logo = brand ? logoFor(brand) : null;

    map[stem] = {
      id: stem,
      brand,
      title,
      price,
      sizes,
      images: imgs,
      logo,
      category,
    };
  });

  return map;
}
