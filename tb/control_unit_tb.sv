module control_unit_tb
  import alu_pkg::*;
();

  int                     checks = 0;
  int                     errors = 0;

  logic             [6:0] op;
  logic             [2:0] funct3;
  logic                   funct7b5;
  logic                   zero;
  logic                   lt;
  logic                   ltu;
  logic                   reg_write;
  logic             [2:0] imm_src;
  logic                   alu_src;
  logic                   mem_write;
  logic             [1:0] result_src;
  logic                   pc_src;
  alu_pkg::alu_op_e       alu_ctrl;

  logic                   exp_pc;
  alu_pkg::alu_op_e       alu_exp;
  alu_pkg::alu_op_e       alu_got;

  localparam logic [6:0] OpcodeOp = 7'b0110011;
  localparam logic [6:0] OpcodeOpImm = 7'b0010011;
  localparam logic [6:0] OpcodeLoad = 7'b0000011;
  localparam logic [6:0] OpcodeBranch = 7'b1100011;
  localparam logic [6:0] OpcodeJal = 7'b1101111;
  localparam logic [6:0] OpcodeJalr = 7'b1100111;

  localparam logic [2:0] ImmI = 3'd0;

  control_unit dut (
      .op        (op),
      .funct3    (funct3),
      .funct7b5  (funct7b5),
      .zero      (zero),
      .lt        (lt),
      .ltu       (ltu),
      .reg_write (reg_write),
      .imm_src   (imm_src),
      .alu_src   (alu_src),
      .mem_write (mem_write),
      .result_src(result_src),
      .pc_src    (pc_src),
      .alu_ctrl  (alu_ctrl)
  );

  // pc_src vector: {op[6:0], funct3[2:0], zero, lt, ltu, exp_pc}
  logic [13:0] pc_vectors [16];
  // alu vector: {op[6:0], funct3[2:0], funct7b5, exp[3:0]}
  logic [14:0] alu_vectors[ 3];

  task automatic check_ctrl(input string name, input logic [2:0] got, input logic [2:0] exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("%s: got %b exp %b", name, got, exp);
    end
  endtask

  task automatic verdict();
    if (errors == 0) $display("PASS: %0d checks, %0d mismatches", checks, errors);
    else $fatal(1, "FAIL: %0d mismatches, %0d checks", errors, checks);
    $finish;
  endtask

  initial begin
    $dumpfile("control_unit_tb.vcd");
    $dumpvars(0, control_unit_tb);

    // All six branches both directions, plus jumps and non-branch
    pc_vectors = '{
        {OpcodeBranch, 3'b000, 1'b1, 1'b0, 1'b0, 1'b1},  // beq taken
        {OpcodeBranch, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0},  // beq not
        {OpcodeBranch, 3'b001, 1'b0, 1'b0, 1'b0, 1'b1},  // bne taken
        {OpcodeBranch, 3'b001, 1'b1, 1'b0, 1'b0, 1'b0},  // bne not
        {OpcodeBranch, 3'b100, 1'b0, 1'b1, 1'b0, 1'b1},  // blt taken
        {OpcodeBranch, 3'b100, 1'b0, 1'b0, 1'b0, 1'b0},  // blt not
        {OpcodeBranch, 3'b101, 1'b0, 1'b0, 1'b0, 1'b1},  // bge taken
        {OpcodeBranch, 3'b101, 1'b0, 1'b1, 1'b0, 1'b0},  // bge not
        {OpcodeBranch, 3'b110, 1'b0, 1'b0, 1'b1, 1'b1},  // bltu taken
        {OpcodeBranch, 3'b110, 1'b0, 1'b0, 1'b0, 1'b0},  // bltu not
        {OpcodeBranch, 3'b111, 1'b0, 1'b0, 1'b0, 1'b1},  // bgeu taken
        {OpcodeBranch, 3'b111, 1'b0, 1'b0, 1'b1, 1'b0},  // bgeu not
        {OpcodeJal, 3'b000, 1'b0, 1'b0, 1'b0, 1'b1},  // jal
        {OpcodeJalr, 3'b000, 1'b0, 1'b0, 1'b0, 1'b1},  // jalr
        {OpcodeOp, 3'b000, 1'b1, 1'b1, 1'b1, 1'b0},  // op no jump
        {OpcodeLoad, 3'b000, 1'b1, 1'b1, 1'b1, 1'b0}  // load no jump
    };

    foreach (pc_vectors[i]) begin
      op       = pc_vectors[i][13:7];
      funct3   = pc_vectors[i][6:4];
      zero     = pc_vectors[i][3];
      lt       = pc_vectors[i][2];
      ltu      = pc_vectors[i][1];
      exp_pc   = pc_vectors[i][0];
      funct7b5 = 1'b0;
      #1;
      checks++;
      if (pc_src !== exp_pc) begin
        errors++;
        $display("pc vec %0d (op=%b funct3=%b): pc_src %b exp %b", i, op, funct3, pc_src, exp_pc);
      end
    end

    // alu_ctrl end to end
    alu_vectors = '{
        {OpcodeOp, 3'b000, 1'b1, ALU_SUB},  // r-sub
        {OpcodeOpImm, 3'b000, 1'b1, ALU_ADD},  // addi
        {OpcodeLoad, 3'b010, 1'b0, ALU_ADD}  // load add
    };

    foreach (alu_vectors[i]) begin
      op       = alu_vectors[i][14:8];
      funct3   = alu_vectors[i][7:5];
      funct7b5 = alu_vectors[i][4];
      alu_exp  = alu_pkg::alu_op_e'(alu_vectors[i][3:0]);
      #1;
      alu_got = alu_ctrl;
      checks++;
      if (alu_got !== alu_exp) begin
        errors++;
        $display("alu vec %0d (op=%b): got %s exp %s", i, op, alu_got.name(), alu_exp.name());
      end
    end

    // Decoder control lines pass through
    op = OpcodeOpImm;
    funct3 = 3'b000;
    funct7b5 = 1'b0;
    zero = 1'b0;
    lt = 1'b0;
    ltu = 1'b0;
    #1;
    check_ctrl("opimm reg_write", 3'(reg_write), 3'd1);
    check_ctrl("opimm alu_src", 3'(alu_src), 3'd1);
    check_ctrl("opimm imm_src", imm_src, ImmI);

    verdict();
  end

endmodule
