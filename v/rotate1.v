module main();
	reg  [31:0] a, b;
	wire [31:0] out;

	rotate1 rot(.x(a), .k(b), .o(out));

	initial begin
		/* output
		 * sora@iHogwarts:~/work/snippets/v$ iverilog rotate1.v 
		 * sora@iHogwarts:~/work/snippets/v$ ./a.out 
		 * a=00000000000000000000000000000000, b=         2, out=00000000000000000000000000000000
		 * a=00000000000000000000000000000111, b=         2, out=00000000000000000000000000011100
		 * a=00000000000000000000000011000111, b=         2, out=00000000000000000000001100011100
		 * a=00000000000000000000000011000111, b=        21, out=00011000111000000000000000000000
		 * a=00000000000000000000000000001010, b=         3, out=00000000000000000000000001010000
		 * a=00000000000000000000000000001111, b=         3, out=00000000000000000000000001111000
		 * a=11000000000000000000000011000111, b=         2, out=00000000000000000000001100011111
		 */

		a = 32'b0;
		b = 2;
		$monitor("a=%b, b=%d, out=%b", a, b, out);
		#100 a = 32'b111; b = 2;
		#100 a = 32'b11000111; b = 5;
		#100 a = 32'b11000111; b = 5;
		#100 a = 32'b11000111; b = 21;
		#100 a = 10; b = 3;
		#100 a = 15; b = 3;
		#100 a = 32'b11000000000000000000000011000111; b = 2;
		#100 $finish;
	end
endmodule

module rotate1(x, k, o);
	input  [31:0] x, k;
	output [31:0] o;

	assign o = (x << k) ^ (x >> (32 - k));
endmodule

module mix(a, b, c, oa, ob, oc);
	input  [31:0] a, b, c;
	output [31:0] oa, ob, oc;
endmodule

//module hoge();
//input a, b, c
//output oa, ob, oc;
//always @hoge begin
//	mix4 m4()
//	mix6 m6()
//	mix8 m8()
//	mix16 m16()
//	mix19 m19()
//end
//endmodule
