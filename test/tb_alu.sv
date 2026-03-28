`include "hdl/alu.sv"

module tb_alu;
    // Inputs
    reg [4:0]  opcode;
    reg [63:0] rd, rs, rt;
    reg [63:0] stack_pointer;
    reg [11:0] L;
    reg [63:0] memory_value;
    reg [63:0] pc;

    // Outputs
    wire [63:0] memory_pointer;
    wire        memory_write;
    wire [63:0] memory_data_to_write;
    wire        ooo_signal;
    wire [63:0] ooo_address;
    wire [63:0] reg_out_value;
    wire        reg_write;

    alu uut (
        .opcode              (opcode),
        .rd                  (rd),
        .rs                  (rs),
        .rt                  (rt),
        .stack_pointer       (stack_pointer),
        .L                   (L),
        .memory_value        (memory_value),
        .pc                  (pc),
        .memory_pointer      (memory_pointer),
        .memory_write        (memory_write),
        .memory_data_to_write(memory_data_to_write),
        .ooo_signal          (ooo_signal),
        .ooo_address         (ooo_address),
        .reg_out_value       (reg_out_value),
        .reg_write           (reg_write)
    );

    integer pass = 0, fail = 0;

    task check;
        input [63:0] got, expected;
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
        // default values
        rd = 0; rs = 0; rt = 0;
        stack_pointer = 64'd524288;
        L = 0; memory_value = 0; pc = 64'h2000;

        // --- Bitwise AND (opcode 0x00) ---
        opcode = 5'h0; rs = 64'hFF; rt = 64'h0F;
        #1 check(reg_out_value, 64'h0F, 0);
        check(reg_write, 1, 1);

        // --- Bitwise OR (opcode 0x01) ---
        opcode = 5'h1; rs = 64'hF0; rt = 64'h0F;
        #1 check(reg_out_value, 64'hFF, 2);

        // --- Bitwise XOR (opcode 0x02) ---
        opcode = 5'h2; rs = 64'hAA; rt = 64'hFF;
        #1 check(reg_out_value, 64'h55, 3);

        // --- Bitwise NOT (opcode 0x03) ---
        opcode = 5'h3; rs = 64'h0;
        #1 check(reg_out_value, 64'hFFFFFFFFFFFFFFFF, 4);

        // --- Logical shift right register (opcode 0x04) ---
        opcode = 5'h4; rs = 64'h80; rt = 64'h3;
        #1 check(reg_out_value, 64'h10, 5);

        // --- Logical shift right immediate (opcode 0x05) ---
        opcode = 5'h5; rd = 64'h80; L = 12'd3;
        #1 check(reg_out_value, 64'h10, 6);

        // --- Logical shift left register (opcode 0x06) ---
        opcode = 5'h6; rs = 64'h1; rt = 64'h4;
        #1 check(reg_out_value, 64'h10, 7);

        // --- Logical shift left immediate (opcode 0x07) ---
        opcode = 5'h7; rd = 64'h1; L = 12'd4;
        #1 check(reg_out_value, 64'h10, 8);

        // --- Move register (opcode 0x11) ---
        opcode = 5'h11; rs = 64'hDEADBEEF;
        #1 check(reg_out_value, 64'hDEADBEEF, 9);

        // --- Load immediate into upper bits (opcode 0x12) ---
        opcode = 5'h12; rd = 64'h0; L = 12'hABC;
        #1 check(reg_out_value, {52'b0, 12'hABC}, 10);

        // --- Integer ADD register (opcode 0x18) ---
        opcode = 5'h18; rs = 64'd100; rt = 64'd200;
        #1 check(reg_out_value, 64'd300, 11);

        // --- Integer ADD immediate (opcode 0x19) ---
        opcode = 5'h19; rd = 64'd50; L = 12'd25;
        #1 check(reg_out_value, 64'd75, 12);

        // --- Integer SUB register (opcode 0x1a) ---
        opcode = 5'h1a; rs = 64'd300; rt = 64'd100;
        #1 check(reg_out_value, 64'd200, 13);

        // --- Integer SUB immediate (opcode 0x1b) ---
        opcode = 5'h1b; rd = 64'd100; L = 12'd25;
        #1 check(reg_out_value, 64'd75, 14);

        // --- Integer MUL (opcode 0x1c) ---
        opcode = 5'h1c; rs = 64'd12; rt = 64'd10;
        #1 check(reg_out_value, 64'd120, 15);

        // --- Integer DIV (opcode 0x1d) ---
        opcode = 5'h1d; rs = 64'd100; rt = 64'd5;
        #1 check(reg_out_value, 64'd20, 16);

        // --- DIV by zero should give 0 ---
        opcode = 5'h1d; rs = 64'd100; rt = 64'd0;
        #1 check(reg_out_value, 64'd0, 17);

        // --- Unconditional branch to register (opcode 0x08) ---
        opcode = 5'h8; rd = 64'h4000;
        #1;
        if (ooo_signal !== 1 || ooo_address !== 64'h4000) begin
            $display("FAIL test 18: branch to register");
            fail = fail + 1;
        end else begin
            $display("PASS test 18");
            pass = pass + 1;
        end

        // --- Load from memory (opcode 0x10) ---
        opcode = 5'h10; rs = 64'h2000; L = 12'd8; memory_value = 64'hCAFEBABE;
        #1 check(reg_out_value, 64'hCAFEBABE, 19);

        // --- Store to memory (opcode 0x13) ---
        opcode = 5'h13; rs = 64'hDEAD; L = 12'd0;
        #1;
        if (memory_write !== 1 || memory_data_to_write !== 64'hDEAD) begin
            $display("FAIL test 20: store to memory");
            fail = fail + 1;
        end else begin
            $display("PASS test 20");
            pass = pass + 1;
        end

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
