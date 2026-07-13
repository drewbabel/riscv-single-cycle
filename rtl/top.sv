module top #(
    parameter int XLEN  = 32,
    parameter int DEPTH = 64
) (
    input  logic            clk,
    input  logic            rst_n,
    output logic [XLEN-1:0] pc,
    output logic [XLEN-1:0] alu_result,
    output logic [XLEN-1:0] write_data,
    output logic            mem_write
);

  logic [XLEN-1:0] instr;
  logic [XLEN-1:0] read_data;
  logic      [3:0] store_wstrb;
  logic [XLEN-1:0] store_data;

  riscv_single #(
      .XLEN(XLEN)
  ) riscv_single_inst (
      .clk        (clk),
      .rst_n      (rst_n),
      .instr      (instr),
      .read_data  (read_data),
      .pc         (pc),
      .mem_write  (mem_write),
      .alu_result (alu_result),
      .write_data (write_data),
      .store_wstrb(store_wstrb),
      .store_data (store_data)
  );

  imem #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) imem_inst (
      .addr (pc),
      .instr(instr)
  );

  dmem #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) dmem_inst (
      .clk(clk),
      .wstrb(store_wstrb),
      .addr(alu_result),
      .wdata(store_data),
      .rdata(read_data)
  );

endmodule
