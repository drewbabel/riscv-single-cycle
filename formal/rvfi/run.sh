#!/usr/bin/env bash
# Build and run the riscv-formal suite against the core
# no args proves all, --list prints check names, names prove only those
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CORE=rv32i_single
RVF="${RISCV_FORMAL_DIR:-$HOME/Documents/code/riscv-formal}"

if [ ! -d "$RVF" ]; then
  git clone https://github.com/YosysHQ/riscv-formal.git "$RVF"
fi

DST="$RVF/cores/$CORE"
mkdir -p "$DST"
cp "$HERE/wrapper.sv" "$DST/wrapper.sv"
cp "$HERE/checks.cfg" "$DST/checks.cfg"

RTL=(
  alu_pkg csr_pkg alu extend pc regfile imem dmem
  alu_decoder control_decoder control_unit csr datapath riscv_single
)
SRC=()
for m in "${RTL[@]}"; do SRC+=("$ROOT/rtl/$m.sv"); done
sv2v -D RISCV_FORMAL "${SRC[@]}" > "$DST/$CORE.v"

cd "$DST"
python3 "$RVF/checks/genchecks.py" >&2

if [ "${1:-}" = "--list" ]; then
  ls checks/*.sby | xargs -n1 basename | sed 's/\.sby$//'
elif [ "$#" -gt 0 ]; then
  for c in "$@"; do sby -f "checks/$c.sby"; done
else
  make -j"$(getconf _NPROCESSORS_ONLN)" -C checks
fi
