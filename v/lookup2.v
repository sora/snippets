`define STEP 2
`define dbg  1

module sim();

reg        tb_enable = 1'b0;
reg[639:0] tb_key;

wire CLK;
wire RST;
wire[31:0] tb_hashkey;

clock clock (
  .CLK(CLK),
  .RST(RST)
);

lookup2 lookup2 (
  .CLK(CLK),
  .RST(RST),
  .enable(tb_enable),
  .key(tb_key),
  .hashkey(tb_hashkey)
);

initial begin
  //$monitor("state: %d", lookup2.state);
  #100 tb_enable = 1'b1; tb_key = "abcdefghijkl";
  #100 tb_enable = 1'b1; tb_key = "abcdefghijkl";
  #100 tb_enable = 1'b1; tb_key = "abcdefghijkl";
  #100 $finish;
end

initial begin
  $dumpfile("lookup2.vcd");
  $dumpvars(0, sim.lookup2);
end

always @(posedge CLK) begin
  if (RST)
    tb_enable <= 1'b0;
  else begin
    if (tb_hashkey)
      $display("key: %s, hashkey: %h", tb_key, tb_hashkey);
      $display("%x, %x, %x", tb_key[95:64], tb_key[63:32], tb_key[31:0]);
    if (tb_enable)
      tb_enable <= 1'b0;
  end
end

endmodule

module clock (
  output reg CLK,
  output reg RST
);

initial CLK = 0;
initial RST = 0;
always #(`STEP / 2) begin
  CLK <= ~CLK;
  RST <= 0;
end
endmodule

module lookup2 (
  input  CLK,
  input  RST,
  input  enable,
  input  [639:0] key,
  output wire[31:0] hashkey
);

parameter[1:0] s0 = 2'b00, //idle
               s1 = 2'b01;

reg[2:0]   state;
reg[31:0]  a1, b1, c1, a2, b2, c2, a3, b3, c3;
wire[31:0] next_a0, next_b0, next_c0,
           next_a1, next_b1, next_c1,
           next_a2, next_b2, next_c2,
           next_a3, next_b3, next_c3;

reg[31:0] a0 = 32'h9e3779b9;
reg[31:0] b0 = 32'h9e3779b9;
reg[31:0] c0 = 32'hdeadbeef;

wire[31:0] k0 = key[95:64];
wire[31:0] k1 = key[63:32];
wire[31:0] k2 = key[31:0];
//wire[31:0] k0 = { key[7:0], key[15:8], key[23:16], key[31:24] };
//wire[31:0] k1 = { key[7:0], key[15:8], key[23:16], key[31:24] };
//wire[31:0] k2 = { key[7:0], key[15:8], key[23:16], key[31:24] };

//assign next_a0 = {1'b0, a0} + {1'b0, k0};
assign next_a0 = a0 + k0;
assign next_b0 = b0 + k1;
assign next_c0 = c0 + k2;

assign next_a1 = (next_a0 - next_b0 - next_c0) ^ (next_c0 >> 13);
assign next_b1 = (next_b0 - next_c0 - next_a1) ^ (next_a1 << 8);

assign next_a2 = (a1 - b1 - c1) ^ (c1 >> 12);
assign next_b2 = (b1 - c1 - next_a2) ^ (next_a2 << 16);

assign next_a3 = (a2 - b2 - c2) ^ (c2 >> 3);
assign next_b3 = (b2 - c2 - next_a3) ^ (next_a3 << 10);

assign hashkey = c3;

always @(posedge CLK) begin
  if (RST) begin
    state <= s0;
  end
  else begin
    a1 <= next_a1;
    b1 <= next_b1;
    c1 <= (c0 - b0 - next_a1) ^ (next_b1 >> 13);
    a2 <= next_a2;
    b2 <= next_b2;
    c2 <= (c1 - b1 - next_a2) ^ (next_b2 >> 5);
    a3 <= next_a3;
    b3 <= next_b3;
    c3 <= (c2 - b2 - next_a3) ^ (next_b3 >> 15);
    state <= s0;
  end
end

always @*
  if (enable)
    state <= s1;

endmodule

