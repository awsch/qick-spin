///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_9
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////
module rx_cmd # (
   parameter CH = 2
)( 
// Core and Com CLK & RST
   input  wire             c_clk_i        ,
   input  wire             c_rst_ni       ,
   input  wire             x_clk_i        ,
   input  wire             x_rst_ni       ,
// XCOM CFG
   input  wire  [3:0]      xcom_id_i      ,
// XCOM CNX
   input  wire             rx_dt_i [CH]   ,
   input  wire             rx_ck_i [CH]   ,
// Command Processing  
   output wire             flg_wr_o     ,
   output wire             reg_wr_o     ,
   output wire             reg_sel_o    ,
   output wire             mem_wr_o     ,
   output wire [15:0]      mem_addr_o   ,
   output wire [15:0]      cmd_dt_o     ,
// DEBUG                   
   output wire [31:0]      xcmd_do     );

wire        rx_req_s  [CH];
wire        rx_ack_s  [CH];
wire [ 3:0] rx_cmd_s  [CH];
wire [31:0] rx_data_s [CH];



genvar ind_rx;
generate
   for (ind_rx=0; ind_rx < CH ; ind_rx=ind_rx+1) begin: RX
      xcom_link_rx LINK (
         .x_clk_i     ( x_clk_i   ),
         .x_rst_ni    ( x_rst_ni  ),
         .xcom_id_i   ( xcom_id_i ),
         .rx_req_o    ( rx_req_s [ind_rx] ),
         .rx_ack_i    ( rx_ack_s [ind_rx] ),
         .rx_cmd_o    ( rx_cmd_s [ind_rx] ),
         .rx_data_o   ( rx_data_s[ind_rx] ),
         .rx_dt_i     ( rx_dt_i  [ind_rx] ),
         .rx_ck_i     ( rx_ck_i  [ind_rx] ),
         .rx_do       (      ) 
      );
  end
endgenerate


///////////////////////////////////////////////////////////////////////////////
// X CLOCK SYNC 
sync_reg # (
   .DW ( CH )
) rx_ack_sync (
   .dt_i      ( cmd_ack     ) ,
   .clk_i     ( x_clk_i     ) ,
   .rst_ni    ( x_rst_ni    ) ,
   .dt_o      ( rx_ack_s   ) );

///////////////////////////////////////////////////////////////////////////////
// C CLOCK SYNC 
wire cmd_req  [CH];
sync_reg # (
   .DW ( CH )
) rx_req_sync (
   .dt_i      ( rx_req_s     ) ,
   .clk_i     ( c_clk_i     ) ,
   .rst_ni    ( c_rst_ni    ) ,
   .dt_o      ( cmd_req    ) );
   
// RX Command Priority Encoder
reg cmd_valid;
reg [3:0] rx_vld_ind ;

integer i ;
always_comb begin
  cmd_valid  = 1'b0;
  rx_vld_ind = 0;
  for (i = 0 ; i < CH; i=i+1)
    if (!cmd_valid & cmd_req[i]) begin
      cmd_valid   = 1'b1;
      rx_vld_ind  = i;
   end
end

// Check SYNTH

///////////////////////////////////////////////////////////////////////////////
// RX Decoding
wire [31:0] rx_dt;       // Data Received
wire [ 3:0] rx_cmd;     // Header Received
reg rx_up_cmd, rx_wreg, wreg_sel, rx_wflg, rx_sync;

assign rx_cmd   = rx_cmd_s[rx_vld_ind];
assign rx_dt    = rx_data_s[rx_vld_ind];

assign rx_no_dt  = ~|rx_cmd[2:1];
assign rx_wflg   =  !rx_cmd[3] & rx_no_dt ; // 000
assign rx_wreg   =  !rx_cmd[3] & !rx_no_dt; // 001-010-011
assign rx_sync   =   rx_cmd[3] & rx_no_dt ; // 100
assign rx_up_cmd =   rx_cmd[3] & !rx_no_dt; // 101-010-011

assign flg_wr   = cmd_valid & rx_wflg  ; // 000
assign reg_wr   = cmd_valid & rx_wreg  ; // 001-010-011
assign sync     = cmd_valid & rx_sync  ; // 100
assign up_cmd   = cmd_valid & rx_up_cmd; // 101-010-011

assign mem_wr   = up_cmd & rx_cmd[0]; 
assign mem_addr = rx_vld_ind;
assign cmd_dt   = rx_dt  ;



///////////////////////////////////////////////////////////////////////////////
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

assign flg_wr_o   = flg_wr   ;
assign reg_wr_o   = reg_wr   ;
assign sync_o     = sync     ;
assign mem_wr_o   = mem_wr   ;
assign sel_o      = rx_cmd[0];
assign mem_addr_o = mem_addr ;
assign cmd_dt_o   = cmd_dt   ;

endmodule




