#!/bin/bash
vcs -sverilog -full64 -debug_access+all +v2k -timescale=1ns/1ps ../RTL/reg_file.sv test_rf_sim.sv -o simv_debug >/dev/null 2>&1
if [ -f simv_debug ]; then
  ./simv_debug
else
  echo "VCS failed to compile"
fi
