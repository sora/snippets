`define STEP 2

module sim();

reg tb_enable = 1'b0;

reg[31:0] tb_oa;
reg[31:0] tb_ob;
reg[31:0] tb_oc;
wire CLK;
wire RST;
wire[31:0] oa;
wire[31:0] ob;
wire[31:0] oc;

clock clock (
  .CLK(CLK),
  .RST(RST)
);

lookup2 lookup2 (
  .CLK(CLK),
  .RST(RST),
  .enable(tb_enable),
  .a3(oa),
  .b3(ob),
  .c3(oc)
);

initial begin
  $monitor("state: %d", lookup2.state);
  #100 tb_enable = 1'b1;
end

initial begin
  $dumpfile("lookup2.vcd");
  $dumpvars(0, sim.lookup2);
end

always @(posedge CLK) begin
  if (RST)
    tb_enable <= 1'b0;
  else begin
    $display("------------");
    if (oa && ob && oc) begin
      $display("oa: %h", oa);
      $display("ob: %h", ob);
      $display("oc: %h", oc);
    end
    if (tb_enable == 1'b1)
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
  output reg[31:0] a3,
  output reg[31:0] b3,
  output reg[31:0] c3
);

parameter[2:0] s0 = 3'b000,
               s1 = 3'b001,
               s2 = 3'b010,
               s3 = 3'b011;

reg[2:0]   state;
reg[31:0]  a1, b1, c1, a2, b2, c2;
wire[31:0] next_a1, next_b1, next_c1,
           next_a2, next_b2, next_c2,
           next_a3, next_b3, next_c3;

wire[31:0] a0 = 32'h9e3779b9;
wire[31:0] b0 = 32'h9e3779b9;
wire[31:0] c0 = 32'hdeadbeef;

assign next_a1 = (a0 - b0 - c0) ^ (c0 >> 13);
assign next_b1 = (b0 - c0 - next_a1) ^ (a0 << 8);
assign next_a2 = (a1 - b1 - c1) ^ (c1 >> 12);
assign next_b2 = (b1 - c1 - next_a2) ^ (a1 << 16);
assign next_a3 = (a2 - b2 - c2) ^ (c2 >> 3);
assign next_b3 = (b2 - c2 - next_a3) ^ (a2 << 10);

always @(posedge CLK) begin
  if (RST) begin
    state <= s0;
  end
  else begin
    case (state)
      s1: begin
        a1 <= next_a1;
        b1 <= next_b1;
        c1 <= (c0 - b0 - next_a1) ^ (next_b1 >> 13);
        state <= s2;
      end
      s2: begin
        a2 <= next_a2;
        b2 <= next_b2;
        c2 <= (c1 - b1 - next_a2) ^ (next_b2 >> 5);
        state <= s3;
      end
      s3: begin
        a3 <= next_a3;
        b3 <= next_b3;
        c3 <= (c2 - b2 - next_a3) ^ (next_b3 >> 15);
      end
    endcase
    if (enable)
      state <= s1;
  end
end

endmodule

