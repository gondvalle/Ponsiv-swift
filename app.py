import json
import re
import subprocess
import unicodedata
from pathlib import Path
from typing import List, Tuple, Optional, Any

import streamlit as st


# =======================
#   Rutas base
# =======================
ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
LOGOS_DIR = ASSETS / "logos"
PRODUCTOS_DIR = ASSETS / "productos"


# =======================
#   Utilidades
# =======================
def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def list_brands() -> List[str]:
    """Devuelve el listado de marcas detectadas.
    Se unifica lo que haya en assets/logos y assets/productos.
    """
    brands: set[str] = set()
    # De logos (nombres de archivo sin extensión)
    if LOGOS_DIR.exists():
        for f in LOGOS_DIR.iterdir():
            if f.is_file() and f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
                brands.add(f.stem)
    # De productos (carpetas inmediatas)
    if PRODUCTOS_DIR.exists():
        for d in PRODUCTOS_DIR.iterdir():
            if d.is_dir():
                brands.add(d.name)
    return sorted(brands)


def slugify_for_stem(name: str) -> str:
    """Convierte un nombre a STEM de carpeta estable (MAYÚSCULAS_CON_GUIONES_BAJOS)."""
    # Normalizar tildes
    name_norm = unicodedata.normalize("NFKD", name)
    name_norm = "".join(c for c in name_norm if not unicodedata.combining(c))
    # Quitar caracteres no alfanum/espacio
    name_norm = re.sub(r"[^A-Za-z0-9\s_-]+", "", name_norm)
    # Espacios y guiones -> guion bajo
    name_norm = re.sub(r"[\s-]+", "_", name_norm)
    return name_norm.upper().strip("_") or "PRODUCTO"


def sanitize_base(filename: str, fallback: str) -> str:
    """Sanitiza el 'stem' del archivo; si queda vacío, usa fallback."""
    base = Path(filename).stem
    base = re.sub(r"[^A-Za-z0-9_-]+", "", base)
    return base or fallback


def read_product_info(info_path: Path) -> dict:
    if not info_path.exists():
        return {}
    try:
        with open(info_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def list_products_of_brand(brand: str) -> List[dict]:
    """Lista productos de una marca con sus paths e info."""
    brand_dir = PRODUCTOS_DIR / brand
    if not brand_dir.exists():
        return []

    products: List[dict] = []
    for prod_dir in sorted([p for p in brand_dir.iterdir() if p.is_dir()]):
        info = read_product_info(prod_dir / "info.json")
        fotos_dir = prod_dir / "fotos"
        fotos = sorted([p for p in fotos_dir.glob("*.jpg")]) if fotos_dir.exists() else []
        products.append(
            {
                "brand": brand,
                "stem": prod_dir.name,
                "dir": prod_dir,
                "info": info,
                "fotos": fotos,
            }
        )
    return products


def delete_photo(photo_path: Path) -> None:
    if photo_path.is_file() and photo_path.suffix.lower() == ".jpg":
        photo_path.unlink(missing_ok=True)


def delete_product_dir(prod_dir: Path) -> None:
    # Seguridad: solo borrar si está dentro de PRODUCTOS_DIR
    try:
        prod_dir.resolve().relative_to(PRODUCTOS_DIR.resolve())
    except Exception:
        raise ValueError("Ruta de producto fuera de assets/productos")
    import shutil
    shutil.rmtree(prod_dir, ignore_errors=True)


def set_solo_photo(fotos: List[Path], chosen: Optional[Path]) -> None:
    """Quita '_solo' del resto y lo añade a chosen (si no es None)."""
    for p in fotos:
        if "_solo" in p.stem:
            new_name = p.stem.replace("_solo", "") + p.suffix
            p.rename(p.with_name(new_name))

    if chosen is not None:
        if "_solo" not in chosen.stem:
            chosen.rename(chosen.with_name(chosen.stem + "_solo" + chosen.suffix))


def next_index_for_photos(fotos: List[Path]) -> int:
    """Devuelve el siguiente índice entero para nombres 'NN_...'."""
    max_idx = 0
    for p in fotos:
        m = re.match(r"^(\d+)_", p.name)
        if m:
            try:
                val = int(m.group(1))
                max_idx = max(max_idx, val)
            except Exception:
                pass
    return max_idx + 1


def save_new_photos(fotos_dir: Path, stem: str, uploaded_files: List[Any]) -> List[Path]:
    """Guarda nuevas fotos como .jpg (sin conversión de contenido), asignando índices consecutivos."""
    ensure_dir(fotos_dir)
    existing = sorted([p for p in fotos_dir.glob("*.jpg")])
    idx = next_index_for_photos(existing)
    saved_paths: List[Path] = []

    for uf in uploaded_files:
        base = sanitize_base(uf.name, fallback=f"{stem}_{idx:02d}")
        dst = fotos_dir / f"{idx:02d}_{base}.jpg"
        with open(dst, "wb") as f:
            f.write(uf.getvalue())  # sin conversión
        saved_paths.append(dst)
        idx += 1

    return saved_paths


def update_info_json(prod_dir: Path, data: dict) -> None:
    info_path = prod_dir / "info.json"
    with open(info_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def rename_product_dir_if_needed(brand: str, old_dir: Path, new_nombre: str) -> Path:
    old_stem = old_dir.name
    new_stem = slugify_for_stem(new_nombre)
    if new_stem == old_stem:
        return old_dir

    new_dir = PRODUCTOS_DIR / brand / new_stem
    if new_dir.exists():
        raise FileExistsError(f"Ya existe un producto con STEM '{new_stem}' en la marca '{brand}'.")
    old_dir.rename(new_dir)
    return new_dir


# =======================
#   Persistencia principal (guardar en "Nuevo producto")
# =======================
def save_logo(brand: str, logo_bytes: bytes, filename: str) -> Path:
    """
    Guarda el logo como PNG SIEMPRE (Marca.png) sin convertir el contenido.
    Acepta png/jpg/jpeg/webp y escribe los bytes tal cual a 'Marca.png'.
    """
    ext = Path(filename).suffix.lower()
    if ext not in {".png", ".jpg", ".jpeg", ".webp"}:
        raise ValueError("Formato de logo no soportado. Usa PNG/JPG/JPEG/WEBP.")
    ensure_dir(LOGOS_DIR)
    dst = LOGOS_DIR / f"{brand}.png"
    with open(dst, "wb") as f:
        f.write(logo_bytes)  # sin conversión: solo cambiamos la extensión del archivo destino
    return dst


def save_product(
    brand: str,
    nombre: str,
    precio: float,
    tallas: List[str],
    categoria: str,
    url: str,
    fotos_with_meta: List[Tuple[str, bytes, int, bool]],  # (orig_name, content, order, is_solo)
) -> dict:
    """
    Guarda:
      - info.json con {nombre, marca, precio, tallas, categoria, url}
      - fotos en orden con prefijos 01_, 02_, ... SIEMPRE con extensión .jpg (sin convertir contenido),
        y la que sea SOLO con sufijo _solo antes de la extensión.
    """
    stem = slugify_for_stem(nombre)
    out_dir = PRODUCTOS_DIR / brand / stem
    fotos_dir = out_dir / "fotos"
    ensure_dir(fotos_dir)

    # Guardar info.json (con el campo url)
    info_path = out_dir / "info.json"
    data = {
        "nombre": nombre,
        "marca": brand,
        "precio": float(precio) if precio is not None else None,
        "tallas": tallas,
        "categoria": categoria,
        "url": url,
    }
    with open(info_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # Ordenar por 'order' y guardar archivos como .jpg SIEMPRE (sin conversión)
    fotos_with_meta_sorted = sorted(fotos_with_meta, key=lambda x: x[2])
    for idx, (orig_name, content, _order, is_solo) in enumerate(fotos_with_meta_sorted, start=1):
        base = sanitize_base(orig_name, fallback=f"{stem}_{idx:02d}")
        solo_suffix = "_solo" if is_solo else ""
        dst_name = f"{idx:02d}_{base}{solo_suffix}.jpg"
        with open(fotos_dir / dst_name, "wb") as f:
            f.write(content)  # sin conversión: solo cambiamos la extensión del archivo destino

    return {
        "stem": stem,
        "info_path": str(info_path.relative_to(ROOT)),
        "fotos_dir": str(fotos_dir.relative_to(ROOT)),
    }


def run_node_generators():
    """Ejecuta los scripts de Node para regenerar índices TS."""
    try:
        res1 = subprocess.run(
            ["node", str(ROOT / "scripts" / "generateAssetsIndex.js")],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
        )
        res2 = subprocess.run(
            ["node", str(ROOT / "scripts" / "generateProductsIndex.js")],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
        )
        ok = res1.returncode == 0 and res2.returncode == 0
        out = "\n".join(
            [
                "[generateAssetsIndex.js]",
                res1.stdout or "",
                res1.stderr or "",
                "[generateProductsIndex.js]",
                res2.stdout or "",
                res2.stderr or "",
            ]
        )
        return ok, out
    except FileNotFoundError:
        return False, "No se encontró Node.js en el entorno (comando 'node')."


# =======================
#       UI Streamlit
# =======================
st.set_page_config(page_title="Gestor de Productos", page_icon="🧵", layout="wide")
st.title("Gestor de Productos (Streamlit)")
st.caption(
    "➕ Sube y ordena fotos (.jpg destino, sin conversión de bytes). "
    "🗂 Revisa/edita productos por marca. "
    "🪪 Logos se guardan como .png (sin conversión)."
)

# Mensaje flash tras recarga
if "flash_success" in st.session_state:
    st.success(st.session_state.pop("flash_success"))
if "flash_warning" in st.session_state:
    st.warning(st.session_state.pop("flash_warning"))
if "flash_error" in st.session_state:
    st.error(st.session_state.pop("flash_error"))

# Sidebar: Añadir nueva marca
st.sidebar.header("Añadir marca nueva")
with st.sidebar.form("form_marca"):
    brand_name_sidebar = st.text_input("Nombre de la marca", value="", key="brand_name")
    logo_file = st.file_uploader(
        "Logo (PNG/JPG/JPEG/WEBP) — se guardará como .png (sin conversión)",
        type=["png", "jpg", "jpeg", "webp"],
        key="brand_logo",
    )
    add_brand = st.form_submit_button("Guardar marca")

if add_brand:
    if not brand_name_sidebar.strip():
        st.sidebar.error("Introduce un nombre de marca.")
    elif logo_file is None:
        st.sidebar.error("Sube un logo para la marca.")
    else:
        try:
            dst = save_logo(brand_name_sidebar.strip(), logo_file.getvalue(), logo_file.name)
            st.sidebar.success(f"Marca '{brand_name_sidebar.strip()}' guardada: {dst.relative_to(ROOT)}")
        except Exception as e:
            st.sidebar.error(f"Error guardando marca: {e}")

# =======================
#   Tabs
# =======================
tab_new, tab_view = st.tabs(["➕ Nuevo producto", "🗂 Ver / Editar productos"])

# -------------------------------------------------------------------
# TAB 1: NUEVO PRODUCTO
# -------------------------------------------------------------------
with tab_new:
    st.header("Nuevo producto")

    brands = list_brands()
    if not brands:
        st.info("No hay marcas todavía. Añade una en la barra lateral.")

    col_form, col_actions = st.columns([2, 1])

    with col_form:
        # Marca (obligatoria)
        brand = st.selectbox("Marca *", options=["(selecciona)"] + brands, index=0)

        # Campos del JSON requerido
        nombre = st.text_input("Nombre del producto *", placeholder="Camisa romántica antracita")

        precio = st.number_input("Precio (€) *", min_value=0.0, step=0.01, format="%.2f")

        tallas_opts = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]
        tallas = st.multiselect("Tallas *", options=tallas_opts, default=[])

        categoria = st.text_input("Categoría *", placeholder="Camisas")

        # URL adicional (como pediste)
        url = st.text_input("URL del producto (opcional)")

        # Uploader de fotos (múltiples) + vista previa y orden
        fotos_files = st.file_uploader(
            "Fotos del producto (puedes subir varias) — se guardarán como .jpg (sin conversión)",
            type=["png", "jpg", "jpeg", "webp"],
            accept_multiple_files=True,
            help="Se guardarán dentro de assets/productos/{marca}/{STEM}/fotos con extensión .jpg (sin conversión).",
            key="uploader_fotos",
        )

        # Si hay fotos, permitir orden y selección SOLO
        if fotos_files:
            st.subheader("Vista previa y orden de fotos")

            file_records: List[Tuple[str, Any, int]] = []
            for i, uf in enumerate(fotos_files):
                rec_id = f"{uf.name}__{i}"  # id estable por archivo subido en esta sesión
                file_records.append((rec_id, uf, i + 1))

            # Selector de 'SOLO'
            st.markdown("**Marca una foto como _SOLO_ (opcional):**")
            solo_options = ["(ninguna)"] + [f"{i+1}. {uf.name}" for i, (_, uf, _) in enumerate(file_records)]
            solo_choice = st.selectbox(
                "Foto SOLO",
                options=solo_options,
                index=0,
                key="solo_choice",
                help="La foto marcada se guardará con sufijo _solo en el nombre.",
            )

            solo_id: Optional[str] = None
            if solo_choice != "(ninguna)":
                try:
                    idx_str = solo_choice.split(".")[0].strip()
                    idx_int = int(idx_str) - 1
                    solo_id = file_records[idx_int][0]
                except Exception:
                    solo_id = None
            # Persistimos el id seleccionado
            st.session_state["solo_id"] = solo_id

            st.caption("Asigna una **posición** a cada foto (1 = primera). Luego revisa la previsualización del orden resultante.")
            for rec_id, uf, default_pos in file_records:
                with st.container():
                    c1, c2 = st.columns([1, 3])
                    with c1:
                        st.image(uf, caption=uf.name, use_container_width=True)
                    with c2:
                        st.write(f"**Archivo:** {uf.name}")
                        pos_key = f"pos_{rec_id}"
                        # No reasignamos session_state manualmente. Solo le pasamos un value inicial.
                        _pos_value = st.number_input(
                            f"Posición para {uf.name}",
                            min_value=1,
                            max_value=len(file_records),
                            value=st.session_state.get(pos_key, default_pos),
                            key=pos_key,
                        )
                        if st.session_state.get("solo_id") == rec_id:
                            st.info("Esta foto está marcada como **SOLO**.")

            # Previsualización del orden final y nombres que se guardarán
            st.markdown("### Vista previa de orden y nombres resultantes")
            ordered_preview = sorted(
                file_records,
                key=lambda r: st.session_state.get(f"pos_{r[0]}", 0)
            )
            for i, (rec_id, uf, _) in enumerate(ordered_preview, start=1):
                base = sanitize_base(uf.name, fallback=f"foto_{i:02d}")
                solo_suffix = "_solo" if rec_id == st.session_state.get("solo_id") else ""
                st.write(f"- **{i:02d}_{base}{solo_suffix}.jpg**")

    with col_actions:
        st.subheader("Acciones")
        do_save = st.button("Guardar producto")
        do_generate = st.button("Actualizar índices (Node)")

    # =======================
    #   Guardar (tab 1)
    # =======================
    if do_save:
        # Validaciones agregadas (un solo mensaje con todos los campos que faltan)
        missing: List[str] = []
        if brand == "(selecciona)":
            missing.append("marca")
        if not nombre.strip():
            missing.append("nombre")
        # Consideramos precio > 0 como obligatorio (0 se trata como faltante). Cambia esto si quieres permitir 0.
        if precio is None or float(precio) <= 0:
            missing.append("precio")
        if not tallas:
            missing.append("tallas")
        if not categoria.strip():
            missing.append("categoría")
        if not st.session_state.get("uploader_fotos"):
            missing.append("fotos")

        if missing:
            st.error("Faltan campos obligatorios: " + ", ".join(missing))
        else:
            try:
                ensure_dir(PRODUCTOS_DIR)

                # Reconstruir records y orden desde el estado
                fotos_files = st.session_state.get("uploader_fotos", [])
                file_records2: List[Tuple[str, Any, int, bool]] = []
                for i, uf in enumerate(fotos_files):
                    rec_id = f"{uf.name}__{i}"
                    order = int(st.session_state.get(f"pos_{rec_id}", i + 1))
                    is_solo = (rec_id == st.session_state.get("solo_id"))
                    file_records2.append((rec_id, uf, order, is_solo))

                # Pasar a save_product como (orig_name, content, order, is_solo)
                fotos_with_meta: List[Tuple[str, bytes, int, bool]] = []
                for rec_id, uf, order, is_solo in file_records2:
                    fotos_with_meta.append((uf.name, uf.getvalue(), order, is_solo))

                saved = save_product(
                    brand=brand,
                    nombre=nombre.strip(),
                    precio=float(precio),
                    tallas=tallas,
                    categoria=categoria.strip(),
                    url=url.strip(),
                    fotos_with_meta=fotos_with_meta,
                )

                # Mensaje flash + recarga
                st.session_state["flash_success"] = f"✅ Producto '{nombre.strip()}' de '{brand}' guardado correctamente."
                st.rerun()

            except Exception as e:
                st.error(f"Error guardando producto: {e}")

    if do_generate:
        ok, output = run_node_generators()
        if ok:
            st.success("Índices regenerados correctamente.")
        else:
            st.warning("No se pudieron regenerar completamente los índices.")
        with st.expander("Ver salida de los scripts"):
            st.code(output)

# -------------------------------------------------------------------
# TAB 2: VER / EDITAR PRODUCTOS
# -------------------------------------------------------------------
with tab_view:
    st.header("Productos por marca — Ver, editar y eliminar")

    brands2 = list_brands()
    brand_sel = st.selectbox("Marca", options=["(selecciona)"] + brands2, index=0, key="brand_view")
    if brand_sel == "(selecciona)" or not brand_sel:
        st.info("Selecciona una marca para ver sus productos.")
    else:
        products = list_products_of_brand(brand_sel)
        if not products:
            st.info("No hay productos para esta marca todavía.")
        else:
            for prod in products:
                info = prod["info"]
                nombre = info.get("nombre", prod["stem"])
                precio = info.get("precio", "")
                categoria = info.get("categoria", "")
                tallas = info.get("tallas", [])
                url = info.get("url", "")

                with st.expander(f"🧵 {nombre}  —  {precio}€  ·  {categoria}  ·  Tallas: {', '.join(tallas) if tallas else '-'}", expanded=False):
                    ctop1, ctop2 = st.columns([3, 2])

                    # ----------------------
                    # Fotos (vista, borrar, SOLO, añadir)
                    # ----------------------
                    with ctop1:
                        st.subheader("Fotos")
                        fotos: List[Path] = sorted(prod["fotos"])

                        if fotos:
                            # mini-grid de fotos con botón eliminar
                            grid_cols = st.columns(4)
                            for i, p in enumerate(fotos):
                                col = grid_cols[i % 4]
                                with col:
                                    st.image(str(p), caption=p.name, use_container_width=True)
                                    if st.button("Eliminar", key=f"del_{prod['stem']}_{p.name}"):
                                        delete_photo(p)
                                        st.session_state["flash_success"] = f"🗑️ Foto '{p.name}' eliminada de '{nombre}'."
                                        st.rerun()

                            # Selector de SOLO
                            current_solo = None
                            foto_names = []
                            for p in fotos:
                                foto_names.append(p.name)
                                if "_solo" in p.stem:
                                    current_solo = p.name

                            st.write("**Marcar foto como _SOLO_ (opcional):**")
                            solo_choice = st.selectbox(
                                "Foto SOLO",
                                options=["(ninguna)"] + foto_names,
                                index=(foto_names.index(current_solo) + 1) if current_solo in foto_names else 0,
                                key=f"solo_sel_{prod['stem']}",
                                help="Al aplicar, solo una foto tendrá el sufijo _solo.",
                            )
                            if st.button("Aplicar SOLO", key=f"apply_solo_{prod['stem']}"):
                                chosen = None if solo_choice == "(ninguna)" else (prod["dir"] / "fotos" / solo_choice)
                                set_solo_photo(fotos, chosen)
                                st.session_state["flash_success"] = f"✅ Actualizada foto SOLO en '{nombre}'."
                                st.rerun()
                        else:
                            st.info("No hay fotos aún para este producto.")

                        # Añadir fotos
                        st.markdown("---")
                        st.write("**Añadir nuevas fotos (.png/.jpg/.jpeg/.webp) → se guardarán como `.jpg` (sin conversión del contenido).**")
                        new_files = st.file_uploader(
                            f"Añadir fotos a {nombre}",
                            type=["png", "jpg", "jpeg", "webp"],
                            accept_multiple_files=True,
                            key=f"add_files_{prod['stem']}",
                        )
                        if new_files:
                            if st.button("Subir fotos", key=f"btn_add_{prod['stem']}"):
                                fotos_dir = prod["dir"] / "fotos"
                                save_new_photos(fotos_dir, prod["stem"], new_files)
                                st.session_state["flash_success"] = f"📸 Añadidas {len(new_files)} fotos a '{nombre}'."
                                st.rerun()

                    # ----------------------
                    # Editar info + borrar producto
                    # ----------------------
                    with ctop2:
                        st.subheader("Editar información")
                        with st.form(key=f"edit_{prod['stem']}"):
                            nombre_new = st.text_input("Nombre *", value=str(nombre))
                            precio_val = float(precio) if isinstance(precio, (int, float, str)) and str(precio) != "" else 0.0
                            precio_new = st.number_input("Precio (€) *", min_value=0.0, step=0.01, format="%.2f", value=precio_val)
                            categoria_new = st.text_input("Categoría *", value=str(categoria))
                            # tallas: multiselect sobre un conjunto conocido + libres
                            tallas_opts = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]
                            tallas_current = list(tallas) if isinstance(tallas, list) else []
                            tallas_new = st.multiselect("Tallas *", options=tallas_opts, default=[t for t in tallas_current if t in tallas_opts])
                            extra_tallas = st.text_input("Tallas extra (separadas por coma, opcional)", value=", ".join([t for t in tallas_current if t not in tallas_opts]))
                            url_new = st.text_input("URL (opcional)", value=str(url))

                            colb1, colb2 = st.columns(2)
                            with colb1:
                                apply_edit = st.form_submit_button("Guardar cambios")
                            with colb2:
                                confirm_del = st.checkbox("Confirmar eliminación")
                                del_product = st.form_submit_button("Eliminar producto", type="secondary")

                        # Procesar edición
                        if apply_edit:
                            missing2: List[str] = []
                            if not nombre_new.strip():
                                missing2.append("nombre")
                            if precio_new is None or float(precio_new) <= 0:
                                missing2.append("precio")
                            if not categoria_new.strip():
                                missing2.append("categoría")
                            tallas_final = [t.strip() for t in tallas_new + ([x.strip() for x in extra_tallas.split(",")] if extra_tallas.strip() else []) if t.strip()]
                            if not tallas_final:
                                missing2.append("tallas")

                            if missing2:
                                st.error("Faltan campos obligatorios: " + ", ".join(missing2))
                            else:
                                try:
                                    # 1) Si cambia el nombre, renombrar carpeta (STEM)
                                    new_dir = rename_product_dir_if_needed(brand_sel, prod["dir"], nombre_new)
                                    # 2) Guardar info.json actualizada
                                    data = {
                                        "nombre": nombre_new.strip(),
                                        "marca": brand_sel,
                                        "precio": float(precio_new),
                                        "tallas": tallas_final,
                                        "categoria": categoria_new.strip(),
                                        "url": url_new.strip(),
                                    }
                                    update_info_json(new_dir, data)
                                    st.session_state["flash_success"] = f"💾 '{nombre_new}' de '{brand_sel}' actualizado correctamente."
                                    st.rerun()
                                except FileExistsError as e:
                                    st.error(str(e))
                                except Exception as e:
                                    st.error(f"Error actualizando el producto: {e}")

                        # Procesar borrado
                        if del_product:
                            if confirm_del:
                                try:
                                    delete_product_dir(prod["dir"])
                                    st.session_state["flash_success"] = f"🗑️ Producto '{nombre}' de '{brand_sel}' eliminado."
                                    st.rerun()
                                except Exception as e:
                                    st.error(f"Error eliminando el producto: {e}")
                            else:
                                st.warning("Marca la casilla 'Confirmar eliminación' para borrar el producto.")
