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
  .CLK(CLK),
  .RST(RST),
  .enable(tb_enable),
  .key_length(tb_key_length),
  .k0(tb_k0),
  .k1(tb_k1),
  .k2(tb_k2),
  .hashkey(tb_hashkey),
  .complete(tb_complete)
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

module lookup3 (
  input  CLK,
  input  RST,
  input  enable,
  input  [7:0]  key_length, // from memcache header
  input  [31:0] k0,
  input  [31:0] k1,
  input  [31:0] k2,
  output reg[31:0] hashkey,
  output reg complete
);

parameter[2:0] s0 = 3'b000, // init
               s1 = 3'b001,
               s2 = 3'b010,
               s3 = 3'b011,
               s4 = 3'b100;
parameter length   = 0; //tmp
parameter interval = 0; //tmp

reg[2:0] state = s0;

reg[31:0] a, b, c;
reg[31:0] a0, b0, c0;
reg[31:0] a1, b1, c1;
reg[31:0] a2, b2, c2;
reg[31:0] a3, b3, c3;
reg[31:0] a4, b4, c4;
reg[31:0] a5, b5, c5;
reg[31:0] a6, b6, c6;
reg[31:0] a7, b7, c7;
reg[31:0] a8, b8, c8;
reg[31:0] a9, b9, c9;
reg[31:0] a10, b10, c10;
reg[3:0] wc0, wc1, wc2, wc3, wc4, wc5;

wire[3:0]  wcmod12 = key_length % 12;
wire[31:0] magic   = 32'hDEADBEEF + key_length + interval;

/* mix1 */
wire[31:0] next_a0 = a + k0;
wire[31:0] next_b0 = b + k1;
wire[31:0] next_c0 = c + k2;
wire[3:0]  next_wc0 = key_length % 12;
wire[31:0] next_a1 = (a0 - c0) ^ {c0[27:0], c0[31:28]};
wire[31:0] next_c1 = c0 + b0;
wire[31:0] next_a2 = a1 + c1;
wire[31:0] next_c2 = (c1 - b1) ^ {b1[23:0], b1[31:24]};
wire[31:0] next_a3 = (a2 - c2) ^ {c2[15:0], c2[31:16]};
wire[31:0] next_c3 = c2 + b2;
wire[31:0] next_a4 = a3 + c3;
wire[31:0] next_c4 = (c3 - b3) ^ {b3[27:0], b3[31:28]};
/* final */
wire[31:0] next_c6 = (c5 ^ b5) - {b5[17:0], b5[31:18]};
wire[31:0] next_a6 = (a5 ^ next_c6) - {next_c6[20:0], next_c6[31:21]};
wire[31:0] next_c7 = (c6 ^ b6) - {b6[15:0], b6[31:16]};
wire[31:0] next_a7 = (a6 ^ next_c7) - {next_c7[27:0], next_c7[31:28]};

always @(posedge CLK) begin
  if (RST)
    state <= s0;
  else begin
    if (enable) begin
      a <= magic;
      b <= magic;
      c <= magic;
      state <= s1;
    end
    case (state)
      s1: begin
        /* mix1 */
        a0 <= next_a0;
        c0 <= next_c0;
        b0 <= next_b0;
        wc0 <= next_wc0;
        a1 <= next_a1;
        c1 <= next_c1;
        b1 <= (b0 - next_a1) ^ {next_a1[25:0], next_a1[31:26]};
        wc1 <= wc0;
        a2 <= next_a2;
        c2 <= next_c2;
        b2 <= b1 + next_a2;
        wc2 <= wc1;
        a3 <= next_a3;
        c3 <= next_c3;
        b3 <= (b2 - next_a3) ^ {next_a3[12:0], next_a3[31:13]};
        wc3 <= wc2;
        a4 <= next_a4;
        c4 <= next_c4;
        b4 <= b3 + next_a4;
        wc4 <= wc3;
        /* final */
        c5 <= next_c5;
        a5 <= next_a5;
        b5 <= next_b5;
        c6 <= next_c6;
        a6 <= next_a6;
        b6 <= (b5 ^ next_a6) - {next_a6[6:0], next_a6[31:7]};
        c7 <= next_c7;
        a7 <= next_a7;
        b7 <= (b6 ^ next_a7) - {next_a7[17:0], next_a7[31:18]};
        hashkey <= (c7 ^ b7) - {b7[7:0], b7[31:8]};
      end
    endcase
  end
end

reg[31:0] next_a5, next_b5, next_c5;
always @* begin
  case (wc4)
    4'hc: begin
      next_c5 <= c4 + k2;
      next_b5 <= b4 + k1;
      next_a5 <= a4 + k0;
    end
    4'hb: begin
      next_c5 <= c4 + k2 & 32'hFFFFFF00;
      next_b5 <= b4 + k1;
      next_a5 <= a4 + k0;
    end
    4'ha: begin
      next_c5 <= c4 + k2 & 32'hFFFF0000;
      next_b5 <= b4 + k1;
      next_a5 <= a4 + k0;
    end
    4'h9: begin
      next_c5 <= c4 + k2 & 32'hFF000000;
      next_b5 <= b4 + k1;
      next_a5 <= a4 + k0;
    end
    4'h8: begin
      next_c5 <= c4;
      next_b5 <= b4 + k1;
      next_a5 <= a4 + k0;
    end
    4'h7: begin
      next_c5 <= c4;
      next_b5 <= b4 + k1 & 32'hFFFFFF00;
      next_a5 <= a4 + k0;
    end
    4'h6: begin
      next_c5 <= c4;
      next_b5 <= b4 + k1 & 32'hFFFF0000;
      next_a5 <= a4 + k0;
    end
    4'h5: begin
      next_c5 <= c4;
      next_b5 <= b4 + k1 & 32'hFF000000;
      next_a5 <= a4 + k0;
    end
    4'h4: begin
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + k0;
    end
    4'h3: begin
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + k0 & 32'hFFFFFF00;
    end
    4'h2: begin
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + k0 & 32'hFFFF0000;
    end
    4'h1: begin
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + k0 & 32'hFF000000;
    end
    4'h0: begin
      hashkey  <= c4;
      complete <= 1'b1;
    end
  endcase
end

endmodule

