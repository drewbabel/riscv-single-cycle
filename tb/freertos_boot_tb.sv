module freertos_boot_tb ();
  localparam int DEPTH = 16384;
  localparam int FastClkHz = 100_000_000;
  localparam int BaudRate = 28_800;
  localparam int ClksPerBit = (FastClkHz + BaudRate / 2) / BaudRate;

  logic clk = 0, rst;
  logic [15:0] sw, led;
  logic uart_rx = 1, uart_tx;
  logic [31:0] img[DEPTH];

  always #5 clk = ~clk;

  board_top #(
      .DEPTH(DEPTH)
  ) dut (
      .clk(clk),
      .rst(rst),
      .sw(sw),
      .led(led),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx)
  );

  task automatic send_byte(input logic [7:0] b);
    uart_rx = 0;
    repeat (ClksPerBit) @(posedge clk);
    for (int i = 0; i < 8; i++) begin
      uart_rx = b[i];
      repeat (ClksPerBit) @(posedge clk);
    end
    uart_rx = 1;
    repeat (ClksPerBit) @(posedge clk);
  endtask

  logic [15:0] max_led = 0;
  always @(posedge clk) if (led > max_led) max_led <= led;

  initial begin
    for (int k = 0; k < DEPTH; k++) img[k] = 32'hDEADBEEF;
    $readmemh("sw/freertos/freertos.hex", img);
    for (int k = 0; k < DEPTH; k++) begin
      dut.imem_inst.g_lane[0].bmem[k] = img[k][7:0];
      dut.imem_inst.g_lane[1].bmem[k] = img[k][15:8];
      dut.imem_inst.g_lane[2].bmem[k] = img[k][23:16];
      dut.imem_inst.g_lane[3].bmem[k] = img[k][31:24];
      dut.dmem_inst.g_lane[0].bmem[k] = img[k][7:0];
      dut.dmem_inst.g_lane[1].bmem[k] = img[k][15:8];
      dut.dmem_inst.g_lane[2].bmem[k] = img[k][23:16];
      dut.dmem_inst.g_lane[3].bmem[k] = img[k][31:24];
    end
    rst = 1;
    sw  = 0;
    repeat (2) @(posedge clk);
    rst = 0;
    repeat (2000) @(posedge clk);
    repeat (4) send_byte(8'd0);
    repeat (5_000_000) @(posedge clk);
    if (max_led === 16'h8301) $display("PASS: FreeRTOS boots, both tasks toggle");
    else $fatal(1, "FAIL: max_led=%04x (expected 8301)", max_led);
    $finish;
  end
endmodule
