`include "hdl/instruction_decoder.sv"

module tb_instruction_decoder;
    reg [31:0] instruction;

    wire [4:0]  opcode, d, s, t;
    wire [11:0] L;

    instruction_decoder uut (
        .instruction (instruction),
        .opcode      (opcode),
        .d           (d),
        .s           (s),
        .t           (t),
        .L           (L)
    );

    integer pass = 0, fail = 0;

    task check5;
        input [4:0]  got, expected;
        input [63:0] test_id;
        input [63:0] field_name; 
        begin
            if (got !== expected) begin
                $display("FAIL test %0d: got %h, expected %h", test_id, got, expected);
                fail = fail + 1;
            end else begin
                $display("PASS test %0d", test_id);
                pass = pass + 1;
            end
        end
    endtask

    task check12;
        input [11:0] got, expected;
        input [63:0] test_id;
        begin
            if (got !== expected) begin
                $display("FAIL test %0d: got %h, expected %h", test_id, got, expected);
                fail = fail + 1;
            end else begin
                $display("PASS test %0d", test_id);
                pass = pass + 1;
            end
        end
    endtask

    initial begin
        // Test 0: opcode extracted from bits [31:27]
        // opcode=5'b00001 (1), d=5'b00010 (2), s=5'b00011 (3), t=5'b00100 (4), L=12'hABC
        instruction = {5'd1, 5'd2, 5'd3, 5'd4, 12'hABC};
        #1;
        check5(opcode, 5'd1,   0, 0);
        check5(d,      5'd2,   1, 0);
        check5(s,      5'd3,   2, 0);
        check5(t,      5'd4,   3, 0);
        check12(L,     12'hABC, 4);

        // Test 5: all-zeros instruction
        instruction = 32'h0;
        #1;
        check5(opcode, 5'd0,   5, 0);
        check5(d,      5'd0,   6, 0);
        check5(s,      5'd0,   7, 0);
        check5(t,      5'd0,   8, 0);
        check12(L,     12'd0,  9);

        // Test 10: all-ones instruction
        instruction = 32'hFFFFFFFF;
        #1;
        check5(opcode, 5'h1F,   10, 0);
        check5(d,      5'h1F,   11, 0);
        check5(s,      5'h1F,   12, 0);
        check5(t,      5'h1F,   13, 0);
        check12(L,     12'hFFF, 14);

        // Test 15: opcode=0x18 (add), d=r1, s=r2, t=r3, L=0
        instruction = {5'h18, 5'd1, 5'd2, 5'd3, 12'd0};
        #1;
        check5(opcode, 5'h18, 15, 0);
        check5(d,      5'd1,  16, 0);
        check5(s,      5'd2,  17, 0);
        check5(t,      5'd3,  18, 0);
        check12(L,     12'd0, 19);

        // Test 20
        instruction = {5'h12, 5'd5, 5'd0, 5'd0, 12'h1FF};
        #1;
        check5(opcode, 5'h12,   20, 0);
        check5(d,      5'd5,    21, 0);
        check12(L,     12'h1FF, 22);

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
