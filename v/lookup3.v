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
  $dumpfile("lookup3.vcd");
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

module lookup3 (
  input  CLK,
  input  RST,
  input  enable,
  input  endofword,
  input  key_length, // from memcache header
  input  [31:0] k0,
  input  [31:0] k1,
  input  [31:0] k2,
  output [31:0] hashkey,
  output reg complete
);

parameter[2:0] s0 = 3'b000, // init
               s1 = 2'b001,
               s2 = 3'b010,
               s3 = 3'b011,
               s4 = 3'b100;
parameter length   = 0;
parameter interval = 0;

reg[2:0]  state = s0;
reg[15:0] wcount;
reg[3:0]  wcmod12;

/* global */
reg[31:0]  a, b, c;
wire[31:0] magic = 32'hDEADBEEF + key_length + interval;

/* mix */
reg[31:0]  a0, b0, c0, a1, b1, c1, a2, b2, c2,
           a3, b3, c3, a4, b4, c4;
wire[31:0] next_a0 = a + k0;
wire[31:0] next_b0 = b + k1;
wire[31:0] next_c0 = c + k2;
wire[31:0] next_a1 = (a0 - c0) ^ {c0[27:0], c0[31:28]};
wire[31:0] next_c1 = c0 + b0;
wire[31:0] next_a2 = a1 + c1;
wire[31:0] next_c2 = (c1 - b1) ^ {b1[23:0], b1[31:24]};
wire[31:0] next_a3 = (a2 - c2) ^ {c2[15:0], c2[31:16]};
wire[31:0] next_c3 = c2 + b2;
wire[31:0] next_a4 = a3 + c3;
wire[31:0] next_c4 = (c3 - b3) ^ {b3[27:0], b3[31:28]};

/* final */
reg[31:0] fk0, fk1, fk2;
reg[31:0] a5, b5, c5, a6, b6, c6, a7, b7, c7;
reg[31:0] next_a5, next_b5, next_c5;
wire[31:0] next_c6 = (c5 ^ b5) - {b5[17:0], b5[31:18]};
wire[31:0] next_a6 = (a5 ^ next_c6) - {next_c6[20:0], next_c6[31:21]};
wire[31:0] next_c7 = (c6 ^ b6) - {b6[15:0], b6[31:16]};
wire[31:0] next_a7 = (a6 ^ next_c7) - {next_c7[27:0], next_c7[31:28]};
wire[31:0] hashkey = (c7 ^ b7) - {b7[7:0], b7[31:8]};

always @(posedge CLK) begin
  if (RST) begin
    state <= s0;
  end else begin
    case (state)
      s0: begin
        a <= magic;
        b <= magic;
        c <= magic;
        state <= s1;
      end
      s1: begin
        a0 <= next_a0;
        c0 <= next_c0;
        b0 <= next_b0;
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
        wcount <= wcount + 12;
      end
      s2: begin
        c5 <= next_c5;
        a5 <= next_a5;
        b5 <= next_b5;
        c6 <= next_c6;
        a6 <= next_a6;
        b6 <= (next_b6 ^ next_a6) - {next_a6[6:0], next_a6[31:7]};
        c7 <= next_c7;
        a7 <= next_a7;
        b7 <= (next_b7 ^ next_a7) - {next_a7[17:0], next_a7[31:18]};
      end
    endcase
  end
end

always @* begin
  if (wcount >= key_length) begin
    state   <= s2;
    wcmod12 <= wcount - key_length;
    fk0     <= k0;
    fk1     <= k1;
    fk2     <= k2;
  end
end

always @* begin
  case (wcmod12)
    32'd12: begin
      next_c5 <= c4 + fk2;
      next_b5 <= b4 + fk1;
      next_a5 <= a4 + fk0;
    end
    32'd11: begin
      next_c5 <= c4 + fk2 & 32'hFFFFFF00;
      next_b5 <= b4 + fk1;
      next_a5 <= a4 + fk0;
    end
    32'd10: begin
      next_c5 <= c4 + fk2 & 32'hFFFF0000;
      next_b5 <= b4 + fk1;
      next_a5 <= a4 + fk0;
    end
    32'd9: begin
      next_c5 <= c4 + fk2 & 32'hFF000000;
      next_b5 <= b4 + fk1;
      next_a5 <= a4 + fk0;
    end
    32'd8: begin
      next_c5 <= c4;
      next_b5 <= b4 + fk1;
      next_a5 <= a4 + fk0;
    end
    32'd7: begin
      next_c5 <= c4;
      next_b5 <= b4 + fk1 & 32'hFFFFFF00;
      next_a5 <= a4 + fk0;
    end
    32'd6: begin
      next_c5 <= c4;
      next_b5 <= b4 + fk1 & 32'hFFFF0000;
      next_a5 <= a4 + fk0;
    end
    32'd5: begin
      next_c5 <= c4;
      next_b5 <= b4 + fk1 & 32'hFF000000;
      next_a5 <= a4 + fk0;
    end
    32'd4:
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + fk0;
    32'd3:
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + fk0 & 32'hFFFFFF00;
    32'd2:
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + fk0 & 32'hFFFF0000;
    32'd1:
      next_c5 <= c4;
      next_b5 <= b4;
      next_a5 <= a4 + fk0 & 32'hFF000000;
    32'd0: begin
      hashkey  <= c4;
      complete <= 1'b1;
    end
  endcase
end

endmodule

