module ram (
	clk,
	address,
	write_data,
	read_data,
	mem_op
); 

input clk;
input [15:0] address;
input [1:0] mem_op;

input [15:0] write_data;
output reg [15:0] read_data;

reg [15:0] mem [0:1023];
 
always @ (*) begin
	if (mem_op == 2'b10) begin
		 mem[address] = write_data;
	end
	else if (mem_op == 2'b01) begin
		read_data = mem[address];
	end
end

integer f; 
always @(posedge clk) begin
	f = $fopen("C:\\Users\\Brian\\Desktop\\ram.txt", "w");
	$fwrite(f,"%h\n", mem[0]);
	$fwrite(f,"%h\n", mem[1]);
	$fwrite(f,"%h\n", mem[2]);
	$fwrite(f,"%h\n", mem[3]);
	$fwrite(f,"%h\n", mem[4]);
	$fwrite(f,"%h\n", mem[5]);
	$fwrite(f,"%h\n", mem[6]);
	$fwrite(f,"%h\n", mem[7]);
	$fclose(f);
end

endmodule
