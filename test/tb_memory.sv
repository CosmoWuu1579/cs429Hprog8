`include "hdl/memory.sv"

module tb_memory;
    reg        clk;
    reg [63:0] pc;
    reg [63:0] alu_data;
    reg [63:0] alu_pointer;
    reg        write;

    wire [31:0] instruction;
    wire [63:0] address_value;

    memory uut (
        .clk          (clk),
        .pc           (pc),
        .alu_data     (alu_data),
        .alu_pointer  (alu_pointer),
        .write        (write),
        .instruction  (instruction),
        .address_value(address_value)
    );

    always #5 clk = ~clk;

    integer pass = 0, fail = 0;

    task force_read;
        begin
            alu_pointer = alu_pointer + 8; #1;
            alu_pointer = alu_pointer - 8; #1;
        end
    endtask

    task check32;
        input [31:0] got, expected;
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
        clk = 0; write = 0;
        pc = 64'h2000; alu_pointer = 64'h0; alu_data = 64'h0;

        // Test 0: memory is initialized to 0, so reads before any write should be 0
        #1;
        check32(instruction,   32'h0, 0);
        check64(address_value, 64'h0, 1);

        // Test 2: write a 64-bit value to address 0x100 and read it back
        alu_pointer = 64'h100; alu_data = 64'hDEADBEEFCAFEBABE; write = 1;
        @(posedge clk); #1;
        write = 0;
        force_read;
        check64(address_value, 64'hDEADBEEFCAFEBABE, 2);

        // Test 3: write an instruction pattern at pc=0x2000 and read via instruction port
        alu_pointer = 64'h2000; alu_data = 64'h00000000C0DEFACE; write = 1;
        @(posedge clk); #1;
        write = 0;
        // Toggle pc to force instruction output to re-evaluate
        pc = 64'h0; #1;
        pc = 64'h2000; #1;
        check32(instruction, 32'hC0DEFACE, 3);

        // Test 4: write=0 should not update memory
        alu_pointer = 64'h200; alu_data = 64'hFFFFFFFFFFFFFFFF; write = 0;
        @(posedge clk); #1;
        force_read;
        check64(address_value, 64'h0, 4);  // still zero, write was disabled

        // Test 5: overwrite existing value at 0x100
        alu_pointer = 64'h100; alu_data = 64'h0000000000000001; write = 1;
        @(posedge clk); #1;
        write = 0;
        force_read;
        check64(address_value, 64'h1, 5);

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
