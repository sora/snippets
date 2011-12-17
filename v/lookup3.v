module main(out);
	parameter STEP = 1000000000000000;

	output	[31:0] out;

	reg	[80*8*1:1] key;
	reg	[31:0] length, interval, k0, k1, k2;
	reg	[31:0] a, b, c;
	reg	[1:0] clk, res;

	initial begin
		clk = 1'b0;
		res = 1'b0;
		key = "abcdefghijkl";
		length = 32'd12;
		interval = 32'd0;
	end

	always #(STEP/2) clk = ~clk;

	always @(posedge clk) begin
		a = 32'hDEADBEEF + length + interval;
		b = 32'hDEADBEEF + length + interval;
		c = 32'hDEADBEEF + length + interval;
		$display("a=%h; b=%h; c=%h", a, b, c);

		k0 = key[3*4*8:2*4*8+1];
		k1 = key[2*4*8:1*4*8+1];
		k2 = key[1*4*8:1];
		$display("k0=%s; k1=%s; k2=%s", k0, k1, k2);

		case (length)
			32'd12: begin
				$display("length=%d", 12);
				c = c + k2;
				b = b + k1;
				a = a + k0;
			end
			32'd11: begin
				$display("length=%d", 11);
				c = c + k2 & 32'hFFFFFF00;
				b = b + k1;
				a = a + k0;
			end
			32'd10: begin
				$display("length=%d", 10);
				c = c + k2 & 32'hFFFF0000;
				b = b + k1;
				a = a + k0;
			end
			32'd9: begin
				$display("length=%d", 9);
				c = c + k2 & 32'hFF000000;
				b = b + k1;
				a = a + k0;
			end
			32'd8: begin
				$display("length=%d", 8);
				b = b + k1;
				a = a + k0;
			end
			32'd7: begin
				$display("length=%d", 7);
				b = b + k1 & 32'hFFFFFF00;
				a = a + k0;
			end
			32'd6: begin
				$display("length=%d", 6);
				b = b + k1 & 32'hFFFF0000;
				a = a + k0;
			end
			32'd5: begin
				$display("length=%d", 5);
				c = c + k2 & 32'hFF000000;
				b = b + k1;
				a = a + k0;
			end
			32'd4: begin
				$display("length=%d", 4);
				a = a + k0;
			end
			32'd3: begin
				$display("length=%d", 3);
				a = a + k0 & 32'hFFFFFF00;
			end
			32'd2: begin
				$display("length=%d", 2);
				a = a + k0 & 32'hFFFF0000;
			end
			32'd1: begin
				$display("length=%d", 1);
				a = a + k0 & 32'hFF000000;
			end
			32'd0: begin
				$display("!!OUT=%h", c);
				$finish;
			end
			default: begin
				$display("ERROR");
				$finish;
			end
		endcase

		$display("a=%h; b=%h; c=%h", a, b, c);

		/* final */
		c <= c ^ b; c <= c - (b << 14) ^ (b >> (32 - 14));
		a <= a ^ c; a <= a - (c << 11) ^ (c >> (32 - 11));
		b <= b ^ a; b <= b - (a << 25) ^ (a >> (32 - 25));
		c <= c ^ b; c <= c - (c << 16) ^ (c >> (32 - 16));
		a <= a ^ c; a <= a - (c << 4) ^ (c >> (32 - 4));
		b <= b ^ a; b <= b - (a << 14) ^ (a >> (32 - 14));
		c <= c ^ b; c <= c - (b << 24) ^ (b >> (32 - 24));
		$display("!!OUT=%h", c);
		$finish;
	end
endmodule

//module rotate1(x, k, o);
//	input  [31:0] x, k;
//	output [31:0] o;
//
//	assign o = (x << k) ^ (x >> (32 - k));
//endmodule
//
//module mix(ia, ib, ic, oa, ob, oc);
//	input  [31:0] ia, ib, ic;
//	output [31:0] oa, ob, oc;
//
//	wire [31:0] ia, ib, ic, oa, ob, oc;
//endmodule
//
