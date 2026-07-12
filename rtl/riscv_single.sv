module riscv_single
  import alu_pkg::*;
#(
    parameter int XLEN = 32
) (
    input  logic            clk,
    input  logic            rst_n,
    input  logic [XLEN-1:0] instr,
    input  logic [XLEN-1:0] read_data,
    output logic [XLEN-1:0] pc,
    output logic            mem_write,
    output logic [XLEN-1:0] alu_result,
    output logic [XLEN-1:0] write_data
);

  // control_unit to datapath wiring
  logic                   reg_write;
  logic             [2:0] imm_src;
  logic             [1:0] alu_a_src;
  logic                   alu_src;
  logic             [1:0] result_src;
  alu_pkg::alu_op_e       alu_ctrl;
  logic                   pc_src;
  logic                   pc_target_src;
  logic zero, lt, ltu;

  control_unit control_unit_inst (
      .op           (instr[6:0]),
      .funct3       (instr[14:12]),
      .funct7b5     (instr[30]),
      .zero         (zero),
      .lt           (lt),
      .ltu          (ltu),
      .reg_write    (reg_write),
      .imm_src      (imm_src),
      .alu_a_src    (alu_a_src),
      .pc_target_src(pc_target_src),
      .alu_src      (alu_src),
      .mem_write    (mem_write),
      .result_src   (result_src),
      .pc_src       (pc_src),
      .alu_ctrl     (alu_ctrl)
  );

  datapath #(
      .XLEN(XLEN)
  ) datapath_inst (
      .clk          (clk),
      .rst_n        (rst_n),
      .reg_write    (reg_write),
      .imm_src      (imm_src),
      .alu_a_src    (alu_a_src),
      .alu_src      (alu_src),
      .result_src   (result_src),
      .alu_ctrl     (alu_ctrl),
      .pc_src       (pc_src),
      .pc_target_src(pc_target_src),
      .instr        (instr),
      .read_data    (read_data),
      .pc           (pc),
      .alu_result   (alu_result),
      .write_data   (write_data),
      .zero         (zero),
      .lt           (lt),
      .ltu          (ltu)
  );

endmodule
