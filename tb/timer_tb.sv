module timer_tb;

  int checks = 0;
  int errors = 0;

  localparam int Xlen = 32;

  logic            clk = 0;
  logic            rst_n;
  logic [Xlen-1:0] pc;
  logic [Xlen-1:0] alu_result;
  logic [Xlen-1:0] write_data;
  logic            mem_write;

  top #(
      .XLEN (Xlen),
      .DEPTH(64)
  ) dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .pc        (pc),
      .alu_result(alu_result),
      .write_data(write_data),
      .mem_write (mem_write)
  );

  always #5 clk = ~clk;

  task automatic check(input string name, input logic [Xlen-1:0] got, input logic [Xlen-1:0] exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $error("%s: got %h exp %h", name, got, exp);
    end
  endtask

  initial begin
    $dumpfile("timer_tb.vcd");
    $dumpvars(0, timer_tb);
    $readmemh("tests/timer.hex", dut.imem_inst.mem);

    rst_n = 0;
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;

    repeat (200) @(posedge clk);

    check("handler_ran_x28", dut.riscv_single_inst.datapath_inst.regfile_inst.regfile_mem[28],
          32'd42);
    check("mcause_timer", dut.riscv_single_inst.csr_inst.mcause, 32'h8000_0007);

    if (errors == 0) $display("PASS: %0d checks, %0d mismatches", checks, errors);
    else $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    $finish;
  end

endmodule
