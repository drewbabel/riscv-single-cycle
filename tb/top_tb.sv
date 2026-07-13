module top_tb ();

  int checks = 0;
  int errors = 0;

  localparam int Xlen = 32;
  localparam int Depth = 64;

  localparam int InstrCnt = 6;

  logic            clk = 1'b0;
  logic            rst_n;
  logic [Xlen-1:0] pc;
  logic [Xlen-1:0] alu_result;
  logic [Xlen-1:0] write_data;
  logic            mem_write;

  always #5 clk = ~clk;

  top #(
      .XLEN (Xlen),
      .DEPTH(Depth)
  ) dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .pc        (pc),
      .alu_result(alu_result),
      .write_data(write_data),
      .mem_write (mem_write)
  );

  task automatic do_reset();
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  endtask  // Automatic

  task automatic verdict();
    @(posedge clk);
    if (errors == 0) $display("PASS: %0d checks, %0d mismatches", checks, errors);
    else $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    $finish;
  endtask  // Automatic

  task automatic check_manual();
    logic [Xlen-1:0] exp_array[InstrCnt];
    logic [Xlen-1:0] got;

    repeat (InstrCnt) @(posedge clk);

    exp_array[0] = 32'd5;
    exp_array[1] = 32'd3;
    exp_array[2] = 32'd8;
    exp_array[3] = 32'd5;
    exp_array[4] = 32'd8;
    exp_array[5] = 32'd8;

    foreach (exp_array[i]) begin
      #1;
      if (i == InstrCnt - 1) got = dut.dmem_inst.mem[0];
      else got = dut.riscv_single_inst.datapath_inst.regfile_inst.regfile_mem[i+1];
      checks++;
      if (got !== exp_array[i]) begin
        errors++;
        $error("t=%0t mismatch: got=%b, exp=%b", $time, got, exp_array[i]);
      end
    end
  endtask  // Automatic

  task automatic check_loop();
    int counter;
    logic [Xlen-1:0] last;

    last = pc;
    @(posedge clk);
    #1;
    while (pc !== last) begin
      last = pc;
      @(posedge clk);
      #1;
    end

    #1;
    checks++;
    if (dut.dmem_inst.mem[0] == 28) begin
      checks++;
      counter = dut.riscv_single_inst.datapath_inst.regfile_inst.regfile_mem[1];
      if (counter !== 0) begin
        errors++;
        $error("t=%0t loop counter mismatch: got=%0d, exp=%0d", $time, counter, 0);
      end
    end else begin
      errors++;
      $error("t=%0t mem  mismatch: got=%0d, exp=%0d", $time, dut.dmem_inst.mem[0], 28);
    end
  endtask  // Automatic

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);

    // program.hex
    $readmemh("tests/program.hex", dut.imem_inst.mem);
    do_reset();
    check_manual();

    // loop.hex
    $readmemh("tests/loop.hex", dut.imem_inst.mem);
    do_reset();
    check_loop();

    verdict();
  end

endmodule
