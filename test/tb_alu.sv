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
        // initial values
        rd = 0; 
        rs = 0; 
        rt = 0;
        stack_pointer = 64'd524288;
        L = 0; 
        memory_value = 0; 
        pc = 64'h2000;

        // logic ones
        opcode = 5'h0; 
        rs = 64'hFF; 
        rt = 64'h0F;
        #1 check(reg_out_value, 64'h0F, 0);
        check(reg_write, 1, 1);

        opcode = 5'h1; 
        rs = 64'hF0; 
        rt = 64'h0F;
        #1 check(reg_out_value, 64'hFF, 2);

        opcode = 5'h2; 
        rs = 64'hAA; 
        rt = 64'hFF;
        #1 check(reg_out_value, 64'h55, 3);

        opcode = 5'h3; 
        rs = 64'h0;
        #1 check(reg_out_value, 64'hFFFFFFFFFFFFFFFF, 4);

        opcode = 5'h4; 
        rs = 64'h80; 
        rt = 64'h3;
        #1 check(reg_out_value, 64'h10, 5);

        opcode = 5'h5; 
        rd = 64'h80; 
        L = 12'd3;
        #1 check(reg_out_value, 64'h10, 6);

        opcode = 5'h6; 
        rs = 64'h1; 
        rt = 64'h4;
        #1 check(reg_out_value, 64'h10, 7);

        opcode = 5'h7; 
        rd = 64'h1; 
        L = 12'd4;
        #1 check(reg_out_value, 64'h10, 8);

        // Data movement
        opcode = 5'h11; 
        rs = 64'hDEADBEEF;
        #1 check(reg_out_value, 64'hDEADBEEF, 9);

        opcode = 5'h12; 
        rd = 64'h0; 
        L = 12'hABC;
        #1 check(reg_out_value, {52'b0, 12'hABC}, 10);

        // Integer arithmetic
        opcode = 5'h18; 
        rs = 64'd100; 
        rt = 64'd200;
        #1 check(reg_out_value, 64'd300, 11);

        opcode = 5'h19; 
        rd = 64'd50; 
        L = 12'd25;
        #1 check(reg_out_value, 64'd75, 12);

        opcode = 5'h1a; 
        rs = 64'd300; 
        rt = 64'd100;
        #1 check(reg_out_value, 64'd200, 13);

        opcode = 5'h1b; 
        rd = 64'd100; 
        L = 12'd25;
        #1 check(reg_out_value, 64'd75, 14);

        opcode = 5'h1c; 
        rs = 64'd12; 
        rt = 64'd10;
        #1 check(reg_out_value, 64'd120, 15);

        opcode = 5'h1d; 
        rs = 64'd100; 
        rt = 64'd5;
        #1 check(reg_out_value, 64'd20, 16);

        opcode = 5'h1d; 
        rs = 64'd100; 
        rt = 64'd0;
        #1 check(reg_out_value, 64'd0, 17);

        // Control instructions
        opcode = 5'h8; rd = 64'h4000;
        #1;
        if (ooo_signal !== 1 || ooo_address !== 64'h4000) begin
            $display("FAIL test 18: branch to register");
            fail = fail + 1;
        end else begin
            $display("PASS test 18");
            pass = pass + 1;
        end

        opcode = 5'h10; 
        rs = 64'h2000; 
        L = 12'd8; 
        memory_value = 64'hCAFEBABE;
        #1 check(reg_out_value, 64'hCAFEBABE, 19);

        opcode = 5'h13; rs = 64'hDEAD; L = 12'd0;
        #1;
        if (memory_write !== 1 || memory_data_to_write !== 64'hDEAD) begin
            $display("FAIL test 20: store to memory");
            fail = fail + 1;
        end else begin
            $display("PASS test 20");
            pass = pass + 1;
        end

    
        // FLOAT TESTS
        opcode = 5'h14; 
        rs = 64'h3FF8000000000000;   // 1.5
        rt = 64'h4002000000000000;   // 2.25
        #1 check(reg_out_value, 64'h400E000000000000, 21); // 3.75
    

        opcode = 5'h14; 
        rs = 64'hBFF0000000000000;   // 1.5
        rt = 64'h4010000000000000;   // 2.25
        #1 check(reg_out_value, 64'h4008000000000000, 22); // 3.75

        opcode = 5'h15; 
        rs = 64'h4016000000000000; // 5.5
        rt = 64'h4002000000000000; // 2.25
        #1 check(reg_out_value, 64'h400A000000000000, 23); // 3.25

        opcode = 5'h15;
        rs = 64'h4000000000000000;   // 2.0
        rt = 64'h4014000000000000;   // 5.0
        #1 check(reg_out_value, 64'hC008000000000000, 24); // -3.0

        opcode = 5'h16;
        rs = 64'h3FF8000000000000;  // 1.5
        rt = 64'h4000000000000000;  // 2.0
        #1 check(reg_out_value, 64'h4008000000000000, 25); // 3.0

        opcode = 5'h16;
        rs = 64'hC000000000000000;  // -2.0
        rt = 64'h4008000000000000;  // 3.0
        #1 check(reg_out_value, 64'hC018000000000000, 26); // -6.0



        opcode = 5'h17;
        rs = 64'h4018000000000000;  // 6.0
        rt = 64'h4000000000000000;  // 2.0
        #1 check(reg_out_value, 64'h4008000000000000, 27); // 3.0

        opcode = 5'h17;
        rs = 64'hC022000000000000;  // -9.0
        rt = 64'h4008000000000000;  // 3.0
        #1 check(reg_out_value, 64'hC008000000000000, 28); // -3.0

        opcode = 5'h16;
        rs = 64'h4020000000000000;  
        rt = 64'h0000000000000010;  
        #1 check(reg_out_value, 64'h0000000000000080, 29); 

        opcode = 5'h14;
        rs = 64'h0000000000000001;
        rt = 64'h0000000000000001;
        #1 check(reg_out_value, 64'h0000000000000002, 30);

        opcode = 5'h15;
        rs = 64'h0000000000000002;
        rt = 64'h0000000000000001;
        #1 check(reg_out_value, 64'h0000000000000001, 31);

        opcode = 5'h16;
        rs = 64'h0000000000000001;
        rt = 64'h4000000000000000;  
        #1 check(reg_out_value, 64'h0000000000000002, 32);

        opcode = 5'h17;
        rs = 64'h4000000000000000;        
        rt = 64'h000FFFFFFFFFFFFF;        
        #1 check(reg_out_value, 64'h7FE0000000000001, 33); 

        opcode = 5'h14;                       
        rs = 64'h0000000000000100;            
        rt = 64'h8000000000000004;            
        #1 check(reg_out_value, 64'h00000000000000fc, 34);   
        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end
endmodule
