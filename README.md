# CS 429H Prog 08 by Cosmo Wu cyw356

## How to Run Testing Code
### ALU testing code
To run the code, run the command below:
```bash
iverilog -g2012 -o vvp/tb_alu test/tb_alu.sv && vvp vvp/tb_alu
```

### Register file testbench
To run the code, run the command below:
```bash
iverilog -g2012 -o vvp/tb_reg_file test/tb_reg_file.sv && vvp vvp/tb_reg_file
```

### Complete Tinker Testing Code 
To run the code, run the command below:
```bash
iverilog -g2012 -o vvp/tb_tinker_core test/tb_tinker_core.sv && vvp vvp/tb_tinker_core
```
