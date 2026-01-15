//                              -*- Mode: Verilog -*-
// Filename        : wsync_mem.sv
// Description     : SRAM model. Synchonous writing, Asynchronous reading
// Author          : Michel Agoyan
// Created On      : Sun Aug 18 17:29:59 2024
// Last Modified By: michel agoyan
// Last Modified On: Sun Aug 18 17:29:59 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module wsync_mem #(
    parameter SIZE = 4096,
    localparam SIZE_IN_BYTES = SIZE / 4,
    localparam ADDR_SIZE = $clog2(SIZE_IN_BYTES),
    parameter WS = 0,
    INIT_FILE = ""
) (
    input  logic                 clk_i,
    input  logic                 we_i,
    input  logic                 re_i,
    input  logic [          3:0] ble_i,
    input  logic [         31:0] d_i,
    input  logic [ADDR_SIZE-1:0] add_i,
    output logic [         31:0] d_o,
    output logic                 valid_o
);
  logic [31:0] mem    [SIZE_IN_BYTES];
  logic [31:0] mask_w;
  logic [31:0] mem_masked_w, data_masked_w, data_w;

  logic [2:0] cnt_r = 0;

  assign mask_w = {{8{ble_i[3]}}, {8{ble_i[2]}}, {8{ble_i[1]}}, {8{ble_i[0]}}};

  initial begin
    if (INIT_FILE == "") $readmemh("../firmware/zero.hex", mem);
    else $readmemh(INIT_FILE, mem);
  end

  assign mem_masked_w = mem[add_i] & ~mask_w;
  assign data_masked_w = d_i & mask_w;
  assign data_w = mem_masked_w | data_masked_w;

  always_ff @(posedge clk_i) begin : wmem
    //if (we_i == 1'b1) mem[add_i] <= (d_i & mask_w )| (mem[add_i] & ~mask_w);
    if (we_i == 1'b1) mem[add_i] <= data_w;
  end

  always_comb begin : rmem
    if (re_i == 1'b1) d_o = mem[add_i] & mask_w;
    else d_o = 0;
  end

  always_ff @(posedge clk_i) begin : valid_proc
    if (((re_i == 1'b1) || (we_i == 1'b1)) && (cnt_r != WS)) cnt_r <= cnt_r + 1;
    else if ((cnt_r == WS) && ((re_i == 1'b1) || (we_i == 1'b1))) cnt_r <= 0;
    else if ((re_i == 1'b0) && (we_i == 1'b0)) cnt_r <= 0;
    else cnt_r <= cnt_r;
  end
  assign valid_o = ((cnt_r == WS) && ((re_i == 1'b1) || (we_i == 1'b1))) ? 1'b1 : 1'b0;
endmodule
