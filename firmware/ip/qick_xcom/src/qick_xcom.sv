///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_9
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////

module qick_xcom (
// Core and Com CLK & RST
   input  wire             c_clk_i        ,
   input  wire             c_rst_ni       ,
   input  wire             x_clk_i        ,
   input  wire             x_rst_ni       ,
// XCOM CFG
   input  wire             pulse_i        ,
   input  wire  [3:0]      xcom_cfg_i     ,
// QCOM INTERFACE
   input  wire             cmd_req_i      ,
   output wire             cmd_ack_o      ,
   input  wire  [3:0]      cmd_op_i       ,
   input  wire  [31:0]     cmd_dt_i       ,
   output reg              xcom_rdy_o     ,
   output reg   [31:0]     xcom_dt1_o     ,
   output reg   [31:0]     xcom_dt2_o     ,
   output reg              xcom_vld_o     ,
   output reg              xcom_flag_o    ,
// TPROC CONTROL
   output reg              qproc_start_o  ,
// Xwire COM
   input  wire    rx_dt_i      ,
   input  wire    rx_ck_i      ,
   output reg     tx_dt_o      ,
   output reg     tx_ck_o      ,
// DEBUG
   output wire [31:0]      xcom_tx_dt_do  ,
   output wire [31:0]      xcom_rx_dt_do  ,
   output wire [31:0]      xcom_status_do ,
   output wire [15:0]      xcom_debug_do  ,
   output wire [31:0]      xcom_do        );

// Signal Declaration 
///////////////////////////////////////////////////////////////////////////////

assign xcmd_sync     = ( cmd_op_i[3:0] == 3'b100 ); // Sync Command



///////////////////////////////////////////////////////////////////////////////
// C CLOCK SYNC 
reg c_sync_r2 ;
sync_reg # (
   .DW ( 1 )
) c_sync_pulse (
   .dt_i      ( pulse_i     ) ,
   .clk_i     ( c_clk_i     ) ,
   .rst_ni    ( c_rst_ni    ) ,
   .dt_o      ( c_sync_r    ) );
always_ff @ (posedge c_clk_i, negedge c_rst_ni) begin
   if (!c_rst_ni)   c_sync_r2   <= 1'b0; 
   else              c_sync_r2   <= c_sync_r;
end
assign c_sync_t01 = !c_sync_r2 & c_sync_r ;


///////////////////////////////////////////////////////////////////////////////
// #######  #     # 
//    #      #   #  
//    #       # #   
//    #        #    
//    #       # #   
//    #      #   #  
//    #     #     # 
///////////////////////////////////////////////////////////////////////////////


// TX Control state
///////////////////////////////////////////////////////////////////////////////
typedef enum { TX_IDLE, TX_WSYNC, TX_WRDY } TYPE_TX_ST ;
(* fsm_encoding = "sequential" *) TYPE_TX_ST xcom_tx_st;
TYPE_TX_ST xcom_tx_st_nxt;

always_ff @ (posedge x_clk_i) begin
   if      ( !x_rst_ni   )  xcom_tx_st  <= TX_IDLE;
   else                     xcom_tx_st  <= xcom_tx_st_nxt;
end

reg        tx_vld, xready;

always_comb begin
   xcom_tx_st_nxt = xcom_tx_st; // Default Current
   tx_vld         = 1'b0;
   xready         = 1'b0;
   case (xcom_tx_st)
      TX_IDLE   :  begin
         xready   = 1'b1;
         if ( cmd_req_i )
            if ( xcmd_sync )
               xcom_tx_st_nxt = TX_WSYNC;     
            else begin
               xcom_tx_st_nxt = TX_WRDY;     
               tx_vld         = 1'b1;
            end
      end
      TX_WSYNC   :  begin
         if ( c_sync_t01 ) begin 
            tx_vld         = 1'b1;
            xcom_tx_st_nxt = TX_WRDY;     
         end
      end
      TX_WRDY   :  begin
         if ( tx_ready ) xcom_tx_st_nxt = TX_IDLE;     
      end
   endcase
end


///////////////////////////////////////////////////////////////////////////////
// ######   #     # 
// #     #   #   #  
// #     #    # #   
// ######      #    
// #   #      # #   
// #    #    #   #  
// #     #  #     # 
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
// RX
typedef enum { RX_IDLE, RX_CMD } TYPE_RX_ST ;
   (* fsm_encoding = "sequential" *) TYPE_RX_ST qcom_rx_st;
   TYPE_RX_ST qcom_rx_st_nxt;

always_ff @ (posedge c_clk_i) begin
   if      ( !c_rst_ni   )  qcom_rx_st  <= RX_IDLE;
   else                     qcom_rx_st  <= qcom_rx_st_nxt;
end

always_comb begin
   qcom_rx_st_nxt   = qcom_rx_st; // Default Current
   case (qcom_rx_st)
      RX_IDLE  : 
         if ( rx_vld ) qcom_rx_st_nxt = RX_CMD;     
      RX_CMD   : begin
         qcom_rx_st_nxt = RX_IDLE;     
      end
   endcase
end


///////////////////////////////////////////////////////////////////////////////
// RX Decoding
wire [31:0] rx_dt;       // Data Received
wire [ 3:0] rx_cmd;     // Header Received
reg rx_wmem, rx_wreg, wreg_sel, rx_wflg, rx_sync;

assign rx_no_dt = ~|rx_cmd[2:1];
assign rx_wflg  =  !rx_cmd[3] & rx_no_dt ;
assign rx_sync  =   rx_cmd[3] & rx_no_dt ;
assign rx_wreg  =  !rx_cmd[3] & !rx_no_dt;
assign rx_wmem  =   rx_cmd[3] & !rx_no_dt;
assign wreg_sel =   rx_cmd[3];


assign rx_wreg_en = rx_vld & rx_wreg;
assign rx_wflg_en = rx_vld & rx_wflg;

///////////////////////////////////////////////////////////////////////////////
// Register Write
reg        qflag_dt, rx_wreg_r ;
reg [31:0] qreg1_dt, qreg2_dt;
always_ff @ (posedge c_clk_i, negedge c_rst_ni) begin
   if (!c_rst_ni) begin
      qflag_dt    <= 1'b0; 
      qreg1_dt    <= '{default:'0} ; 
      qreg2_dt    <= '{default:'0} ; 
      rx_wreg_r   <= 1'b0; 
   end else begin 
      rx_wreg_r <= rx_wreg_en ;
      if ( rx_wreg_en )
         case ( wreg_sel )
            1'b0 : qreg1_dt <= rx_dt;      // Reg_dt1
            1'b1 : qreg2_dt <= rx_dt;      // Reg_dt2
         endcase
      else if ( rx_wflg_en )
         qflag_dt <= rx_cmd[0]; // FLAG


   end

end



///////////////////////////////////////////////////////////////////////////////
// INSTANCES 
///////////////////////////////////////////////////////////////////////////////

   
///////////////////////////////////////////////////////////////////////////////
xcom_link XCOM (
	.c_clk_i      ( c_clk_i    ),
	.c_rst_ni     ( c_rst_ni    ),
	.x_clk_i      ( x_clk_i    ),
	.x_rst_ni     ( x_rst_ni   ),
	.tick_cfg_i   ( xcom_cfg_i  ),
	.tx_vld_i     ( tx_vld    ),
	.tx_ready_o   ( tx_ready  ),
	.tx_header_i  ( cmd_op_i ),
	.tx_data_i    ( cmd_dt_i   ),
	.rx_vld_o     ( rx_vld    ),
	.rx_cmd_o     ( rx_cmd ),
	.rx_data_o    ( rx_dt   ),
	.rx_dt_i      ( rx_dt_i     ),
	.rx_ck_i      ( rx_ck_i     ),
	.tx_dt_o      ( tx_dt_o     ),
	.tx_ck_o      ( tx_ck_o     ),
	.xcom_link_do (             ));


///////////////////////////////////////////////////////////////////////////////
// DEBUG
reg [3:0] sync_cnt;
always_ff @ (posedge c_clk_i, negedge c_rst_ni) begin
   if (!c_rst_ni)   begin
      sync_cnt   <= 0; 
   end else begin
      if ( c_sync_t01 ) sync_cnt <= sync_cnt + 1'b1;
   end
end

//assign qcom_tx_dt_do   = qcom_dt;
//assign qcom_rx_dt_do   = rx_data;
//assign qcom_status_do  = {tx_ready, qctrl_st[1:0],  qcom_tx_st[2:0], qcom_rx_st[1:0] };
//assign qcom_debug_do   = {pulse_i, tx_ready, reg_wr_size[1:0], reg_sel, qcom_header[2:0], rx_header[2:0], sync_cnt[3:0] };
//assign qcom_do         = 0;

///////////////////////////////////////////////////////////////////////////////
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

// OUT SIGNALS
assign xcom_rdy_o    = xready;
assign xcom_dt1_o    = qreg1_dt;
assign xcom_dt2_o    = qreg2_dt;
assign xcom_vld_o    = rx_wreg_r;
assign xcom_flag_o   = qflag_dt;
assign xcom_do       = 0;
assign xproc_start_o = 0;
assign cmd_ack_o     = ~xready;





endmodule


