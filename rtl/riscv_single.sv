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
    output logic [XLEN-1:0] write_data,
    output logic      [3:0] store_wstrb,
    output logic [XLEN-1:0] store_data
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
  logic [XLEN-1:0] load_data;
  logic      [7:0] ld_byte;
  logic     [15:0] ld_half;

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
      .read_data    (load_data),
      .pc           (pc),
      .alu_result   (alu_result),
      .write_data   (write_data),
      .zero         (zero),
      .lt           (lt),
      .ltu          (ltu)
  );

  always_comb begin
    ld_byte = read_data[{alu_result[1:0], 3'b000} +: 8];
    ld_half = read_data[{alu_result[1], 4'b0000} +: 16];
    case (instr[14:12])
      3'b000:  load_data = {{24{ld_byte[7]}}, ld_byte};    // lb
      3'b100:  load_data = {24'b0, ld_byte};               // lbu
      3'b001:  load_data = {{16{ld_half[15]}}, ld_half};   // lh
      3'b101:  load_data = {16'b0, ld_half};               // lhu
      default: load_data = read_data;                      // lw
    endcase
  end

  // Replicate rs2, strobe picks the lane
  always_comb begin
    store_data  = write_data;
    store_wstrb = 4'h0;
    if (mem_write) begin
      case (instr[14:12])
        3'b000: begin  // sb
          store_data  = {4{write_data[7:0]}};
          store_wstrb = 4'b0001 << alu_result[1:0];
        end
        3'b001: begin  // sh
          store_data  = {2{write_data[15:0]}};
          store_wstrb = 4'b0011 << alu_result[1:0];
        end
        3'b010: begin  // sw
          store_data  = write_data;
          store_wstrb = 4'b1111;
        end
        default: ;
      endcase
    end
  end

endmodule
