module board_top #(
    parameter int XLEN  = 32,
    parameter int DEPTH = 64
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] sw,
    output logic [15:0] led,
    input  logic        uart_rx,
    output logic        uart_tx
);

  localparam logic [7:0] ClintTag = 8'h02;
  localparam logic [7:0] GpioTag = 8'h03;

  logic            rst_n;
  logic [XLEN-1:0] instr;
  logic [XLEN-1:0] pc;
  logic [XLEN-1:0] alu_result;
  logic [XLEN-1:0] write_data;
  logic            mem_write;
  logic [     3:0] store_wstrb;
  logic [XLEN-1:0] store_data;
  logic            timer_irq;

  logic [XLEN-1:0] read_data;
  logic [XLEN-1:0] dmem_rdata;
  logic [XLEN-1:0] clint_rdata;
  logic [XLEN-1:0] gpio_rdata;
  logic            clint_sel;
  logic            gpio_sel;
  logic [    15:0] led_reg;

  logic            core_rst_n;
  logic            loading;
  logic            boot_we;
  logic [XLEN-1:0] boot_waddr;
  logic [XLEN-1:0] boot_wdata;
  logic [     7:0] rx_byte;
  logic            rx_valid_w;

  // Divided core clock
  logic core_clk;
`ifdef FPGA_DIVCLK
  logic [2:0] clk_div = '0;
  always_ff @(posedge clk) clk_div <= clk_div + 1'b1;
  BUFG core_bufg (
      .I(clk_div[2]),
      .O(core_clk)
  );
  // Power-on reset
  logic [3:0] por = '0;
  always_ff @(posedge core_clk) if (!por[3]) por <= por + 1'b1;
  assign rst_n = por[3] & ~rst;
`else
  assign core_clk = clk;
  assign rst_n = ~rst;
`endif

  // Held in reset during load
  assign core_rst_n = rst_n & ~loading;

  assign clint_sel  = alu_result[31:24] == ClintTag;
  assign gpio_sel   = alu_result[31:24] == GpioTag;
  assign read_data  = gpio_sel ? gpio_rdata : clint_sel ? clint_rdata : dmem_rdata;

  // LEDs +0, switches +4
  assign gpio_rdata = alu_result[2] ? {16'b0, sw} : {16'b0, led_reg};
  assign led        = led_reg;
  always_ff @(posedge core_clk) begin
    if (!core_rst_n) led_reg <= '0;
    else if (gpio_sel && !alu_result[2] && |store_wstrb) led_reg <= store_data[15:0];
  end

  assign uart_tx = 1'b1;  // Idle high

  uart_rx #(
      .CLK_FREQ_HZ(12_500_000)
  ) uart_rx_inst (
      .clk      (core_clk),
      .rst_n    (rst_n),
      .rx_serial(uart_rx),
      .rx_data  (rx_byte),
      .rx_valid (rx_valid_w),
      .rx_error ()
  );

  boot_loader #(
      .XLEN(XLEN)
  ) boot_loader_inst (
      .clk     (core_clk),
      .rst_n   (rst_n),
      .rx_valid(rx_valid_w),
      .rx_data (rx_byte),
      .we      (boot_we),
      .waddr   (boot_waddr),
      .wdata   (boot_wdata),
      .loading (loading)
  );

  riscv_single #(
      .XLEN(XLEN)
  ) riscv_single_inst (
      .clk        (core_clk),
      .rst_n      (core_rst_n),
      .instr      (instr),
      .read_data  (read_data),
      .timer_irq  (timer_irq),
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
      .clk  (core_clk),
      .we   (boot_we),
      .waddr(boot_waddr),
      .wdata(boot_wdata),
      .addr (pc),
      .instr(instr)
  );

  dmem #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) dmem_inst (
      .clk  (core_clk),
      .wstrb((clint_sel || gpio_sel) ? 4'b0 : store_wstrb),
      .addr (alu_result),
      .wdata(store_data),
      .rdata(dmem_rdata)
  );

  clint #(
      .XLEN(XLEN)
  ) clint_inst (
      .clk      (core_clk),
      .rst_n    (core_rst_n),
      .sel      (clint_sel),
      .wstrb    (store_wstrb),
      .addr     (alu_result),
      .wdata    (store_data),
      .rdata    (clint_rdata),
      .timer_irq(timer_irq)
  );

endmodule
