#!/bin/bash
# verdi_print.sh - abre o Verdi numa tela virtual (Xvfb), carrega um FSDB,
# adiciona sinais, da zoom e salva um print PNG.
#
# Uso (rodar de verif/):
#   scripts/verdi_print.sh <waves.fsdb> <saida.png> <t_ini_ns> <t_fim_ns> <sinal> [sinal ...]
# Exemplo:
#   scripts/verdi_print.sh sim/waves.fsdb mem.png 20 200 /top_tb/mem_if_i/mem_clk /top_tb/mem_if_i/tb_valid
set -e
FSDB=$(readlink -f "$1"); OUT=$(readlink -f "$2"); T0=$3; T1=$4; shift 4
SIM_DIR=$(readlink -f "$(dirname "$0")/../sim")
DISP=:$((90 + RANDOM % 9))
TCL=$(mktemp --suffix=.tcl)

{
  echo "debImport -dbdir $SIM_DIR/simv.daidir"
  echo "debLoadSimResult $FSDB"
  echo "wvCreateWindow"
  echo "verdiWindowResize -win \$_Verdi_1 0 0 1600 900"
  echo "verdiDockWidgetMaximize -dock windowDock_nWave_2"
  for s in "$@"; do echo "wvAddSignal -win \$_nWave2 \"$s\""; done
  echo "wvSelectAll -win \$_nWave2"
  echo "wvSetRadix -win \$_nWave2 -format Hex"
  echo "wvSelectSignal -win \$_nWave2"
  echo "wvZoom -win \$_nWave2 $((T0 * 1000)) $((T1 * 1000))"
} > "$TCL"

/usr/bin/Xvfb $DISP -screen 0 1600x900x24 >/dev/null 2>&1 & XPID=$!
sleep 2
cd "$SIM_DIR"
DISPLAY=$DISP verdi -play "$TCL" -nologo >/dev/null 2>&1 & VPID=$!
sleep 25
DISPLAY=$DISP import -window root "$OUT"
kill $VPID 2>/dev/null || true
sleep 1
kill $XPID 2>/dev/null || true
echo "print salvo: $OUT"
