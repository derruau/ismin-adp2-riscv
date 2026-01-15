//                              -*- Mode: Verilog -*-
// Filename        : RV32i_alu.sv
// Description     : Arithmetic & Logic Unit
// Author          : Michel Agoyan
// Created On      : Thu Jul 18 13:23:15 2024
// Last Modified By: michel agoyan
// Last Modified On: Thu Jul 18 13:23:15 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module alu (
    input  logic        [ 3:0] func_i,
    input  logic signed [31:0] op1_i,
    input  logic signed [31:0] op2_i,
    output logic signed [31:0] d_o,
    output logic               zero_o,
    output logic               lt_o,
    output logic               ltu_o
);

  import RV32i_pkg::*;

  logic [31:0] d_w;
  logic lt_w, ltu_w;

  assign lt_w  = op1_i < op2_i;
  assign ltu_w = $unsigned(op1_i) < $unsigned(op2_i);

  always_comb begin
    case (func_i)
      ALU_ADD: d_w = op1_i + op2_i;
      ALU_SUB: d_w = op1_i - op2_i;
      ALU_AND: d_w = op1_i & op2_i;
      ALU_XOR: d_w = op1_i ^ op2_i;
      ALU_OR: d_w = op1_i | op2_i;
      ALU_SLT: d_w = {31'b0, lt_w};
      ALU_SLTU: d_w = {31'b0, ltu_w};
      ALU_SLLV: d_w = op1_i << op2_i[4:0];
      ALU_SRLV: d_w = op1_i >> op2_i[4:0];
      ALU_SRAV: d_w = op1_i >>> op2_i[4:0];
      ALU_COPY_RS1: d_w = op1_i;
      ALU_X: d_w = 32'hxxxxxxxx;
      default: d_w = 32'h0;
    endcase
  end

  assign zero_o = d_w == 32'h0;
  assign lt_o = lt_w;
  assign ltu_o = ltu_w;
  assign d_o = d_w;

endmodule
