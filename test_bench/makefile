
all: compile_test_bench run_test_bench

compile_test_bench: test_bench.c 
	gcc -o test_bench test_bench.c ../common/logs.c ../common/instruction.c `pkg-config --cflags --libs glib-2.0`

run_test_bench: test_bench
	./test_bench

clean:
	rm -f programs/asm/bin/*.hex programs/asm/mips/*.m
	rm -f programs/code/asm/*.s programs/code/bin/*.hex programs/code/mips/*.m
	rm -rf out/sim/*/ out/emu/*/
	rm -f test.vcd test_bench
