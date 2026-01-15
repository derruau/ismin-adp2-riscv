#! /usr/bin/env bash
if [ $# -ne 1 ]; then
    HDL_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../hdl_src/";
    TB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../tb";
else
    HDL_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../hdl_src/$1";
    TB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../tb";
fi

files_list=(
    "$HDL_DIR/RV32i_pkg.sv"
    "$HDL_DIR/regfile.sv"
    "$HDL_DIR/RV32i_alu.sv"
    "$HDL_DIR/RV32i_pipeline_controlpath.sv"
    "$HDL_DIR/RV32i_pipeline_datapath.sv"
    "$HDL_DIR/RV32i_pipeline_top.sv"
    "$HDL_DIR/RV32i_soc.sv"
    "$HDL_DIR/wsync_mem.sv"
    "$HDL_DIR/wsync_mem_o128.sv"
    "$TB_DIR/RV32i_tb.sv"
)
if [ ! -d "./libs" ]; then
  mkdir libs
fi
if [ -d "./libs/work" ]; then
    vdel -lib "./libs/work/" -all
    vlib "./libs/work"
else
    vlib "./libs/work"
fi
vmap work "./libs/work"
for file in "${files_list[@]}"; do
    echo "compiling : " "$file"
    vlog -quiet -work work "+acc" -sv "$file"
done
vsim RV32i_tb
