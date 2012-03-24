`define STEP 2
`define dbg  1

module sim();
reg       tb_enable = 1'b0;
reg[7:0]  tb_key_length;
reg[31:0] tb_k0, tb_k1, tb_k2;

wire CLK;
wire RST;
wire[31:0] tb_hashkey;
wire tb_complete;

clock clock (
  .CLK(CLK),
  .RST(RST)
);

lookup3 lookup3 (
  .CLK(CLK)
, .RST(RST)
, .key_length(tb_key_length)
, .k0(tb_k0)
, .k1(tb_k1)
, .k2(tb_k2)
, .hashkey(tb_hashkey)
);

initial begin
  //$monitor("state: %d", lookup2.state);
  #100 tb_enable = 1'b1; tb_key_length = 4'hd; tb_k0 = "abcd"; tb_k1 = "efgh"; tb_k2 = "ijkl";
  #100 tb_enable = 1'b1; tb_key_length = 4'hd; tb_k0 = "abcd"; tb_k1 = "efgh"; tb_k2 = "ijkl";
  #100 tb_enable = 1'b1; tb_key_length = 4'hd; tb_k0 = "abcd"; tb_k1 = "efgh"; tb_k2 = "ijkl";
  #100 $finish;
end

initial begin
  $dumpfile("lookup3.vcd");
  $dumpvars(0, sim.lookup3);
end

always @(posedge CLK) begin
  if (RST)
    tb_enable <= 1'b0;
  else begin
    if (tb_hashkey)
      $display("key: %s, hashkey: %h", {tb_k0, tb_k1, tb_k2}, tb_hashkey);
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

module hash_r1 (
  input CLK
, input RST
, input [31:0] ia
, input [31:0] ib
, input [31:0] ic
, input [31:0] k0
, input [31:0] k1
, input [31:0] k2
, input [7:0]  iw
, output reg[31:0] oa
, output reg[31:0] ob
, output reg[31:0] oc
, output reg[7:0]  ow
);

reg[31:0] a0, b0, c0;
reg[31:0] a1, b1, c1;
reg[31:0] a2, b2, c2;
reg[31:0] a3, b3, c3;
reg[7:0]  w0, w1, w2, w3, w4;

wire[7:0]  next_w0 = (iw > 12) ? iw - 12 : iw;
wire[31:0] next_a0 = ia + k0;
wire[31:0] next_b0 = ib + k1;
wire[31:0] next_c0 = ic + k2;
wire[31:0] next_a1 = (a0 - c0) ^ {c0[27:0], c0[31:28]};
wire[31:0] next_c1 = c0 + b0;
wire[31:0] next_a2 = a1 + c1;
wire[31:0] next_c2 = (c1 - b1) ^ {b1[23:0], b1[31:24]};
wire[31:0] next_a3 = (a2 - c2) ^ {c2[15:0], c2[31:16]};
wire[31:0] next_c3 = c2 + b2;
wire[31:0] next_a4 = a3 + c3;
wire[31:0] next_c4 = (c3 - b3) ^ {b3[27:0], b3[31:28]};

always @(posedge CLK) begin
  if (RST) begin
    oa <= 32'b0;
    ob <= 32'b0;
    oc <= 32'b0;
    ow <= 7'b0;
  end else begin
    a0 <= next_a0;
    c0 <= next_c0;
    b0 <= next_b0;
    w0 <= next_w0;
    a1 <= next_a1;
    c1 <= next_c1;
    b1 <= (b0 - next_a1) ^ {next_a1[25:0], next_a1[31:26]};
    w1 <= w0;
    a2 <= next_a2;
    c2 <= next_c2;
    b2 <= b1 + next_a2;
    w2 <= w1;
    a3 <= next_a3;
    c3 <= next_c3;
    b3 <= (b2 - next_a3) ^ {next_a3[12:0], next_a3[31:13]};
    w3 <= w2;
    oa <= next_a4;
    ob <= next_c4;
    oc <= b3 + next_a4;
    ow <= w3;
  end
end
endmodule

module hash_r2 (
  input CLK
, input RST
, input [31:0] ia
, input [31:0] ib
, input [31:0] ic
, input [31:0] k0
, input [31:0] k1
, input [31:0] k2
, input [7:0]  wc
, output reg[31:0] o
);

reg complete;

reg[31:0] a0, b0, c0;
reg[31:0] a1, b1, c1;
reg[31:0] a2, b2, c2;

wire[31:0] next_c1 = (c0 ^ b0) - {b0[17:0], b0[31:18]};
wire[31:0] next_a1 = (a0 ^ next_c1) - {next_c1[20:0], next_c1[31:21]};
wire[31:0] next_c2 = (c1 ^ b1) - {b1[15:0], b1[31:16]};
wire[31:0] next_a2 = (a1 ^ next_c2) - {next_c2[27:0], next_c2[31:28]};

always @(posedge CLK) begin
  if (RST)
    o  <= 1'b0;
  else begin
    c0 <= next_c0;
    a0 <= next_a0;
    b0 <= next_b0;
    c1 <= next_c1;
    a1 <= next_a1;
    b1 <= (b0 ^ next_a1) - {next_a1[6:0], next_a1[31:7]};
    c2 <= next_c2;
    a2 <= next_a2;
    b2 <= (b1 ^ next_a2) - {next_a2[17:0], next_a2[31:18]};
    o  <= (c2 ^ b2) - {b2[7:0], b2[31:8]};
  end
end

reg[31:0] next_a0, next_b0, next_c0;
always @* begin
  case (wc)
    4'hc: begin
      next_c0 <= ic + k2;
      next_b0 <= ib + k1;
      next_a0 <= ia + k0;
    end
    4'hb: begin
      next_c0 <= ic + k2 & 32'hFFFFFF00;
      next_b0 <= ib + k1;
      next_a0 <= ia + k0;
    end
    4'ha: begin
      next_c0 <= ic + k2 & 32'hFFFF0000;
      next_b0 <= ib + k1;
      next_a0 <= ia + k0;
    end
    4'h9: begin
      next_c0 <= ic + k2 & 32'hFF000000;
      next_b0 <= ib + k1;
      next_a0 <= ia + k0;
    end
    4'h8: begin
      next_c0 <= ic;
      next_b0 <= ib + k1;
      next_a0 <= ia + k0;
    end
    4'h7: begin
      next_c0 <= ic;
      next_b0 <= ib + k1 & 32'hFFFFFF00;
      next_a0 <= ia + k0;
    end
    4'h6: begin
      next_c0 <= ic;
      next_b0 <= ib + k1 & 32'hFFFF0000;
      next_a0 <= ia + k0;
    end
    4'h5: begin
      next_c0 <= ic;
      next_b0 <= ib + k1 & 32'hFF000000;
      next_a0 <= ia + k0;
    end
    4'h4: begin
      next_c0 <= ic;
      next_b0 <= ib;
      next_a0 <= ia + k0;
    end
    4'h3: begin
      next_c0 <= ic;
      next_b0 <= ib;
      next_a0 <= ia + k0 & 32'hFFFFFF00;
    end
    4'h2: begin
      next_c0 <= ic;
      next_b0 <= ib;
      next_a0 <= ia + k0 & 32'hFFFF0000;
    end
    4'h1: begin
      next_c0 <= ic;
      next_b0 <= ib;
      next_a0 <= ia + k0 & 32'hFF000000;
    end
    4'h0: begin
      next_c0  <= ic;
      next_b0  <= ib;
      next_a0  <= ia;
      complete <= 1'b1;
    end
  endcase
end

endmodule

module lookup3 (
  input CLK
, input RST
, input [7:0]  key_length //from memcache protocol header
, input [31:0] k0
, input [31:0] k1
, input [31:0] k2
, output reg[31:0] hashkey
);

parameter interval = 0;       //tmp

wire[31:0] a0 = k0 + 32'hDEADBEEF + key_length + interval;
wire[31:0] b0 = k1 + 32'hDEADBEEF + key_length + interval;
wire[31:0] c0 = k2 + 32'hDEADBEEF + key_length + interval;
wire[7:0]  w0 = key_length;

wire[31:0] a1, b1, c1;
wire[31:0] a2, b2, c2;
wire[31:0] a3, b3, c3;
wire[31:0] a4, b4, c4;
wire[31:0] a5, b5, c5;
wire[31:0] a6, b6, c6;
wire[31:0] a7, b7, c7;
wire[31:0] a8, b8, c8;
wire[31:0] a9, b9, c9;
wire[31:0] a10, b10, c10;
wire[31:0] a11, b11, c11;
wire[31:0] a12, b12, c12;
wire[31:0] a13, b13, c13;
wire[31:0] a14, b14, c14;
wire[31:0] a15, b15, c15;
wire[31:0] a16, b16, c16;
wire[31:0] a17, b17, c17;
wire[31:0] a18, b18, c18;
wire[31:0] a19, b19, c19;
wire[31:0] a20, b20, c20;
wire[31:0] a21, b21, c21;
wire[31:0] o;

wire[7:0] w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12,
          w13, w14, w15, w16, w17, w18, w19, w20, w21;

hash_r1 round1 (CLK, RST, a0, b0, c0, k0, k1, k2, w0, a1, b1, c1, w1);
hash_r1 round2 (CLK, RST, a1, b1, c1, k0, k1, k2, w1, a2, b2, c2, w2);
hash_r1 round3 (CLK, RST, a2, b2, c2, k0, k1, k2, w2, a3, b3, c3, w3);
hash_r1 round4 (CLK, RST, a3, b3, c3, k0, k1, k2, w3, a4, b4, c4, w4);
hash_r1 round5 (CLK, RST, a4, b4, c4, k0, k1, k2, w4, a5, b5, c5, w5);
hash_r1 round6 (CLK, RST, a5, b5, c5, k0, k1, k2, w5, a6, b6, c6, w6);
hash_r1 round7 (CLK, RST, a6, b6, c6, k0, k1, k2, w6, a7, b7, c7, w7);
hash_r1 round8 (CLK, RST, a7, b7, c7, k0, k1, k2, w7, a8, b8, c8, w8);
hash_r1 round9 (CLK, RST, a8, b8, c8, k0, k1, k2, w8, a9, b9, c9, w9);
hash_r1 round10 (CLK, RST, a9, b9, c9, k0, k1, k2, w9, a10, b10, c10, w10);
hash_r1 round11 (CLK, RST, a10, b10, c10, k0, k1, k2, w10, a11, b11, c11, w11);
hash_r1 round12 (CLK, RST, a11, b11, c11, k0, k1, k2, w11, a12, b12, c12, w12);
hash_r1 round13 (CLK, RST, a12, b12, c12, k0, k1, k2, w12, a13, b13, c13, w13);
hash_r1 round14 (CLK, RST, a13, b13, c13, k0, k1, k2, w13, a14, b14, c14, w14);
hash_r1 round15 (CLK, RST, a14, b14, c14, k0, k1, k2, w14, a15, b15, c15, w15);
hash_r1 round16 (CLK, RST, a15, b15, c15, k0, k1, k2, w15, a16, b16, c16, w16);
hash_r1 round17 (CLK, RST, a16, b16, c16, k0, k1, k2, w16, a17, b17, c17, w17);
hash_r1 round18 (CLK, RST, a17, b17, c17, k0, k1, k2, w17, a18, b18, c18, w18);
hash_r1 round19 (CLK, RST, a18, b18, c18, k0, k1, k2, w18, a19, b19, c19, w19);
hash_r1 round20 (CLK, RST, a19, b19, c19, k0, k1, k2, w19, a20, b20, c20, w20);
hash_r1 round21 (CLK, RST, a20, b20, c20, k0, k1, k2, w20, a21, b21, c21, w21);
hash_r2 round22 (CLK, RST, a21, b21, c21, k0, k1, k2, w21, o);

always @(posedge CLK) begin
  if (RST)
    hashkey <= 32'hFFFFFFFF;
  else
    hashkey <= o;
end
endmodule

