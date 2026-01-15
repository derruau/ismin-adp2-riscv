//                              -*- Mode: Verilog -*-
// Filename        : RV32i_monocycle_datapath.sv
// Description     : monocycle datapath
// Author          : Michel Agoyan
// Created On      : Thu Jul 18 13:52:18 2024
// Last Modified By: michel agoyan
// Last Modified On: Thu Jul 18 13:52:18 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module RV32i_datapath (
    input  logic        clk_i,
    input  logic        resetn_i,
    // Fetch stage
    output logic [31:0] imem_add_o,
    input  logic [31:0] imem_data_i,
    input  logic        fetch_nop_i, // Le signal du control_path qui permet de sélectionner
                                     // une instruction NOP à mettre dans le registre de
                                     // l'étage DEC au lieu de l'instruction de la mémoire qui 
                                     // devrait normalement s'y trouver.
    // Dec stage
    input  logic        stall_dec_i,
    output logic [31:0] instruction_o,
    input  logic [ 2:0] pc_next_sel_i,
    input  logic [ 1:0] alu_src1_i,
    input  logic        alu_src2_i,
    input  logic [ 2:0] imm_gen_sel_i,
    input  logic        flush_dec_i, // Si ce signal est à 1, on remplace le contenu du
                                     // registre à l'étage DEC par un NOP
    // Exec stage
    input  logic        stall_exec_i,
    input  logic [ 3:0] alu_control_i,
    output logic        alu_zero_o,
    output logic        alu_lt_o,
    output logic        alu_ltu_o,
    input  logic        flush_exec_i, // Si ce signal est à 1, on remplace le contenu du
                                      // registre à l'étage EXEC par un NOP
    // Mem stage
    output logic [31:0] dmem_add_o,
    output logic [31:0] dmem_di_o,
    output logic [ 3:0] dmem_ble_o,
    input  logic [31:0] dmem_do_i,
    // Write back
    input  logic [ 1:0] wb_sel_i,

    input logic [4:0] rd_add_i,

    input logic reg_we_i
);

  import RV32i_pkg::*;

  // Fetch stage
  logic [31:0] pc_counter_r;
  logic [31:0] inst_w;
  logic [ 6:0] opcode_w;
  logic [ 2:0] func3_w;
  logic [ 6:0] func7_w;
  logic [ 4:0] rs1_add_w;
  logic [ 4:0] rs2_add_w;
  logic [31:0] pc_plus4_w;
  logic [31:0] pc_next_w;
  // Dec stage
  logic [ 6:0] opcode_r;
  logic [ 2:0] func3_dec_r;
  logic [ 6:0] func7_dec_r;
  logic [4:0] rs1_add_r, rs2_add_r, rd_add_dec_r;
  logic [31:0] pc_counter_dec_r;
  logic [31:0] inst_r;
  logic [31:0] rs1_data_w, rs2_data_w;
  logic [31:0] imm_w;
  logic [31:0] pc_j_target_w;
  logic [31:0] pc_br_target_w;
  logic [31:0] pc_jr_target_w;
  logic [31:0] alu_op1_data_w, alu_op2_data_w;
  // Exec stage
  logic [31:0] alu_op1_data_r, alu_op2_data_r;
  logic [31:0] rs2_data_r;
  logic [ 2:0] func3_exec_r;
  logic [31:0] pc_br_target_r;
  logic [31:0] pc_counter_exec_r;
  logic [31:0] alu_do_w;
  logic [ 1:0] dmem_add_lsb_w;
  logic [ 3:0] ble_w;
  // Mem stage
  logic [31:0] dmem_add_r;
  logic [31:0] dmem_di_r;
  logic [ 3:0] dmem_ble_r;
  logic [31:0] pc_counter_mem_r;
  logic [ 2:0] func3_mem_r;
  logic        rdu_w;
  logic        rd_extend_w;
  logic [31:0] rd_shifter_do_w, wr_shifter_di_w;
  // Write back
  logic [31:0] rd_shifter_do_r;
  logic [31:0] alu_do_r;
  logic [31:0] pc_counter_wb_r;
  logic [ 4:0] rd_add_w;
  logic [31:0] wb_data_w;

  // Fetch stage

  always_ff @(posedge clk_i, negedge resetn_i) begin : program_counter
    if (!resetn_i) pc_counter_r <= '0;
    else begin
      if (!stall_dec_i || (pc_next_sel_i == SEL_PC_BRANCH)) begin
        pc_counter_r <= pc_next_w;
      end
    end
  end

  assign imem_add_o = {pc_counter_r[13:2], 2'b00};

  // Sélectionne un NOP si fetch_nop_i est actif et l'instruction
  // imem_data_i sinon
  assign inst_w = fetch_nop_i ? 32'h00000013 : imem_data_i;

  assign opcode_w = inst_w[6:0];
  assign func3_w = inst_w[14:12];
  assign func7_w = inst_w[31:25];
  assign rs1_add_w = inst_w[19:15];
  assign rs2_add_w = inst_w[24:20];

  assign pc_plus4_w = pc_counter_r + 4;

  always_comb begin : pc_next_comb
    case (pc_next_sel_i)
      SEL_PC_PLUS_4: pc_next_w = pc_plus4_w;
      SEL_PC_JAL: pc_next_w = pc_j_target_w;
      SEL_PC_JALR: pc_next_w = pc_jr_target_w;
      SEL_PC_BRANCH: pc_next_w = pc_br_target_r;
      default: pc_next_w = pc_plus4_w;
    endcase
  end

  // Dec stage

  always_ff @(posedge clk_i or negedge resetn_i) begin : dec_stage
    if (!resetn_i) begin
      opcode_r <= '0;
      func3_dec_r <= '0;
      func7_dec_r <= '0;
      rs1_add_r <= '0;
      rs2_add_r <= '0;
      rd_add_dec_r <= '0;
      pc_counter_dec_r <= '0;
    // Si flush_dec_i est à 1, on remplace la valeur du registre par un NOP
    end else if (flush_dec_i) begin
      opcode_r <= 7'b0010011; // TODO: OPCODE POUR UN NOP, remplacer par un localparam
      func3_dec_r <= '0;
      func7_dec_r <= '0;
      rs1_add_r <= '0;
      rs2_add_r <= '0;
      rd_add_dec_r <= '0;
      pc_counter_dec_r <= '0;
    end else if (!stall_dec_i) begin
      opcode_r <= opcode_w;
      func3_dec_r <= func3_w;
      func7_dec_r <= func7_w;
      rs1_add_r <= rs1_add_w;
      rs2_add_r <= rs2_add_w;
      rd_add_dec_r <= inst_w[11:7];
      pc_counter_dec_r <= pc_counter_r;
    end
  end

  assign inst_r = {func7_dec_r, rs2_add_r, rs1_add_r, func3_dec_r, rd_add_dec_r, opcode_r};

  assign instruction_o = inst_r;

  regfile regfile_inst (
      .clk_i(clk_i),

      .we_i(reg_we_i),
      .rd_add_i(rd_add_w),
      .rs1_add_i(rs1_add_r),
      .rs2_add_i(rs2_add_r),
      .rd_data_i(wb_data_w),
      .rs1_data_o(rs1_data_w),
      .rs2_data_o(rs2_data_w)
  );

  always_comb begin : imm_generator
    case (imm_gen_sel_i)
      IMM20_UNSIGN_U: imm_w = {inst_r[31:12], 12'b0};
      IMM12_SIGEXTD_I: imm_w = {{20{inst_r[31]}}, inst_r[31:20]};
      IMM12_SIGEXTD_S: imm_w = {{20{inst_r[31]}}, {inst_r[31:25], inst_r[11:7]}};
      IMM12_SIGEXTD_SB: imm_w = {{20{inst_r[31]}}, inst_r[7], inst_r[30:25], inst_r[11:8], 1'b0};
      IMM20_UNSIGN_UJ: imm_w = {{12{inst_r[31]}}, inst_r[19:12], inst_r[20], inst_r[30:21], 1'b0};
      default: imm_w = '0;
    endcase
  end

  assign pc_j_target_w  = pc_counter_dec_r + imm_w;
  assign pc_br_target_w = pc_counter_dec_r + imm_w;
  assign pc_jr_target_w = (rs1_data_w + imm_w) & 32'hFFFF_FFFE;

  always_comb begin : alu_src1_mux_comb
    case (alu_src1_i)
      SEL_OP1_RS1: alu_op1_data_w = rs1_data_w;
      SEL_OP1_IMM: alu_op1_data_w = imm_w;
      SEL_OP1_PC: alu_op1_data_w = pc_counter_r;
      default: alu_op1_data_w = '0;
    endcase
  end

  always_comb begin : alu_src2_mux_comb
    case (alu_src2_i)
      SEL_OP2_RS2: alu_op2_data_w = rs2_data_w;
      SEL_OP2_IMM: alu_op2_data_w = imm_w;
      default: alu_op2_data_w = '0;
    endcase
  end

  // Exec stage

  always_ff @(posedge clk_i or negedge resetn_i) begin : exec_stage
    if (!resetn_i) begin
      alu_op1_data_r <= '0;
      alu_op2_data_r <= '0;
      rs2_data_r <= '0;
      func3_exec_r <= '0;
      pc_br_target_r <= '0;
      pc_counter_exec_r <= '0;
    // Si flush_exec_i est à 1, on remplace la valeur du registre par un NOP 
    end else if (flush_exec_i) begin // TODO, vérifier les valeurs
      alu_op1_data_r <= '0;
      alu_op2_data_r <= '0;
      rs2_data_r <= rs2_data_w;
      func3_exec_r <= '0;
      pc_br_target_r <= pc_br_target_w;
      pc_counter_exec_r <= pc_counter_dec_r;
    end else if (!stall_exec_i) begin
      alu_op1_data_r <= alu_op1_data_w;
      alu_op2_data_r <= alu_op2_data_w;
      rs2_data_r <= rs2_data_w;
      func3_exec_r <= func3_dec_r;
      pc_br_target_r <= pc_br_target_w;
      pc_counter_exec_r <= pc_counter_dec_r;
    end
  end

  alu alu_inst (
      .func_i(alu_control_i),
      .op1_i(alu_op1_data_r),
      .op2_i(alu_op2_data_r),
      .d_o(alu_do_w),
      .zero_o(alu_zero_o),
      .lt_o(alu_lt_o),
      .ltu_o(alu_ltu_o)
  );

  // byte and word reading accesses
  // non aligned accesses are not managed
  assign dmem_add_lsb_w = alu_do_w[1:0];

  always_comb begin : byte_enable_comb
    case (func3_exec_r[1:0])
      2'b00: begin
        unique case (dmem_add_lsb_w)
          2'b00: ble_w = 4'b0001;
          2'b01: ble_w = 4'b0010;
          2'b10: ble_w = 4'b0100;
          2'b11: ble_w = 4'b1000;
        endcase
      end
      // misaligned halfword accesses are not managed
      2'b01: begin
        unique case (dmem_add_lsb_w)
          2'b00: ble_w = 4'b0011;
          2'b01: ble_w = 4'b0011;
          2'b10: ble_w = 4'b1100;
          2'b11: ble_w = 4'b1100;
        endcase
      end
      2'b10:   ble_w = 4'b1111;
      default: ble_w = 4'b1111;
    endcase
  end

  // Mem stage

  always_ff @(posedge clk_i, negedge resetn_i) begin : mem_stage
    if (!resetn_i) begin
      dmem_add_r <= 32'b0;
      dmem_di_r <= 32'b0;
      dmem_ble_r <= 4'b0;
      pc_counter_mem_r <= 32'b0;
      func3_mem_r <= 3'b0;
    end else if (!stall_exec_i) begin
      dmem_add_r <= alu_do_w;
      dmem_di_r <= wr_shifter_di_w;
      dmem_ble_r <= ble_w;
      pc_counter_mem_r <= pc_counter_exec_r;
      func3_mem_r <= func3_exec_r;
    end
  end

  assign dmem_add_o = dmem_add_r;
  assign dmem_di_o = dmem_di_r;
  assign dmem_ble_o = dmem_ble_r;

  assign rdu_w = func3_mem_r[2];

  always_comb begin : rd_extend_comb
    if (rdu_w) begin
      rd_extend_w = 1'b0;
    end else begin
      case (dmem_ble_r)
        4'b1111: rd_extend_w = 1'b0;
        4'b0001: rd_extend_w = dmem_do_i[7];
        4'b0010: rd_extend_w = dmem_do_i[15];
        4'b0100: rd_extend_w = dmem_do_i[23];
        4'b1000: rd_extend_w = dmem_do_i[31];
        4'b0011: rd_extend_w = dmem_do_i[15];
        4'b1100: rd_extend_w = dmem_do_i[31];
        default: rd_extend_w = 1'b0;
      endcase
    end
  end

  always_comb begin : rd_shifter_comb
    case (dmem_ble_r)
      4'b1111: rd_shifter_do_w = dmem_do_i;
      4'b0001: rd_shifter_do_w = {{24{rd_extend_w}}, dmem_do_i[7:0]};
      4'b0010: rd_shifter_do_w = {{24{rd_extend_w}}, dmem_do_i[15:8]};
      4'b0100: rd_shifter_do_w = {{24{rd_extend_w}}, dmem_do_i[23:16]};
      4'b1000: rd_shifter_do_w = {{24{rd_extend_w}}, dmem_do_i[31:24]};
      4'b0011: rd_shifter_do_w = {{16{rd_extend_w}}, dmem_do_i[15:0]};
      4'b1100: rd_shifter_do_w = {{16{rd_extend_w}}, dmem_do_i[31:16]};
      default: rd_shifter_do_w = 32'b0;
    endcase
  end

  always_comb begin : wr_shifter_comb
    case (dmem_ble_r)
      4'b1111: wr_shifter_di_w = rs2_data_r;
      4'b0001: wr_shifter_di_w = {24'b0, rs2_data_r[7:0]};
      4'b0010: wr_shifter_di_w = {16'b0, rs2_data_r[7:0], 8'b0};
      4'b0100: wr_shifter_di_w = {8'b0, rs2_data_r[7:0], 16'b0};
      4'b1000: wr_shifter_di_w = {rs2_data_r[7:0], 24'b0};
      4'b0011: wr_shifter_di_w = {16'b0, rs2_data_r[15:0]};
      4'b1100: wr_shifter_di_w = {rs2_data_r[15:0], 16'b0};
      default: wr_shifter_di_w = 32'b0;
    endcase
  end

  // Write back

  always_ff @(posedge clk_i, negedge resetn_i) begin : wb_stage
    if (!resetn_i) begin
      rd_shifter_do_r <= 32'b0;
      alu_do_r <= 32'b0;
      pc_counter_wb_r <= 32'h0;
    end else if (!stall_exec_i) begin
      rd_shifter_do_r <= rd_shifter_do_w;
      alu_do_r <= dmem_add_r;
      pc_counter_wb_r <= pc_counter_mem_r;
    end
  end

  assign rd_add_w = rd_add_i;

  always_comb begin : wb_mux
    case (wb_sel_i)
      SEL_WB_ALU: wb_data_w = alu_do_r;
      SEL_WB_MEM: wb_data_w = rd_shifter_do_r;
      SEL_WB_PC_PLUS_4: wb_data_w = pc_counter_wb_r + 4;
      default: wb_data_w = '0;
    endcase
  end

endmodule
