// scripts/migrate_to_productos.js
// Migración histórica de assets a assets/productos/{marca}/{producto}/{info.json,fotos/*}
const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();
const DIR_INFO = path.join(ROOT, 'assets', 'informacion');
const DIR_IMG = path.join(ROOT, 'assets', 'prendas');
const DIR_OUT = path.join(ROOT, 'assets', 'productos');

const exts = ['.jpg', '.jpeg', '.png', '.webp'];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function findImage(stem) {
  for (const ext of exts) {
    const p = path.join(DIR_IMG, `${stem}${ext}`);
    if (fs.existsSync(p)) return p;
  }
  // fallback: try case-insensitive match
  const files = fs.existsSync(DIR_IMG) ? fs.readdirSync(DIR_IMG) : [];
  const found = files.find(f => f.replace(/\.[^.]+$/, '').toLowerCase() === stem.toLowerCase());
  return found ? path.join(DIR_IMG, found) : null;
}

function main() {
  if (!fs.existsSync(DIR_INFO)) {
    console.error('No existe assets/informacion');
    process.exit(1);
  }
  ensureDir(DIR_OUT);

  const jsonFiles = fs.readdirSync(DIR_INFO).filter(f => f.toLowerCase().endsWith('.json'));
  let moved = 0;
  for (const f of jsonFiles) {
    const abs = path.join(DIR_INFO, f);
    const stem = f.replace(/\.json$/i, '');
    let brand = 'Desconocida';
    try {
      const data = JSON.parse(fs.readFileSync(abs, 'utf8'));
      if (data && typeof data.marca === 'string' && data.marca.trim()) brand = data.marca.trim();
    } catch {}

    const outDir = path.join(DIR_OUT, brand, stem);
    const fotosDir = path.join(outDir, 'fotos');
    ensureDir(fotosDir);

    // mover JSON -> info.json (si no existe ya)
    const dstInfo = path.join(outDir, 'info.json');
    if (!fs.existsSync(dstInfo)) {
      fs.renameSync(abs, dstInfo);
    } else {
      // ya migrado: borrar duplicado
      try { fs.unlinkSync(abs); } catch {}
    }

    // mover imagen si existe
    const img = findImage(stem);
    if (img) {
      const fileName = path.basename(img);
      const dstImg = path.join(fotosDir, fileName);
      if (!fs.existsSync(dstImg)) {
        fs.renameSync(img, dstImg);
      } else {
        try { fs.unlinkSync(img); } catch {}
      }
    }

    moved++;
  }

  // limpiar carpetas antiguas si quedan vacías
  try {
    const leftoverPrendas = fs.readdirSync(DIR_IMG).filter(n => !n.startsWith('.'));
    if (leftoverPrendas.length === 0) fs.rmdirSync(DIR_IMG);
  } catch {}
  try {
    const leftoverInfo = fs.readdirSync(DIR_INFO).filter(n => !n.startsWith('.'));
    if (leftoverInfo.length === 0) fs.rmdirSync(DIR_INFO);
  } catch {}

  console.log(`Migrados ${moved} productos a ${DIR_OUT}`);
}

main();
