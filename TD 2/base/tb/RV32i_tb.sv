//                              -*- Mode: Verilog -*-
// Filename        : RV32i_monocycle_tb.sv
// Description     : RV32i monocycle testbench
// Author          : michel.agoyan
// Created On      : Tue Aug 20 10:56:09 2024
// Last Modified By: michel.agoyan
// Last Modified On: Tue Aug 20 10:56:09 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

`timescale 1ns / 1ps
module RV32i_tb ();

  logic clk_r;
  logic resetn_r;
  real  freq = 100;
  real  half_period;
  int   sim_duration = 1000;

  logic [31:0] inst_w, inst_dec_w, t0_w, t1_w, t2_w, t3_w, s1_w, a0_w, a1_w, a2_w, a3_w, a4_w, a5_w;
  int i, j;


  RV32i_soc #(
      .IMEM_INIT_FILE("../firmware/imem.hex"),
      .DMEM_INIT_FILE("../firmware/dmem.hex")
  ) RV32i_soc_inst (
      .clk_i(clk_r),
      .resetn_i(resetn_r)
  );

  //clock generator
  always begin
    #(half_period) clk_r = ~clk_r;
  end

  assign inst_w = RV32i_tb.RV32i_soc_inst.RV32i_core.imem_data_i;
  assign inst_dec_w = RV32i_tb.RV32i_soc_inst.RV32i_core.cp.inst_exec_r;
  assign t0_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[5];
  assign t1_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[6];
  assign t2_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[7];
  assign t3_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[28];
  assign s1_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[9];
  assign a0_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[10];
  assign a1_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[11];
  assign a2_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[12];
  assign a3_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[13];
  assign a4_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[14];
  assign a5_w = RV32i_tb.RV32i_soc_inst.RV32i_core.dp.regfile_inst.register_r[15];

  always @(inst_dec_w) begin
    $display(
        "At time %t, instruction= %h t0=%h t1=%h t2=%h t3=%h s1_w=%h a0=%h a1=%h a2=%h a3=%h a4=%h a5=%h",
        $time, inst_dec_w, t0_w, t1_w, t2_w, t3_w, s1_w, a0_w, a1_w, a2_w, a3_w, a4_w, a5_w);
  end
  initial begin
    if ($test$plusargs("FREQ")) begin
      if ($value$plusargs("FREQ=%d", freq))
        $display("running frequency is equal to :%d MHz", int'(freq));
    end
    half_period = realtime'($ceil(500.0 / freq));
    $display("half running period= %f", half_period);

    if ($test$plusargs("SIMD")) begin
      if ($value$plusargs("SIMD=%d", sim_duration))
        $display("simulation duration :%d clock periods", sim_duration);
    end


    clk_r = 1'b0;
    resetn_r = 1'b0;

    repeat (5) begin
      @(posedge clk_r);
    end

    #0.1 resetn_r = 1'b1;
    @(posedge clk_r);

    i = 0;

    do begin
      @(inst_w);
      if (inst_w == 32'h0000006F) begin
        @(inst_w);
        if (inst_w == 32'h00000013) i = i + 1;
        else begin
          @(inst_w);
          i = 0;
        end
      end
    end while (i < 5);

    $display("Simulation stops at %t", $time);

    $stop;
  end

  initial j = 0;
  always @(posedge clk_r) if (j++ > sim_duration) $stop;

endmodule
