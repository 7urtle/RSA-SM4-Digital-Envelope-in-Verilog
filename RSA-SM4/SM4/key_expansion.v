  module key_expansion (
    input clk,rst_n,
    input [127:0] mkey, //母密钥
    input key_exp_start, //与母密钥信号对齐,1周期
    input [4:0]ikey_cnt, //子密钥序号
    output [31:0] ikey, //子密钥
    output key_exp_done
  );

  localparam FK0 = 32'ha3b1bac6;
  localparam FK1 = 32'h56aa3350;
  localparam FK2 = 32'h677d9197;
  localparam FK3 = 32'hb27022dc;

  localparam IDLE    = 1'b0;
  localparam WORKING = 1'b1;
  
  //  -  -  -  -  -  -  -  -  - 密钥扩展轮函数输入控制 -  -  -  -  -  -  -  -  -  -  -  -  -

  reg state;
  reg  [4:0]    round_cnt;
  reg  [127:0]  round_in;
  wire [31:0]   cki;
  wire          key_exp_trigger;
  wire [127:0]  round_out;

  assign key_exp_done = (state == WORKING)&&(round_cnt == 5'd31);
  assign key_exp_trigger = (state == IDLE)&&(key_exp_start);


  always @(posedge clk or negedge rst_n) begin // 工作状态
    if(!rst_n)begin
        state <= IDLE;
    end
    else if (round_cnt == 5'd31) begin
        state <= IDLE;
    end
    else if (key_exp_start) begin
        state <= WORKING;
    end
    else state <= state;
  end

  always @(posedge clk or negedge rst_n) begin //轮数统计
    if (!rst_n) begin
        round_cnt <= 0;
    end
    else if (round_cnt == 5'd31) begin
        round_cnt <= 5'd0;
    end 
    else begin
        if(state == WORKING)begin
            round_cnt <= round_cnt + 1;
        end
    end
  end

  always @(posedge clk or negedge rst_n) begin //输入控制
    if(!rst_n)
        round_in <= 128'b0;
    else if (key_exp_trigger) 
        round_in <= (mkey ^ {FK0,FK1,FK2,FK3});
    else if(state == WORKING) 
        round_in <= round_out;
    else 
        round_in <= round_in;
  end
//  -  -  -  -  -  -  -  -  - 轮密钥RAM控制 -  -  -  -  -  -  -  -  -  -  -  -  -
  wire [4:0]  rki_ram_addr; 
  wire [31:0] rki_ram_din;
  wire        rki_ram_wea;
  wire        rki_ram_ena;
  wire [31:0] rki_ram_dout;

  assign rki_ram_addr = (state == WORKING)?round_cnt:ikey_cnt;
  assign rki_ram_din  = round_out[31:0];
  assign rki_ram_wea  = (state == WORKING);
  assign rki_ram_ena  = 1'b1; //(state == WORKING) || 读取信号 ;
  assign ikey = rki_ram_dout;


  keyexp_round  keyexp_round_inst (
    .round_in(round_in),
    .round_cki(cki),
    .round_out(round_out)
  );
  get_cki  get_cki_inst (
    .round_cnt(round_cnt),
    .cki(cki)
  );
  rki_ram rki_ram (
            .clka   (clk         ),    // input wire clka
            .ena    (rki_ram_ena ),    // input wire ena
            .wea    (rki_ram_wea ),    // input wire [0 : 0] wea
            .addra  (rki_ram_addr),    // input wire [4 : 0] addra
            .dina   (rki_ram_din ),    // input wire [31 : 0] dina
            .douta  (rki_ram_dout)     // output wire [31 : 0] douta
          );

endmodule //key_expansion

