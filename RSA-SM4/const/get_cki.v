module get_cki(
    input [4:0] round_cnt,
    output reg [31:0] cki
);
 
always@(*)
	case(round_cnt)
	5'h00: cki <= 32'h00070e15;
	5'h01: cki <= 32'h1c232a31;
	5'h02: cki <= 32'h383f464d;
	5'h03: cki <= 32'h545b6269;
	5'h04: cki <= 32'h70777e85;
	5'h05: cki <= 32'h8c939aa1;
	5'h06: cki <= 32'ha8afb6bd;
	5'h07: cki <= 32'hc4cbd2d9;
	5'h08: cki <= 32'he0e7eef5;
	5'h09: cki <= 32'hfc030a11;
	5'h0a: cki <= 32'h181f262d;
	5'h0b: cki <= 32'h343b4249;
	5'h0c: cki <= 32'h50575e65;
	5'h0d: cki <= 32'h6c737a81;
	5'h0e: cki <= 32'h888f969d;
	5'h0f: cki <= 32'ha4abb2b9;
	5'h10: cki <= 32'hc0c7ced5;
	5'h11: cki <= 32'hdce3eaf1;
	5'h12: cki <= 32'hf8ff060d;
	5'h13: cki <= 32'h141b2229;
	5'h14: cki <= 32'h30373e45;
	5'h15: cki <= 32'h4c535a61;
	5'h16: cki <= 32'h686f767d;
	5'h17: cki <= 32'h848b9299;
	5'h18: cki <= 32'ha0a7aeb5;
	5'h19: cki <= 32'hbcc3cad1;
	5'h1a: cki <= 32'hd8dfe6ed;
	5'h1b: cki <= 32'hf4fb0209;
	5'h1c: cki <= 32'h10171e25;
	5'h1d: cki <= 32'h2c333a41;
	5'h1e: cki <= 32'h484f565d;
	5'h1f: cki <= 32'h646b7279;
	default: cki <= 32'h0;
	endcase
endmodule