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

mix mix (
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
  $dumpfile("mix.vcd");
  $dumpvars(0, sim.mix);
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

endmodule // sim()

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

module mix (
  input  CLK,
  input  RST,
  input  enable,
  input  [639:0] key,
  output wire[31:0] hashkey
);

parameter[1:0] s0 = 2'b00, //idle
               s1 = 2'b01;
parameter length   = 0;
parameter interval = 0;

reg[2:0]   state;
reg[31:0]  a0, b0, c0, a1, b1, c1, a2, b2, c2,
           a3, b3, c3, a4, b4, c4;
wire[31:0] next_a1, next_c1, next_a2, next_c2,
           next_a3, next_c3, next_a4, next_c4;

wire[31:0] k0      = key[95:64];
wire[31:0] k1      = key[63:32];
wire[31:0] k2      = key[31:0];
wire[31:0] next_a0 = 32'hDEADBEEF + length + interval;
wire[31:0] next_b0 = 32'hDEADBEEF + length + interval;
wire[31:0] next_c0 = 32'hDEADBEEF + length + interval;

assign next_a1 = (a0 - c0) ^ {c0[27:0], c0[31:28]};
assign next_c1 = c0 + b0;
assign next_a2 = a1 + c1;
assign next_c2 = (c1 - b1) ^ {b1[23:0], b1[31:24]};
assign next_a3 = (a2 - c2) ^ {c2[15:0], c2[31:16]};
assign next_c3 = c2 + b2;
assign next_a4 = a3 + c3;
assign next_c4 = (c3 - b3) ^ {b3[27:0], b3[31:28]};

assign hashkey = c4;

always @(posedge CLK) begin
  if (RST)
    state <= s0;
  else begin
    a0 <= next_a0 + k0;
    b0 <= next_b0 + k1;
    c0 <= next_c0 + k2;
    a1 <= next_a1;
    c1 <= next_c1;
    b1 <= (b0 - next_a1) ^ {next_a1[25:0], next_a1[31:26]};
    a2 <= next_a2;
    c2 <= next_c2;
    b2 <= b1 + next_a2;
    a3 <= next_a3;
    c3 <= next_c3;
    b3 <= (b2 - next_a3) ^ {next_a3[12:0], next_a3[31:13]};
    a4 <= next_a4;
    c4 <= next_c4;
    b4 <= b3 + next_a4;

    state <= s0;
  end
end

always @*
  if (enable)
    state <= s1;

endmodule

module final (

