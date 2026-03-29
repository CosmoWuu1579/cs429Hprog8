`include "hdl/instruction_fetch.sv"

module tb_instruction_fetch;
    reg        clk, reset, ooo_signal;
    reg [63:0] ooo_address;

    wire [63:0] pc_address;

    instruction_fetch uut (
        .clk         (clk),
        .reset       (reset),
        .ooo_signal  (ooo_signal),
        .ooo_address (ooo_address),
        .pc_address  (pc_address)
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
        clk = 0; 
        reset = 0; 
        ooo_signal = 0; 
        ooo_address = 64'h0;

        // Test 0: reset sets PC to 0x2000
        reset = 1;
        @(posedge clk); #1;
        reset = 0;
        check64(pc_address, 64'h2000, 0);

        // Test 1: PC advances by 4 each cycle
        @(posedge clk); #1;
        check64(pc_address, 64'h2004, 1);

        @(posedge clk); #1;
        check64(pc_address, 64'h2008, 2);

        // Test 3: out-of-order (branch) signal 
        ooo_signal = 1; ooo_address = 64'h4000;
        @(posedge clk); #1;
        ooo_signal = 0;
        check64(pc_address, 64'h4000, 3);

        // Test 4: after branch, normal increment resumes
        @(posedge clk); #1;
        check64(pc_address, 64'h4004, 4);

        // Test 5: reset in the middle of execution returns PC to 0x2000
        @(posedge clk); #1;  // PC = 0x4008
        reset = 1;
        @(posedge clk); #1;
        reset = 0;
        check64(pc_address, 64'h2000, 5);

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
