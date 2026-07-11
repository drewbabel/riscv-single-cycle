module imem #(
    parameter int XLEN = 32,
    parameter int DEPTH = 64,
    localparam int AddrWidth = $clog2(DEPTH)
) (
    input  logic [XLEN-1:0] addr,
    output logic [XLEN-1:0] instr
);

  logic [XLEN-1:0] mem[DEPTH];

  // 2 bits = divide by 4
  assign instr = mem[addr[AddrWidth+1:2]];

endmodule
