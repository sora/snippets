module main(out);
	parameter STEP = 1000000000000000;

	output	[31:0] out;

	reg	[80*8*1:1] key;
	reg	[31:0] length, interval;
	reg	[31:0] a, b, c;
	reg	[1:0] clk, res;

	initial begin
		clk = 1'b0;
		res = 1'b0;
		key = "abcde";
	end

	always #(STEP/2) clk = ~clk;

	always @(posedge clk) begin
		$display("k=%b", key);
		$display("k[0]=%b", key[8:1]);
		$display("k[0]=%c", key[5*8:4*8+1]);
		$display("k[0]=%c", key[4*8:3*8+1]);
		$display("k[0]=%c", key[3*8:2*8+1]);
		$display("k[0]=%c", key[2*8:1*8+1]);
		$display("k[0]=%c", key[1*8:0*8+1]);
		$finish;
	end
endmodule
