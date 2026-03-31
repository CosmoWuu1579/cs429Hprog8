`timescale 1ns/1ns
`include "tinker.sv"

module tb_tinker_core;
    reg clk, reset;

    tinker_core core (
        .clk   (clk),
        .reset (reset)
    );

    always #5 clk = ~clk;

    // Loads a 32-bit instruction word into memory at byte address
    task load_instruction;
        input [63:0] addr;
        input [31:0] instr;
        begin
            core.memory.bytes[addr]   = instr[7:0];
            core.memory.bytes[addr+1] = instr[15:8];
            core.memory.bytes[addr+2] = instr[23:16];
            core.memory.bytes[addr+3] = instr[31:24];
        end
    endtask

    // Making a 32 bit instruction
    function [31:0] enc;
        input [4:0] op, d, s, t;
        input [11:0] L;
        enc = {op, d, s, t, L};
    endfunction


    task do_reset;
        begin
            reset = 0;
            @(posedge clk); #0;  // advance pc by 1 (away from wherever it is)
            reset = 1;
            @(posedge clk); #0;  // pc transitions to 0x2000 — always@(pc) fires
            // @(posedge clk); #0;  // hold reset a second cycle
            reset = 0;
            #1;
        end
    endtask

    // Run N clock cycles and settle
    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i++) @(posedge clk);
            #1;
        end
    endtask

    integer pass = 0, fail = 0;

    task check64;
        input [63:0] got, expected;
        input [255:0] label;
        begin
            if (got !== expected) begin
                $display("FAIL [%s]: got %h, expected %h", label, got, expected);
                fail = fail + 1;
            end else begin
                $display("PASS [%s]", label);
                pass = pass + 1;
            end
        end
    endtask

    initial begin
        clk = 0; reset = 0;

        // Test 0: XOR r0

        // Test 1: ADDI then ADD
        //   addi r2, 10   (r2 = 0 + 10 = 10)
        //   addi r3, r3, 20   (r3 = 0 + 20 = 20)
        //   add  r1, r2, r3   (r1 = 10 + 20 = 30)
        load_instruction(64'h2000, enc(5'h19, 5'd2, 5'd0, 5'd0, 12'd10));
        load_instruction(64'h2004, enc(5'h19, 5'd3, 5'd0, 5'd0, 12'd20));
        load_instruction(64'h2008, enc(5'h18, 5'd1, 5'd2, 5'd3, 12'd0));
        load_instruction(64'h200c, enc(5'h0,  5'd0, 5'd0, 5'd0, 12'd0));
        do_reset;
        // $display("opcode: %h, d: %h, s: %h, t: %h", core.u_decoder.opcode, core.u_decoder.d, core.u_decoder.s, core.u_decoder.t);

        // #5;
        // // current PC
        // $display("PC: %h", core.pc_address);
        // // print reset flag
        // $display("Reset: %b", core.reset);
        // // print ALU opcode input and operands
        // $display("opcode: %h, d: %h, s: %h, t: %h", core.u_decoder.opcode, core.u_decoder.d, core.u_decoder.s, core.u_decoder.t);
        // // print output of ALU that feeds into reg file
        // $display("ALU output: %h", core.u_alu.reg_out_value);
        // // print reg_file inputs
        // $display("reg_file write: %b, d: %h, s: %h, t: %h, data_write: %h", core.reg_file.write, core.reg_file.d, core.reg_file.s, core.reg_file.t, core.reg_file.data_write);
        run_cycles(1);     // execute 4 instructions
        // $display("PC: %h", core.pc_address);

        // $display("reg_file write: %b, d: %h, s: %h, t: %h, data_write: %h", core.reg_file.write, core.reg_file.d, core.reg_file.s, core.reg_file.t, core.reg_file.data_write);



        check64(core.reg_file.registers[2], 64'd10, "r2=10 after ADDI");
        run_cycles(1);
        check64(core.reg_file.registers[3], 64'd20, "r3=20 after ADDI");
        run_cycles(1);
        check64(core.reg_file.registers[1], 64'd30, "r1=r2+r3=30 after ADD");

        // Test 2: r31 = MEM_SIZE after reset
        // load_instruction(64'h2000, enc(5'h0, 5'd0, 5'd0, 5'd0, 12'd0)); 
        // do_reset;

        // check64(core.reg_file.registers[31], 64'd524288, "r31=MEM_SIZE on reset");

        // // Test 3: Store then Load
        // //   addi r6, r6, 42       r6 = 42
        // //   mov (r6)(0), r6       MEM(42) <- 42
        // //   mov (r7), (r6)(0)     r7 <- MEM(42)
        // load_instruction(64'h2000, enc(5'h19, 5'd6, 5'd0, 5'd0, 12'd42));
        // load_instruction(64'h2004, enc(5'h13, 5'd6, 5'd6, 5'd0, 12'd0));
        // load_instruction(64'h2008, enc(5'h10, 5'd7, 5'd6, 5'd0, 12'd0));
        // load_instruction(64'h200c, enc(5'h0,  5'd0, 5'd0, 5'd0, 12'd0));

        // do_reset;
        // run_cycles(4);

        // check64(core.reg_file.registers[7], 64'd42, "r7=42 after store+load");

        // // Test 4: Subtraction and multiply
        // load_instruction(64'h2000, enc(5'h19, 5'd4, 5'd0, 5'd0, 12'd100)); // addi r4, 100
        // load_instruction(64'h2004, enc(5'h19, 5'd5, 5'd0, 5'd0, 12'd30));  // addi r5, 30
        // load_instruction(64'h2008, enc(5'h1a, 5'd6, 5'd4, 5'd5, 12'd0));   // sub r6, r4, r5
        // load_instruction(64'h200c, enc(5'h1c, 5'd7, 5'd4, 5'd5, 12'd0));   // mul r7, r4, r5
        // load_instruction(64'h2010, enc(5'h0,  5'd0, 5'd0, 5'd0, 12'd0));

        // do_reset;
        // run_cycles(5);

        // check64(core.reg_file.registers[6], 64'd70,   "r6=100-30=70 after SUB");
        // check64(core.reg_file.registers[7], 64'd3000, "r7=100*30=3000 after MUL");

        // // Test 5: Unconditional branch
        // //   sub r1, r1, r1  zero out r1 (in case of leftover value)
        // //   addi r1, 5
        // //   brr 8          skip next instruction
        // //   addi r1, 99     should be skipped
        // load_instruction(64'h2000, enc(5'h1a, 5'd1, 5'd1, 5'd1, 12'd0));   // sub r1,r1,r1 (zero r1)
        // load_instruction(64'h2004, enc(5'h19, 5'd1, 5'd0, 5'd0, 12'd5));   // addi r1, 5
        // load_instruction(64'h2008, enc(5'h0a, 5'd0, 5'd0, 5'd0, 12'd8));   
        // load_instruction(64'h200c, enc(5'h19, 5'd1, 5'd0, 5'd0, 12'd99));  // addi r1, 99 (skipped)
        // load_instruction(64'h2010, enc(5'h0,  5'd0, 5'd0, 5'd0, 12'd0));   

        // do_reset;
        // run_cycles(5);

        // check64(core.reg_file.registers[1], 64'd5, "r1=5 branch skipped ADDI 99");

        $display("\n%0d passed, %0d failed", pass, fail);
        $finish;
    end

    initial begin
        $dumpfile("sim/tb_tinker_core.vcd");
        $dumpvars(0, tb_tinker_core);
    end
endmodule
