module hello2();
reg [8*16:0] stringA;
initial begin
	stringA = "Hello World";
	$display("%s is stored as %h", stringA, stringA);
	stringA = {stringA,"!!!"};
	$display("%s is stored as %h", stringA, stringA);
end
endmodule
