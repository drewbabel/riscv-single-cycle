module dmem #(
    parameter int XLEN = 32,
    parameter int DEPTH = 64,
    localparam int AddrWidth = $clog2(DEPTH)
) (
    input  logic            clk,
    input  logic            we,
    input  logic [XLEN-1:0] addr,
    input  logic [XLEN-1:0] wdata,
    output logic [XLEN-1:0] rdata
);

  logic [XLEN-1:0] mem[DEPTH];

  assign rdata = mem[addr[AddrWidth+1:2]];

  always_ff @(posedge clk) begin
    if (we) mem[addr[AddrWidth+1:2]] <= wdata;
  end

endmodule
