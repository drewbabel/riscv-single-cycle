module board_top_tb ();

  int checks = 0;
  int errors = 0;

  logic        clk = 1'b0;
  logic        rst;
  logic [15:0] sw;
  logic [15:0] led;
  logic        uart_rx = 1'b1;
  logic        uart_tx;

  // uart_rx bit period
  localparam int ClksPerBit = 16 * (((12_500_000 + 115_200 / 2) / 115_200 + 8) / 16);

  always #5 clk = ~clk;

  board_top dut (
      .clk    (clk),
      .rst    (rst),
      .sw     (sw),
      .led    (led),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx)
  );

  task automatic do_reset();
    rst = 1;
    sw  = 16'h0;
    uart_rx = 1'b1;
    repeat (2) @(posedge clk);
    rst = 0;
  endtask  // Automatic

  task automatic send_byte(input logic [7:0] b);
    uart_rx = 1'b0;
    repeat (ClksPerBit) @(posedge clk);
    for (int i = 0; i < 8; i++) begin
      uart_rx = b[i];
      repeat (ClksPerBit) @(posedge clk);
    end
    uart_rx = 1'b1;
    repeat (ClksPerBit) @(posedge clk);
  endtask  // Automatic

  task automatic check(input string name, input logic [15:0] got, input logic [15:0] exp);
    checks++;
    if (got !== exp) begin
      $error("%s got %04x exp %04x", name, got, exp);
      errors++;
    end
  endtask  // Automatic

  task automatic verdict();
    if (errors == 0) $display("PASS: %0d checks, %0d mismatches", checks, errors);
    else $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    $finish;
  endtask  // Automatic

  // gpio_test writes 0xABCD to LEDs
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, board_top_tb);
    do_reset();

    send_byte(8'd5);
    send_byte(8'hB7); send_byte(8'h00); send_byte(8'h00); send_byte(8'h03);
    send_byte(8'h37); send_byte(8'hB1); send_byte(8'h00); send_byte(8'h00);
    send_byte(8'h13); send_byte(8'h01); send_byte(8'hD1); send_byte(8'hBC);
    send_byte(8'h23); send_byte(8'hA0); send_byte(8'h20); send_byte(8'h00);
    send_byte(8'h6F); send_byte(8'h00); send_byte(8'h00); send_byte(8'h00);

    wait (dut.loading == 1'b0);
    repeat (20) @(posedge clk);
    check("led", led, 16'hABCD);
    verdict();
  end

endmodule
