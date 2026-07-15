module boot_loader #(
    parameter int XLEN  = 32,
    parameter int DEPTH = 64
) (
    input  logic            clk,
    input  logic            rst_n,
    input  logic            rx_valid,
    input  logic [     7:0] rx_data,
    output logic            we,
    output logic [XLEN-1:0] waddr,
    output logic [XLEN-1:0] wdata,
    output logic            loading
);

  typedef enum logic [1:0] {
    COUNT,
    LOAD,
    DONE
  } state_t;

  state_t state, next_state;
  logic [1:0] cnt_byte;
  logic [$clog2(DEPTH)+1:0] cnt_word;
  logic [$clog2(DEPTH)+1:0] max_word;
  logic [XLEN-1:0] acc;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= COUNT;
      cnt_byte <= '0;
      cnt_word <= '0;
    end else begin
      state <= next_state;

      if (rx_valid) begin
        case (state)
          COUNT: max_word <= rx_data;
          LOAD: begin
            if (cnt_byte == 2'd3) cnt_word <= cnt_word + 1'd1;
            cnt_byte <= cnt_byte + 2'd1;
            acc <= {rx_data, acc[XLEN-1:$bits(rx_data)]};
          end
          DONE: ;
          default: ;
        endcase
      end
    end
  end

  always_comb begin
    next_state = state;
    case (state)
      COUNT: if (rx_valid) next_state = LOAD;
      LOAD: if (cnt_word == max_word) next_state = DONE;
      DONE: ; // Terminates
      default: ;
    endcase
  end

  assign we      = (rx_valid && (cnt_byte == 2'd3));
  assign waddr   = XLEN'(cnt_word) << 2;
  assign wdata   = {rx_data, acc[XLEN-1:$bits(rx_data)]};
  assign loading = state != DONE;

endmodule
