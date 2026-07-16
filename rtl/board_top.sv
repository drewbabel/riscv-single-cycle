module board_top #(
    parameter int XLEN  = 32,
    parameter int DEPTH = 16384
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
  logic [XLEN-1:0] instr_raw;
  logic [XLEN-1:0] pc;
  logic [XLEN-1:0] alu_result;
  logic [XLEN-1:0] write_data;
  logic            mem_write;
  logic [     3:0] store_wstrb;
  logic [XLEN-1:0] store_data;
  logic            timer_irq;

  logic [XLEN-1:0] read_data;
  logic [XLEN-1:0] mem_rdata;
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

  logic [XLEN-1:0] mem_daddr;
  logic [XLEN-1:0] mem_wdata;
  logic [     3:0] mem_wstrb;

  logic [XLEN-1:0] rt_addr_q;
  logic [XLEN-1:0] rt_data_q;
  logic [     3:0] rt_strb_q;

  // Core-enable divider
  logic [     4:0] div = '0;
  logic            core_en;
  always_ff @(posedge clk) div <= div + 1'b1;
  assign core_en = (div == 5'd0);

  // Power-on reset
  logic [3:0] por = '0;
  always_ff @(posedge clk) if (core_en && !por[3]) por <= por + 1'b1;
  assign rst_n      = por[3] & ~rst;

  // Load holds reset
  assign core_rst_n = rst_n & ~loading;

  assign instr      = instr_raw;
  assign clint_sel  = alu_result[31:24] == ClintTag;
  assign gpio_sel   = alu_result[31:24] == GpioTag;
  assign read_data  = gpio_sel ? gpio_rdata : clint_sel ? clint_rdata : mem_rdata;

  // GPIO read mux
  assign gpio_rdata = alu_result[2] ? {16'b0, sw} : {16'b0, led_reg};
  assign led        = loading ? 16'h5555 : led_reg;
  always_ff @(posedge clk) begin
    if (!core_rst_n) led_reg <= '0;
    else if (core_en && gpio_sel && !alu_result[2] && |store_wstrb) led_reg <= store_data[15:0];
  end

  assign uart_tx = 1'b1;  // Idle high

  // Registered store path
  always_ff @(posedge clk) begin
    rt_addr_q <= alu_result;
    rt_data_q <= store_data;
    rt_strb_q <= (clint_sel || gpio_sel) ? 4'b0 : store_wstrb;
  end

  // Boot write mux
  assign mem_daddr = loading ? boot_waddr : rt_addr_q;
  assign mem_wdata = loading ? boot_wdata : rt_data_q;
  assign mem_wstrb = loading ? (boot_we ? 4'hF : 4'b0) : rt_strb_q;

  uart_rx #(
      .CLK_FREQ_HZ(3_125_000),
      .BAUD_RATE  (28_800)
  ) uart_rx_inst (
      .clk      (clk),
      .core_en  (core_en),
      .rst_n    (rst_n),
      .rx_serial(uart_rx),
      .rx_data  (rx_byte),
      .rx_valid (rx_valid_w),
      .rx_error ()
  );

  boot_loader #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) boot_loader_inst (
      .clk     (clk),
      .core_en (core_en),
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
      .clk        (clk),
      .core_en    (core_en),
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

  // Split fetch data mem
  mem #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) imem_inst (
      .clk    (clk),
      .core_en(core_en),
      .iaddr  (pc),
      .instr  (instr_raw),
      .wstrb  (loading ? (boot_we ? 4'hF : 4'b0) : 4'b0),
      .daddr  (boot_waddr),
      .wdata  (boot_wdata),
      .rdata  ()
  );

  mem #(
      .XLEN (XLEN),
      .DEPTH(DEPTH)
  ) dmem_inst (
      .clk    (clk),
      .core_en(core_en),
      .iaddr  ('0),
      .instr  (),
      .wstrb  (mem_wstrb),
      .daddr  (mem_daddr),
      .wdata  (mem_wdata),
      .rdata  (mem_rdata)
  );

  clint #(
      .XLEN(XLEN)
  ) clint_inst (
      .clk      (clk),
      .core_en  (core_en),
      .rst_n    (core_rst_n),
      .sel      (clint_sel),
      .wstrb    (store_wstrb),
      .addr     (alu_result),
      .wdata    (store_data),
      .rdata    (clint_rdata),
      .timer_irq(timer_irq)
  );

endmodule
