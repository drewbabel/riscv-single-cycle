module pc #(
    parameter int XLEN = 32,
    parameter logic [XLEN-1:0] RESET_ADDR = '0
) (
    input  logic            clk,
    input  logic            rst_n,
    input  logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc_q
);

  always_ff @(posedge clk) begin
    if (!rst_n) pc_q <= RESET_ADDR;
    else pc_q <= pc_next;
  end

endmodule
