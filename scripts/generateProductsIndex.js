// scripts/generateProductsIndex.js
const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();
const SRC = path.join(ROOT, 'assets', 'productos');
const OUT = path.join(ROOT, 'src', 'data', 'productsIndex.ts');

function walk(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(p));
    else out.push(p);
  }
  return out;
}

function main() {
  if (!fs.existsSync(SRC)) {
    console.error(`No existe ${SRC}`);
    process.exit(1);
  }
  // Buscar todos los info.json dentro de productos/{marca}/{producto}/info.json
  const files = walk(SRC).filter(
    (p) => path.basename(p).toLowerCase() === 'info.json'
  );
  const entries = files.map((abs) => {
    const raw = fs.readFileSync(abs, 'utf8');
    const json = JSON.stringify(JSON.parse(raw));
    // stem = nombre de la carpeta del producto
    const stem = path.basename(path.dirname(abs));
    return `  ${JSON.stringify(stem)}: ${json},`;
  });

  const code = `// AUTO-GENERATED. Do not edit.
const productsInfo: Record<string, any> = {
${entries.join('\n')}
};
export default productsInfo;
`;
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, code, 'utf8');
  console.log(`Wrote ${OUT} with ${files.length} entries`);
}

main();
