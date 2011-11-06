module main();
reg		[31:0] a, b;
wire	[31:0] out;

rotate1 rot(.x(a), .k(b), .o(out));

initial begin
	a = 32'b00000000;
	b = 2;
	$monitor("a=%b, b=%d, out=%b", a, b, out);
	#6 a = 32'b00000111; b = 2;
	#6 a = 32'b11000111; b = 2;
	#6 a = 32'b11000111; b = 21;
	#6 a = 10; b = 3;
	#6 a = 15; b = 3;
	#6 a = 32'b11000000000000000000000011000111; b = 2;
	#6 $finish;
end
endmodule

module rotate1(x, k, o);
input	[31:0] x, k;
output	[31:0] o;
assign o = (x << k) ^ (x >> (32 - k));
endmodule

