#!/usr/bin/env bash
# Exportiert alle Teile von rugged_case.scad als STL.
#
# Aufruf:
#   ./export.sh                                  # Standardmaße -> ./stl/
#   ./export.sh -D inner_x=150 -D inner_y=100    # eigene Parameter
#   OUT=meine_box ./export.sh -D base_in_h=40    # anderes Zielverzeichnis
#
# Alle Argumente werden an openscad durchgereicht.
set -euo pipefail

cd "$(dirname "$0")"
SCAD=rugged_case.scad
OUT="${OUT:-.}"
mkdir -p "$OUT"

pids=()
PARTS=(base lid latch handle)
for p in "${PARTS[@]}"; do
    echo "-> $OUT/$p.stl"
    openscad "$@" -D "part=\"$p\"" -o "$OUT/$p.tmp.stl" "$SCAD" >"$OUT/$p.log" 2>&1 &
    pids+=($!)
done

fail=0
for i in "${!pids[@]}"; do
    p=${PARTS[$i]}
    wait "${pids[$i]}" && ok=1 || ok=0
    if [ "$p" = handle ] && grep -q "object is empty" "$OUT/$p.log"; then
        echo "   kein Griff: $(grep -o 'Kein Griff: [^"]*' "$OUT/$p.log" | sed 's/^Kein Griff: //' || echo 'deaktiviert')"
        rm -f "$OUT/$p.tmp.stl" "$OUT/$p.stl" "$OUT/$p.log"
        continue
    fi
    if [ "$ok" = 1 ]; then
        mv "$OUT/$p.tmp.stl" "$OUT/$p.stl"
        rm -f "$OUT/$p.log"
    else
        rm -f "$OUT/$p.tmp.stl" "$OUT/$p.stl"   # keine veralteten STLs liegen lassen
        echo "FEHLER bei $p:" >&2
        grep -E "ERROR|WARNING" "$OUT/$p.log" >&2 || cat "$OUT/$p.log" >&2
        fail=1
    fi
done

if [ "$fail" -eq 0 ]; then
    echo "Fertig. latch.stl 2x drucken (auf der Seite liegend)."
    [ -f "$OUT/handle.stl" ] && echo "handle.stl flach liegend drucken."
fi
exit "$fail"
