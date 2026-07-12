module alu_decoder_tb
  import alu_pkg::*;
();

  int checks = 0;
  int errors = 0;

  logic [1:0] alu_op;
  logic [2:0] funct3;
  logic       funct7b5;
  logic       op5;
  alu_pkg::alu_op_e alu_ctrl;

  localparam logic [1:0] AluOpAdd = 2'b00;
  localparam logic [1:0] AluOpBranch = 2'b01;
  localparam logic [1:0] AluOpFunct = 2'b10;

  alu_decoder dut (
      .alu_op  (alu_op),
      .funct3  (funct3),
      .funct7b5(funct7b5),
      .op5     (op5),
      .alu_ctrl(alu_ctrl)
  );

  task automatic check(input string name, input alu_pkg::alu_op_e got, input alu_pkg::alu_op_e exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("%s mismatch: got %s, exp %s", name, got.name(), exp.name());
    end
  endtask

  task automatic verdict();
    if (errors == 0) $display("PASS: %0d checks, %0d mismatches", checks, errors);
    else $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    $finish;
  endtask

  initial begin
    $dumpfile("alu_decoder_tb.vcd");
    $dumpvars(0, alu_decoder_tb);

    // Add category
    alu_op = AluOpAdd; funct3 = 3'b000; funct7b5 = 0; op5 = 0; #1;
    check("add cat", alu_ctrl, ALU_ADD);
    alu_op = AluOpAdd; funct3 = 3'b111; funct7b5 = 1; op5 = 1; #1;
    check("add cat ignores funct", alu_ctrl, ALU_ADD);

    // Branch category
    alu_op = AluOpBranch; funct3 = 3'b000; funct7b5 = 0; op5 = 0; #1;
    check("branch cat", alu_ctrl, ALU_SUB);

    // funct3=000 add/sub tiebreaker
    alu_op = AluOpFunct; funct3 = 3'b000;
    funct7b5 = 0; op5 = 1; #1; check("add (r)", alu_ctrl, ALU_ADD);
    funct7b5 = 1; op5 = 1; #1; check("sub (r)", alu_ctrl, ALU_SUB);
    funct7b5 = 1; op5 = 0; #1; check("addi bit30 set stays add", alu_ctrl, ALU_ADD);
    funct7b5 = 0; op5 = 0; #1; check("addi", alu_ctrl, ALU_ADD);

    // One-to-one funct3 arms
    alu_op = AluOpFunct; funct7b5 = 0; op5 = 1;
    funct3 = 3'b001; #1; check("sll", alu_ctrl, ALU_SLL);
    funct3 = 3'b010; #1; check("slt", alu_ctrl, ALU_SLT);
    funct3 = 3'b011; #1; check("sltu", alu_ctrl, ALU_SLTU);
    funct3 = 3'b100; #1; check("xor", alu_ctrl, ALU_XOR);
    funct3 = 3'b110; #1; check("or", alu_ctrl, ALU_OR);
    funct3 = 3'b111; #1; check("and", alu_ctrl, ALU_AND);

    // funct3=101 srl/sra tiebreaker, no op5 gate
    alu_op = AluOpFunct; funct3 = 3'b101;
    funct7b5 = 0; op5 = 1; #1; check("srl (r)", alu_ctrl, ALU_SRL);
    funct7b5 = 1; op5 = 1; #1; check("sra (r)", alu_ctrl, ALU_SRA);
    funct7b5 = 0; op5 = 0; #1; check("srli", alu_ctrl, ALU_SRL);
    funct7b5 = 1; op5 = 0; #1; check("srai stays arithmetic", alu_ctrl, ALU_SRA);

    verdict();
  end

endmodule
