module sm4_top (
    input           clk,
    input           rst_n,
    input  [1:0]    cmd,   //       00:invalid  01:key_expansion
    input  [127:0]  sm4_in,//       10:encrypt  11:decrypt
    output [127:0]  sm4_out,
    output          res_vld//       result_valid for 1clk , rsp when key_exp , sync when en/de. 
  );

 //  -  -  -  -  -  -  -  -  - Key_exp control (kxp) -  -  -  -  -  -  -  -  -  -  -  -  -
  localparam KXP_IDLE    = 2'b00; 
  localparam KXP_WORKING = 2'b01;
  localparam KXP_DONE    = 2'b10;

  wire [127:0]  mkey;
  wire          key_exp_start;
  wire          key_exp_done;

  reg  [1:0]    kxp_state;
  reg           kxp_done; //lock reg
  reg           kxp_rsp;  //rsp  reg

  assign mkey = (cmd == 2'b01)? sm4_in : 128'b0;
  assign key_exp_start = (cmd == 2'b01) && (kxp_state != KXP_WORKING);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      kxp_state <= KXP_IDLE;
      kxp_done  <= 1'b0;
      kxp_rsp   <= 1'b0;
    end
    else begin
      case (kxp_state)
          KXP_IDLE: begin
              if (key_exp_start) 
                  kxp_state <= KXP_WORKING;
              else kxp_state <= kxp_state;
          end
          KXP_WORKING: begin
              if(key_exp_done) begin
                  kxp_state <= KXP_DONE;
                  kxp_done <= 1'b1;
                  kxp_rsp  <= 1'b1;
              end
              else begin
                  kxp_state <= kxp_state;
                  kxp_done <= 1'b0;
                  kxp_rsp  <= 1'b0;
              end 
          end
          KXP_DONE:begin
              kxp_rsp  <= 1'b0;
              kxp_done <= 1'b1;
              if(key_exp_start)begin
                  kxp_state <= KXP_WORKING;
                  kxp_done <= 1'b0;
              end
              else kxp_state <= kxp_state;
          end
      endcase
    end
  end



//  -  -  -  -  -  -  -  -  - en/decrypt control (EDC) -  -  -  -  -  -  -  -  -  -  -  -  -
  localparam EDC_IDLE        = 3'd1;
  localparam EDC_ENCRYPTING  = 3'd2;
  localparam EDC_DECRYPTING  = 3'd3;
  localparam EDC_INVERSING   = 3'd4;
  localparam EDC_OUTPUT      = 3'd5;
  
  wire [31:0]   ikey;
  wire          enc_start;
  wire          dec_start;
  wire [31:0]   edc_round_rki;
  wire [127:0]  edc_round_out;
  wire [127:0]  edc_round_in;
  reg  [4:0]    ikey_cnt;
  reg  [127:0]  r_edc_round_in_d1;
  reg  [4:0]    ikey_encnt;
  reg  [4:0]    ikey_decnt;
  reg  [2:0]    edc_state;
  reg  [127:0]  edc_output;
  reg           edc_outsync;

  assign enc_start    = kxp_done && (cmd == 2'b10);
  assign dec_start    = kxp_done && (cmd == 2'b11);
  assign edc_round_rki= ikey;
  assign edc_round_in = r_edc_round_in_d1;
  assign sm4_out      = edc_output;

  always @(*) begin                                     //加解密轮数整合
      if(cmd == 2'b10 || edc_state == EDC_ENCRYPTING)
        ikey_cnt = ikey_encnt;
      else
        ikey_cnt = ikey_decnt;
  end

  always @(posedge clk or negedge rst_n) begin //输入延时1
      if (!rst_n) begin
        r_edc_round_in_d1 <= 128'b0;
      end
      else if(enc_start||dec_start)begin
        r_edc_round_in_d1 <= sm4_in;
      end
      else if((edc_state == EDC_ENCRYPTING) ||(edc_state == EDC_DECRYPTING) ) begin
        r_edc_round_in_d1 <= edc_round_out;
      end
      else begin
        r_edc_round_in_d1 <= 128'b0;
      end
    end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ikey_encnt <= 5'd0;
      ikey_decnt <= 5'd31;
      edc_state  <= EDC_IDLE;
      edc_outsync <= 1'b0;
    end
    else begin
      case (edc_state)
        EDC_IDLE:begin
          if(enc_start)begin
            edc_state <= EDC_ENCRYPTING;
            ikey_encnt <= ikey_encnt + 1;
          end
          else if(dec_start)begin
            edc_state <= EDC_DECRYPTING;
            ikey_decnt <= ikey_decnt - 1;
          end
          else begin
            ikey_encnt <= 5'd0;
            ikey_decnt <= 5'd31;
            edc_state <= edc_state;
          end
        end
        EDC_ENCRYPTING:begin
          if(ikey_encnt == 5'd31)begin
            edc_state   <= EDC_INVERSING;
            ikey_encnt  <= 5'd0;
          end
          else begin
            edc_state   <= edc_state;
            ikey_encnt  <= ikey_encnt + 5'd1;
          end
        end
        EDC_DECRYPTING:begin
          if(ikey_decnt == 5'd0)begin
            edc_state   <= EDC_INVERSING;
            ikey_decnt  <= 5'd31;
          end
          else begin
            edc_state   <= edc_state;
            ikey_decnt  <= ikey_decnt - 5'd1;
          end
        end
        EDC_INVERSING :begin
          edc_state <= EDC_OUTPUT;
          edc_output<= {edc_round_out[31:0],edc_round_out[63:32],edc_round_out[95:64],edc_round_out[127:96]};
          edc_outsync <= 1'b1;
        end
        EDC_OUTPUT    :begin
          edc_outsync <= 1'b0;
          edc_state   <= EDC_IDLE;
        end
      endcase
    end
  end
  
//  -  -  -  -  -  -  -  -  - bus control -  -  -  -  -  -  -  -  -  -  -  -  -
  assign res_vld = kxp_rsp || edc_outsync;



  key_expansion  key_expansion_inst (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .mkey           (mkey           ),//128
    .key_exp_start  (key_exp_start  ),
    .ikey_cnt       (ikey_cnt       ),//5 - edc variable
    .ikey           (ikey           ),//32- edc variable
    .key_exp_done   (key_exp_done   )
  );

  encdec_round  encdec_round_inst (
    .round_in   (edc_round_in ),//128
    .round_rki  (edc_round_rki),//32
    .round_out  (edc_round_out) //128
  );
endmodule //sm4_top
