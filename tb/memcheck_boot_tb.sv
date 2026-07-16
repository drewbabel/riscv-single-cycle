module memcheck_boot_tb ();
  localparam int DEPTH = 16384;

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
    localparam int ClksPerBit = (100_000_000 + 28_800 / 2) / 28_800;
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
  always @(posedge clk) if (led > max_led && led != 16'h5555) max_led <= led;

  initial begin
    for (int k = 0; k < DEPTH; k++) img[k] = 32'hDEADBEEF;
    $readmemh("tests/memcheck.hex", img);
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
    repeat (4_000_000) @(posedge clk);
    if (led === 16'hFFFF) $display("PASS: 2000-word store/verify, led=%04x", led);
    else $fatal(1, "FAIL: led=%04x (expected FFFF)", led);
    $finish;
  end
endmodule
