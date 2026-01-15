//                              -*- Mode: Verilog -*-
// Filename        : RV32i_monocycle_top.sv
// Description     : RV32i top
// Author          : Michel Agoyan
// Created On      : Tue Aug 20 08:43:20 2024
// Last Modified By: ROUCWL7441
// Last Modified On: Tue Aug 20 08:43:20 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module RV32i_top (
    input  logic        clk_i,
    input  logic        resetn_i,
    output logic [31:0] imem_add_o,
    input  logic [31:0] imem_data_i,
    output logic        imem_re_o,
    input  logic        imem_valid_i,
    input  logic        dmem_valid_i,
    output logic [31:0] dmem_add_o,
    input  logic [31:0] dmem_do_i,
    output logic [31:0] dmem_di_o,
    output logic        dmem_we_o,
    output logic        dmem_re_o,
    output logic [ 3:0] dmem_ble_o

);

  import RV32i_pkg::*;

  // Fetch stage
  logic        fetch_nop_w;
  // Dec stage
  logic [31:0] instruction_w;
  logic [ 2:0] pc_next_sel_w;
  logic [ 1:0] alu_src1_w;
  logic        alu_src2_w;
  logic [ 2:0] imm_gen_sel_w;
  // Exec stage
  logic [ 3:0] alu_control_w;
  logic        alu_zero_w;
  logic        alu_lt_w;
  logic        alu_ltu_w;
  // Mem stage
  logic        dmem_we_w;
  logic        dmem_re_w;
  // Write back
  logic [ 1:0] wb_sel_w;

  logic [ 4:0] rd_add_w;

  logic        reg_we_w;

  logic stall_from_hazard_w, stall_from_fetch_w, stall_frow_mem_w;
  logic stall_dec_w, stall_exec_w;

  logic branch_taken_w;
  logic flush_dec_w, flush_exec_w;

  RV32i_datapath dp (
      .clk_i(clk_i),
      .resetn_i(resetn_i),
      // Fetch stage
      .imem_add_o(imem_add_o),
      .imem_data_i(imem_data_i),
      .fetch_nop_i(fetch_nop_w), // Pour transmettre le signal du controlpath au datapath
      // Dec stage
      .stall_dec_i(stall_dec_w),
      .instruction_o(instruction_w),
      .pc_next_sel_i(pc_next_sel_w),
      .alu_src1_i(alu_src1_w),
      .alu_src2_i(alu_src2_w),
      .imm_gen_sel_i(imm_gen_sel_w),
      .flush_dec_i(flush_dec_w), // <===
      // Exec stage
      .stall_exec_i(stall_exec_w),
      .alu_control_i(alu_control_w),
      .alu_zero_o(alu_zero_w),
      .alu_lt_o(alu_lt_w),
      .alu_ltu_o(alu_ltu_w),
      .flush_exec_i(flush_exec_w), // <====
      // Mem stage
      .dmem_add_o(dmem_add_o),
      .dmem_di_o(dmem_di_o),
      .dmem_ble_o(dmem_ble_o),
      .dmem_do_i(dmem_do_i),
      // Write back
      .wb_sel_i(wb_sel_w),

      .rd_add_i(rd_add_w),

      .reg_we_i(reg_we_w)
  );

  RV32i_controlpath cp (
      .clk_i(clk_i),
      .resetn_i(resetn_i),
      // Fetch stage
      .fetch_nop_o(fetch_nop_w), // Pour transmettre le signal du controlpath au datapath
      // Dec stage
      .stall_dec_i(stall_dec_w),
      .instruction_i(instruction_w),
      .pc_next_sel_o(pc_next_sel_w),
      .alu_src1_o(alu_src1_w),
      .alu_src2_o(alu_src2_w),
      .imm_gen_sel_o(imm_gen_sel_w),
      .stall_o(stall_from_hazard_w),
      // Exec stage
      .stall_exec_i(stall_exec_w),
      .alu_control_o(alu_control_w),
      .alu_zero_i(alu_zero_w),
      .alu_lt_i(alu_lt_w),
      .alu_ltu_i(alu_ltu_w),
      .branch_taken_o(branch_taken_w), // <===
      // Mem stage
      .dmem_we_o(dmem_we_w),
      .dmem_re_o(dmem_re_w),
      // Write back

      .rd_add_o(rd_add_w),

      .wb_sel_o(wb_sel_w),
      .reg_we_o(reg_we_w)
  );

  assign imem_re_o = 1'b1;

  assign dmem_we_o = dmem_we_w;
  assign dmem_re_o = dmem_re_w;

  assign stall_from_fetch_w = !imem_valid_i;
  assign stall_from_mem_w = (dmem_we_w || dmem_re_w) && !dmem_valid_i;

  assign stall_exec_w = stall_from_mem_w;
  assign stall_dec_w = stall_from_fetch_w || stall_from_hazard_w || stall_exec_w;

  // On a pas besoin de deux signaux de flush et on pourrait se débrouiller avec un seul mais afin de futurproof le design au cas où on ait besoin de flush les étages individuellement plus tard, on fait comme ceci.
  assign flush_dec_w = branch_taken_w;
  assign flush_exec_w = branch_taken_w;

endmodule
