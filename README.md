# Compiler - Assembler - Processor
This repository implements a compiler, assembler and a processor.
### Compiler
OCaml.</br>
Most of code taken from Northeastern compilers course.</br>
Compiles to x86.
### Assembler
Ocaml.</br>
Coverts x86 to a RISC ISA and assembles to binary.
### Processor
Verilog.</br>
Implements a RISC ISA capable of running all instructions generated by assembler.
### Test Bench
C - Verilog Programming Interface.</br>
Simulates instruction memory, data memory, and registers.</br>
Runs through different types of tests:
1. Binary tests - binary code. and checks to make sure main memory and registers are the same as expected
2. Assembly Tests - x86 assembly code. tests only the final result in eax.
3. Code Tests - abstract code. tests only the final result in eax.
### Running the code
There is a dependency script that may or may not work for getting the dependencies.</br>
Once these are acquired, the makefile can be run which will compile all four modules and run the test bench.
### Future Features
1. Super scalar :+1:
2. Performance metrics (branch misses, IPC, instruction histograms, stalls) :+1:
3. Robust Tests
4. Branch predictor
5. Out of order
6. Compiler - Tuples and Forever loop
7. OS
8. SIMD 
9. Basic terminal output
10. Memory simulator (cache / memory heirarchy with random latency)
