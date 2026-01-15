//                              -*- Mode: Verilog -*-
// Filename        : RV32i_monocycle_controlpath.sv
// Description     : control path
// Author          : Michel Agoyan
// Created On      : Mon Aug 19 14:06:29 2024
// Last Modified By: michel agoyan
// Last Modified On: Mon Aug 19 14:06:29 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

module RV32i_controlpath (
    input  logic        clk_i,
    input  logic        resetn_i,
    // Fetch stage
    output logic        fetch_nop_o, // Ce signal permet de fetch dans l'étage Fetch du
                                     // datapath une instruction NOP à la place de 
                                     // l'instruction qui à l'adresse mémoire normalement 
                                     // sélectionnée.
    // Dec stage
    input  logic        stall_dec_i,
    input  logic [31:0] instruction_i,
    output logic [ 2:0] pc_next_sel_o,
    output logic [ 1:0] alu_src1_o,
    output logic        alu_src2_o,
    output logic [ 2:0] imm_gen_sel_o,
    output logic        stall_o,
    // Exec stage
    input  logic        stall_exec_i,
    output logic [ 3:0] alu_control_o,
    input  logic        alu_zero_i,
    input  logic        alu_lt_i,
    input  logic        alu_ltu_i,
    output logic        branch_taken_o, // Le signal qui dit au datapath qu'une branche
                                        // a été prise et qu'il faut flush DEC et EXEC
    // Mem stage
    output logic        dmem_we_o,
    output logic        dmem_re_o,
    // Write back

    output logic [4:0] rd_add_o,

    output logic [1:0] wb_sel_o,
    output logic       reg_we_o
);

  import RV32i_pkg::*;
  // Dec stage

  logic [4:0] rs1_dec_w, rs2_dec_w;

  logic [31:0] inst_dec_w;
  logic [6:0] opcode_dec_w;

  // Les rd_we_XXX_w sont à 1 lorsqu'une instruction dans XXX utilise rd
  // Les hazard_rsX sont à 1 lorsqu'il y a dépendance de donnée sur le registre rsX.
  // Les rsX_re_dec_w sont à 1 lorsque l'instruction dans le stage DEC utilise rsX
  logic rd_we_exec_w, rd_we_mem_w, rd_we_wb_w;
  logic hazard_rs1, hazard_rs2;
  logic rs1_re_dec_w, rs2_re_dec_w;

  // Exec stage
  logic [31:0] inst_exec_r;

  logic [4:0] rd_add_exec_w;

  logic [6:0] opcode_exec_w;
  logic [6:0] func7_exec_w;
  logic [2:0] func3_exec_w;
  logic branch_taken_w;
  // Mem stage
  logic [31:0] inst_mem_r;

  logic [4:0] rd_add_mem_w;

  logic [6:0] opcode_mem_w;
  // Write back
  logic [31:0] inst_wb_r;

  logic [4:0] rd_add_wb_w;

  logic [6:0] opcode_wb_w;

  // Fetch stage
  
  // Si l'opcode de l'opération dans l'étage de décode dans le datapath est celui d'une instruction J.
  // (opcode_dec_w provient de instruction_i qui est l'instruction actuellement dans l'étage décode du datapath)
  assign fetch_nop_o = opcode_dec_w == 7'b1101111;

  // Dec stage

  // Fonction qui retourne 1 si l'instruction utilise rd, 0 sinon.
  function logic rd_used(input logic [31:0] inst);
    // Cas spécial pour les instructions qui utilisent R0.
    // On DOIT les rendre non-bloquants sinon ils peuvent
    // créer un stall infini.
    //
    //             RD      !=      R0    &&  OPCODE[5:3] != 3'b100
    rd_used = ( inst[11:7] != 5'b00000 ) && (  inst[5:3] != 3'b100 );  
  endfunction

  assign rs1_dec_w = instruction_i[19:15];
  assign rs2_dec_w = instruction_i[24:20];

  // Pas besoin de prendre en compte branch_taken_w ici car instruction_i est directement l'instruction dans le registre de l'étage DEC du datapath, il nous suffit de changer le contenu de DEC dans le datapath
  assign inst_dec_w = stall_dec_i ? 32'h00000013 : instruction_i;

  assign opcode_dec_w = instruction_i[6:0];

  always_comb begin : pc_next_sel_comb
    if (branch_taken_w) begin
      pc_next_sel_o = SEL_PC_BRANCH;
    end else begin
      case (opcode_dec_w)
        RV32I_I_INSTR_JALR: pc_next_sel_o = SEL_PC_JALR;
        RV32I_J_INSTR: pc_next_sel_o = SEL_PC_JAL;
        default: pc_next_sel_o = SEL_PC_PLUS_4;
      endcase
    end
  end

  always_comb begin : alu_src1_comb
    case (opcode_dec_w)
      RV32I_U_INSTR_LUI: alu_src1_o = SEL_OP1_IMM;
      RV32I_U_INSTR_AUIPC: alu_src1_o = SEL_OP1_PC;
      default: alu_src1_o = SEL_OP1_RS1;
    endcase
  end

  always_comb begin : alu_src2_comb
    case (opcode_dec_w)
      RV32I_I_INSTR_OPER: alu_src2_o = SEL_OP2_IMM;
      RV32I_I_INSTR_LOAD: alu_src2_o = SEL_OP2_IMM;
      RV32I_U_INSTR_AUIPC: alu_src2_o = SEL_OP2_IMM;
      RV32I_S_INSTR: alu_src2_o = SEL_OP2_IMM;
      default: alu_src2_o = SEL_OP2_RS2;
    endcase
  end

  always_comb begin : imm_gen_sel_comb
    case (opcode_dec_w)
      RV32I_I_INSTR_OPER: imm_gen_sel_o = IMM12_SIGEXTD_I;
      RV32I_I_INSTR_LOAD: imm_gen_sel_o = IMM12_SIGEXTD_I;
      RV32I_I_INSTR_JALR: imm_gen_sel_o = IMM12_SIGEXTD_I;
      RV32I_U_INSTR_LUI: imm_gen_sel_o = IMM20_UNSIGN_U;
      RV32I_U_INSTR_AUIPC: imm_gen_sel_o = IMM20_UNSIGN_U;
      RV32I_B_INSTR: imm_gen_sel_o = IMM12_SIGEXTD_SB;
      RV32I_S_INSTR: imm_gen_sel_o = IMM12_SIGEXTD_S;
      RV32I_J_INSTR: imm_gen_sel_o = IMM20_UNSIGN_UJ;
      default: imm_gen_sel_o = IMM12_SIGEXTD_I;
    endcase
  end

  // On applique la fonction rd_used aux signaux rd des différents
  // stages de la pipeline.
  assign rd_we_exec_w = rd_used(inst_exec_r);
  assign rd_we_mem_w = rd_used(inst_mem_r);
  assign rd_we_wb_w = rd_used(inst_wb_r);

  // Les opcodes qui utilisent rs1 ont le bit 2^2 à 0, les autres à 1
  // Les opcodes qui utilisent rs2 ont le bit 2^2 à 0 et le 2^5 à 1, ce qui n'est pas le cas des autres opcodes.
  assign rs1_re_dec_w = !opcode_dec_w[2];
  assign rs2_re_dec_w = !opcode_dec_w[2] && opcode_dec_w[5];

  // Il y a une dépendance de donnée sur rsX lorsque:
  // - rd est utilisé dans le stage EXEC, MEM ou WB
  // - rsX est utilisé dans le stage DEC
  // - rsX correspond à rd dans le stage EXEC, MEM ou WB
  // Il y a une dépendance de donnée sur rsX lorsque:
  // - rsX est utilisé dans le stage DEC
  // - rd est utilisé dans le stage EXEC, MEM ou WB
  // - rsX correspond à rd dans le stage EXEC, MEM ou WB
  assign hazard_rs1 =
      (rs1_re_dec_w)
    && (   
           (rd_we_exec_w && (rs1_dec_w == rd_add_exec_w)) 
        || (rd_we_mem_w  && (rs1_dec_w == rd_add_mem_w)) 
        || (rd_we_wb_w   && (rs1_dec_w == rd_add_wb_w))
       );
  assign hazard_rs2 = 
      (rs2_re_dec_w)
    && (
           (rd_we_exec_w && (rs2_dec_w == rd_add_exec_w)) 
        || (rd_we_mem_w && (rs2_dec_w == rd_add_mem_w)) 
        || (rd_we_wb_w && (rs2_dec_w == rd_add_wb_w))
       );

  // On stall si on a une dépendance de données sur rs1 ou sur rs2.
  // Cependant, on ne doit pas stall si on prends une branche car cela bloque le PC et empêche la branche d'être prise.
  assign stall_o = (hazard_rs1 || hazard_rs2) && !branch_taken_w;

  // Exec stage

  always_ff @(posedge clk_i or negedge resetn_i) begin : exec_stage
    if (!resetn_i) begin
      inst_exec_r <= 32'h0;
    // Si on prends une branche, on doit flush l'étage EXEC,
    // On insère donc un NOP
    end else if (branch_taken_w) begin 
      inst_exec_r <= 32'h00000013; // TODO: remplacer 32'h00000013 par NOP en localparam
    end else if (!stall_exec_i) begin
      inst_exec_r <= inst_dec_w;
    end
  end

  assign rd_add_exec_w = inst_exec_r[11:7];

  assign opcode_exec_w = inst_exec_r[6:0];
  assign func7_exec_w  = inst_exec_r[31:25];
  assign func3_exec_w  = inst_exec_r[14:12];

  always_comb begin : alu_control_comb
    alu_control_o = ALU_X;
    case (opcode_exec_w)
      RV32I_R_INSTR: begin
        case ({
          func7_exec_w, func3_exec_w
        })
          {RV32I_FUNCT7_ADD, RV32I_FUNCT3_ADD} : alu_control_o = ALU_ADD;
          {RV32I_FUNCT7_SUB, RV32I_FUNCT3_SUB} : alu_control_o = ALU_SUB;
          {RV32I_FUNCT7_SLT, RV32I_FUNCT3_SLT} : alu_control_o = ALU_SLT;
          {RV32I_FUNCT7_SLTU, RV32I_FUNCT3_SLTU} : alu_control_o = ALU_SLTU;
          {RV32I_FUNCT7_XOR, RV32I_FUNCT3_XOR} : alu_control_o = ALU_XOR;
          {RV32I_FUNCT7_OR, RV32I_FUNCT3_OR} : alu_control_o = ALU_OR;
          {RV32I_FUNCT7_AND, RV32I_FUNCT3_AND} : alu_control_o = ALU_AND;
          {RV32I_FUNCT7_SLL, RV32I_FUNCT3_SLL} : alu_control_o = ALU_SLLV;
          {RV32I_FUNCT7_SRL, RV32I_FUNCT3_SR} : alu_control_o = ALU_SRLV;
          {RV32I_FUNCT7_SRA, RV32I_FUNCT3_SR} : alu_control_o = ALU_SRAV;
          default: alu_control_o = ALU_X;
        endcase
      end
      RV32I_I_INSTR_OPER: begin
        case (func3_exec_w)
          RV32I_FUNCT3_ADD: alu_control_o = ALU_ADD;
          RV32I_FUNCT3_XOR: alu_control_o = ALU_XOR;
          RV32I_FUNCT3_SLT: alu_control_o = ALU_SLT;
          RV32I_FUNCT3_SLTU: alu_control_o = ALU_SLTU;
          RV32I_FUNCT3_OR: alu_control_o = ALU_OR;
          RV32I_FUNCT3_AND: alu_control_o = ALU_AND;
          RV32I_FUNCT3_SLL: alu_control_o = ALU_SLLV;
          RV32I_FUNCT3_SR: begin
            if (func7_exec_w == RV32I_FUNCT7_SRL) alu_control_o = ALU_SRLV;
            else if (func7_exec_w == RV32I_FUNCT7_SRA) alu_control_o = ALU_SRAV;
            else alu_control_o = ALU_SRAV;
          end
          default: alu_control_o = ALU_X;
        endcase
      end
      RV32I_U_INSTR_LUI: alu_control_o = ALU_COPY_RS1;
      RV32I_B_INSTR: alu_control_o = ALU_SUB;
      RV32I_U_INSTR_AUIPC: alu_control_o = ALU_ADD;
      RV32I_I_INSTR_LOAD: alu_control_o = ALU_ADD;
      RV32I_S_INSTR: alu_control_o = ALU_ADD;
      RV32I_I_INSTR_LOAD: alu_control_o = ALU_ADD;
      RV32I_I_INSTR_JALR: alu_control_o = ALU_ADD;
      default: alu_control_o = ALU_X;
    endcase
  end

  always_comb begin : branch_taken_comb
    case (opcode_exec_w)
      RV32I_B_INSTR: begin
        case (func3_exec_w)
          RV32I_FUNCT3_BEQ: branch_taken_w = alu_zero_i;
          RV32I_FUNCT3_BNE: branch_taken_w = !alu_zero_i;
          RV32I_FUNCT3_BLT: branch_taken_w = alu_lt_i;
          RV32I_FUNCT3_BGE: branch_taken_w = !alu_lt_i;
          RV32I_FUNCT3_BLTU: branch_taken_w = alu_ltu_i;
          RV32I_FUNCT3_BGEU: branch_taken_w = !alu_ltu_i;
          default: branch_taken_w = 1'b0;
        endcase
      end
      default: branch_taken_w = 1'b0;
    endcase
  end

  // branch_taken_o doit évidemment avoir la même valeur que branch_taken_w
  assign branch_taken_o = branch_taken_w;

  // Mem stage

  always_ff @(posedge clk_i or negedge resetn_i) begin : mem_stage
    if (!resetn_i) begin
      inst_mem_r <= 32'h0;
    end else if (!stall_exec_i) begin
      inst_mem_r <= inst_exec_r;
    end
  end

  assign rd_add_mem_w = inst_mem_r[11:7];

  assign opcode_mem_w = inst_mem_r[6:0];

  always_comb begin : mem_we_comb
    case (opcode_mem_w)
      RV32I_S_INSTR: dmem_we_o = WE_1;
      default: dmem_we_o = WE_0;
    endcase
  end

  always_comb begin : mem_re_comb
    case (opcode_mem_w)
      RV32I_I_INSTR_LOAD: dmem_re_o = RE_1;
      default: dmem_re_o = RE_0;
    endcase
  end

  // Write back

  always_ff @(posedge clk_i or negedge resetn_i) begin : wb_stage
    if (!resetn_i) inst_wb_r <= 32'h0;
    else inst_wb_r <= stall_exec_i ? 32'h00000013 : inst_mem_r;
  end

  assign rd_add_wb_w = inst_wb_r[11:7];
  assign rd_add_o = rd_add_wb_w;

  assign opcode_wb_w = inst_wb_r[6:0];

  always_comb begin : wb_sel_comb
    case (opcode_wb_w)
      RV32I_I_INSTR_LOAD: wb_sel_o = SEL_WB_MEM;
      RV32I_I_INSTR_JALR: wb_sel_o = SEL_WB_PC_PLUS_4;
      RV32I_J_INSTR: wb_sel_o = SEL_WB_PC_PLUS_4;
      default: wb_sel_o = SEL_WB_ALU;
    endcase
  end

  always_comb begin : reg_we_comb
    case (opcode_wb_w)
      RV32I_B_INSTR: reg_we_o = WE_0;
      RV32I_I_INSTR_JALR: reg_we_o = WE_1;
      RV32I_J_INSTR: reg_we_o = WE_1;
      RV32I_S_INSTR: reg_we_o = WE_0;
      default: reg_we_o = WE_1;
    endcase
  end

endmodule
