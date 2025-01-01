//encdec round function for 1 loop
//https://imgur.com/a/dec-enc-round-cW2r3rM
// IN  : {Ki-Ki+3}
// Out : {Ki+1-Ki+4}

module encdec_round ( 
    input	  [127:0]		round_in,
    input	  [31:0]		round_rki,
    output	[127:0]		round_out
  );

  wire [31:0] K0,K1,K2,K3;
  wire [31:0] transform_din;
  wire [31:0] transform_dout;
  wire [7:0] sbox_in0,sbox_in1,sbox_in2,sbox_in3;
  wire [7:0] sbox_out0,sbox_out1,sbox_out2,sbox_out3;
  wire [31:0] sbox_wout={sbox_out0,sbox_out1,sbox_out2,sbox_out3};

  assign {K0,K1,K2,K3} = round_in;
  assign transform_din = K1^K2^K3^round_rki;
  assign {sbox_in0,sbox_in1,sbox_in2,sbox_in3}=transform_din;
  assign transform_dout = ((sbox_wout^{sbox_wout[29:0],sbox_wout[31:30]})^({sbox_wout[21:0],sbox_wout[31:22]}^{sbox_wout[13:0],sbox_wout[31:14]}))^{sbox_wout[7:0],sbox_wout[31:8]};
  assign round_out = {K1,K2,K3,transform_dout^K0};

  s_box  s_box_inst_0 (
           .s_in(sbox_in0),
           .s_out(sbox_out0)
         );

  s_box  s_box_inst_1 (
           .s_in(sbox_in1),
           .s_out(sbox_out1)
         );

  s_box  s_box_inst_2 (
           .s_in(sbox_in2),
           .s_out(sbox_out2)
         );

  s_box  s_box_inst_3 (
           .s_in(sbox_in3),
           .s_out(sbox_out3)
         );

endmodule //Encdec_round

