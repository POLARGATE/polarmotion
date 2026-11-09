#!/bin/sh
# PolarMotion (Polargate): comprueba la biblioteca e instala sus paquetes.
#   sh tools/setup.sh                  ¿está lista? Imprime LIB=<ruta> en la última línea
#   sh tools/setup.sh deps [voice] [music]
#                                      instala: core = paquetes de Node (versiones del package-lock), navegador sin ventana y Python core;
#                                      voice = voz Kokoro (inglés y español) y comprobación de voz; music = pluck.py (numba)
#   sh tools/setup.sh demo <slug>      ruta del código de la demo de un estilo (solo para leer técnicas)
# No descarga ni actualiza la biblioteca: la clona la skill Haz reels en una versión fija.
set -e
LIB=$(cd "$(dirname "$0")/.." && pwd -P)

sig() { cat "$@" 2>/dev/null | cksum | cut -d' ' -f1; }
pysig() { echo "$(sig "$1")-$("$LIB/.venv/bin/python" -V 2>&1 | cut -d. -f1,2)"; }
req() { [ "$1" = core ] && echo "$LIB/requirements.txt" || echo "$LIB/requirements-$1.txt"; }
node_ok() { [ "$(cat "$LIB/node_modules/.pm-ok" 2>/dev/null)" = "$(sig "$LIB/package.json" "$LIB/package-lock.json")" ]; }
py_ok() { [ "$(cat "$LIB/.venv/.pm-$1" 2>/dev/null)" = "$(pysig "$(req "$1")")" ]; }
# kokoro-onnx (voz) necesita Python < 3.14: primero las versiones que valen
find_py() {
  for c in python3.12 python3.13 python3.11 python3; do
    "$c" -c 'import sys; sys.exit(not ((3, 11) <= sys.version_info < (3, 14)))' 2>/dev/null && { echo "$c"; return 0; }
  done
  return 1
}

case "$1" in
  deps)
    shift; tiers=core
    for t in "$@"; do case $t in voice|music) tiers="$tiers $t" ;; *) echo "uso: sh tools/setup.sh deps [voice] [music]"; exit 1 ;; esac; done
    cd "$LIB"
    command -v npm >/dev/null || { echo "✗ falta npm: instala Node 20 o superior"; exit 1; }
    if ! node_ok; then
      npm ci --no-audit --no-fund --loglevel=error
      sig package.json package-lock.json > node_modules/.pm-ok
    fi
    node node_modules/playwright-core/cli.js install chromium-headless-shell   # el navegador del render (no hace nada si ya está)
    [ ! -e .venv ] || .venv/bin/python -c pass 2>/dev/null || { echo "! $LIB/.venv está roto; lo rehago"; rm -rf .venv; }
    if [ ! -x .venv/bin/python ]; then
      if command -v uv >/dev/null; then uv venv --quiet --python 3.12 .venv
      else py=$(find_py) || { echo "✗ hace falta Python 3.11, 3.12 o 3.13 (o instalar uv, que lo trae)"; exit 1; }; "$py" -m venv .venv; fi
    fi
    for t in $tiers; do
      py_ok "$t" && continue
      if command -v uv >/dev/null; then uv pip install --quiet --python .venv/bin/python -r "$(req "$t")"
      else .venv/bin/python -m pip install --quiet --disable-pip-version-check -r "$(req "$t")"; fi
      pysig "$(req "$t")" > ".venv/.pm-$t"
    done
    case " $tiers " in *" voice "*) [ -f core/tts/kokoro-v1.0.onnx ] && [ -f core/tts/voices-v1.0.bin ] || sh tools/fetch.sh voice ;; esac
    ;;
  demo)
    [ -n "$2" ] && [ -f "$LIB/styles/$2/STYLE.md" ] || { echo "uso: sh tools/setup.sh demo <slug>  (estilos: $LIB/styles/INDICE.md)"; exit 1; }
    echo "demo source: $LIB/styles/$2/demo"
    ;;
esac

# Herramientas del sistema que hacen falta (solo avisa; instalarlas es cosa de la persona)
miss=""
if command -v node >/dev/null; then
  [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] || miss="$miss node20+(hay $(node -v))"
else miss="$miss node20+"; fi
if command -v ffmpeg >/dev/null; then
  ffv=$(ffmpeg -version 2>/dev/null | sed -n '1s/^ffmpeg version n\{0,1\}\([0-9][0-9]*\)\..*/\1/p')
  [ -z "$ffv" ] || [ "$ffv" -ge 7 ] || miss="$miss ffmpeg7+(hay $ffv.x)"
else miss="$miss ffmpeg"; fi
command -v uv >/dev/null || find_py >/dev/null || miss="$miss python3.11-3.13(o uv)"
[ -n "$miss" ] && echo "! falta:$miss"
node_ok && py_ok core || echo "! paquetes sin instalar: 'sh tools/setup.sh deps' (unos minutos) antes del primer render"
echo "LIB=$LIB"
