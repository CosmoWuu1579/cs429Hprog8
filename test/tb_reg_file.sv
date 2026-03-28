`include "hdl/reg_file.sv"

module tb_reg_file;
    reg        clk, reset, write;
    reg [63:0] data_write;
    reg [4:0]  d, s, t;

    wire [63:0] rd, rs, rt, stack_pointer;

    register_file uut (
        .clk        (clk),
        .reset      (reset),
        .write      (write),
        .data_write (data_write),
        .d          (d),
        .s          (s),
        .t          (t),
        .rd         (rd),
        .rs         (rs),
        .rt         (rt),
        .stack_pointer(stack_pointer)
    );

    always #5 clk = ~clk;

    integer pass = 0, fail = 0;

    task check64;
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
        clk = 0; reset = 1; write = 0;
        data_write = 0; d = 0; s = 0; t = 0;

        // Apply reset for one cycle
        @(posedge clk); #1;
        reset = 0;

        // After reset: r0-r30 should be 0, r31 = MEM_SIZE (524288)
        s = 5'd0;
        #1 check64(rs, 64'd0, 0);

        s = 5'd15;
        #1 check64(rs, 64'd0, 1);

        s = 5'd31;
        #1 check64(rs, 64'd524288, 2);  // r31 = MEM_SIZE

        // Write 64'hDEADBEEF to register 5
        write = 1; d = 5'd5; data_write = 64'hDEADBEEF;
        @(posedge clk); #1;
        write = 0;

        // Read it back via rd port (d=5) and rs port (s=5)
        d = 5'd5; s = 5'd5;
        #1 check64(rd, 64'hDEADBEEF, 3);
        check64(rs, 64'hDEADBEEF, 4);

        // Write to r10, read via rt port
        write = 1; d = 5'd10; data_write = 64'hCAFEBABE;
        @(posedge clk); #1;
        write = 0;

        t = 5'd10;
        #1 check64(rt, 64'hCAFEBABE, 5);

        // Write with write=0 should NOT update the register
        write = 0; d = 5'd5; data_write = 64'hFFFFFFFF;
        @(posedge clk); #1;
        d = 5'd5;
        #1 check64(rd, 64'hDEADBEEF, 6);  // should still be old value

        // Reset clears all registers
        reset = 1;
        @(posedge clk); #1;
        reset = 0;

        d = 5'd5; s = 5'd10; t = 5'd31;
        #1;
        check64(rd, 64'd0, 7);       // r5 should be 0 again
        check64(rs, 64'd0, 8);       // r10 should be 0 again
        check64(rt, 64'd524288, 9);  // r31 = MEM_SIZE

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
