///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_5
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////

module xcom_link (
// Core and AXI CLK & RST
   input  wire          c_clk_i       ,
   input  wire          c_rst_ni      ,
   input  wire          x_clk_i       ,
   input  wire          x_rst_ni      ,
// Config 
   input  wire [ 3:0]   tick_cfg_i    , // Pulse Duration
// Transmittion 
   input  wire          tx_vld_i      ,
   output reg           tx_ready_o    ,
   input  wire [ 7:0]   tx_header_i   ,
   input  wire [31:0]   tx_data_i     ,
// Command Processing  
   output reg           rx_vld_o      ,
   output reg  [ 3:0]   rx_cmd_o   ,
   output reg  [31:0]   rx_data_o     ,
// Xwire COM
   input  wire    rx_dt_i      ,
   input  wire    rx_ck_i      ,
   output reg     tx_dt_o      ,
   output reg     tx_ck_o      ,
///// DEBUG   
   output wire [31:0]   xcom_link_do        
   );

///////////////////////////////////////////////////////////////////////////////
// ######   #     # 
// #     #   #   #  
// #     #    # #   
// ######      #    
// #   #      # #   
// #    #    #   #  
// #     #  #     # 
///////////////////////////////////////////////////////////////////////////////
reg rx_idle_s, rx_header_s, rx_end_s, rx_fault_s ;


///////////////////////////////////////////////////////////////////////////////
// Sync rx_clk and Data with Xclk
reg rx_ck_r, rx_ck_r2, rx_dt_r, rx_dt_r2;
(* ASYNC_REG = "TRUE" *) reg rx_ck_cdc, rx_dt_cdc ;
always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      rx_ck_cdc    <= 1'b0;
      rx_ck_r      <= 1'b0;
      rx_ck_r2     <= 1'b0;
      rx_dt_cdc    <= 1'b0;
      rx_dt_r      <= 1'b0;
      rx_dt_r2     <= 1'b0;
   end else begin 
      rx_ck_cdc    <= rx_ck_i;
      rx_ck_r      <= rx_ck_cdc;
      rx_ck_r2     <= rx_ck_r;
      rx_dt_cdc    <= rx_dt_i;
      rx_dt_r      <= rx_dt_cdc;
      rx_dt_r2     <= rx_dt_r;
   end
end
assign rx_new_dt   = rx_ck_r2 ^ rx_ck_r;

///////////////////////////////////////////////////////////////////////////////
// RX Serial to Paralel
reg [ 7:0] rx_hd_sr ;
reg [31:0] rx_dt_sr ;
always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      rx_dt_sr  <= '{default:'0} ; 
      rx_hd_sr  <= '{default:'0} ; 
   end else begin 
      if (rx_new_dt) begin
         if ( rx_header_s ) begin
            rx_hd_sr <= {rx_hd_sr[7:0]  , rx_dt_r2}  ;
            rx_dt_sr <= '{default:'0} ;
         end else               
            rx_dt_sr <= {rx_dt_sr[31:0] , rx_dt_r2 } ;
      end
   end
end

///////////////////////////////////////////////////////////////////////////////
// RX Length Decoding
reg [5:0] rx_pack_size;
always_comb begin
   case ( rx_hd_sr [6:5] )
      2'b00  : rx_pack_size = 6'd8  ; 
      2'b01  : rx_pack_size = 6'd16 ; 
      2'b10  : rx_pack_size = 6'd24 ; 
      2'b11  : rx_pack_size = 6'd40 ; 
      default: rx_pack_size = 6'd8  ;
   endcase
end

///////////////////////////////////////////////////////////////////////////////
// RX Measurment
reg [4:0] rx_time_out_cnt; // Timeout
reg [5:0] rx_bit_cnt     ; // Received Bit up to 40

always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      rx_bit_cnt      <= 8'd1;
      rx_time_out_cnt <= 5'd0;
   end else begin 
      if (rx_new_dt) begin
         rx_bit_cnt       <= rx_bit_cnt + 1'b1 ;
         rx_time_out_cnt  <= 4'd0;
      end else if (rx_idle_s) begin
         rx_bit_cnt       <= 8'd1;
         rx_time_out_cnt  <= 4'd0;
      end else
         rx_time_out_cnt  <= rx_time_out_cnt + 1'b1 ;
   end
end

wire rx_time_out, rx_last_dt ;

assign rx_no_dt      = rx_hd_sr [5:4] == 2'b00 ;
assign rx_last_hd    = rx_new_dt & (rx_bit_cnt == 5'd8) ; // Last Header bit
assign rx_last_dt    = rx_new_dt & (rx_bit_cnt == rx_pack_size ) ; // Last Data Received
assign rx_time_out   = &rx_time_out_cnt ; // New Data was not received in time

///////////////////////////////////////////////////////////////////////////////
///// RX STATE
typedef enum { RX_IDLE, RX_HEADER, RX_DATA, RX_END, RX_FAULT, RX_CHECK, RX_RTZ } TYPE_RX_ST ;
(* fsm_encoding = "one_hot" *) TYPE_RX_ST rx_st;
TYPE_RX_ST rx_st_nxt;


always_ff @ (posedge x_clk_i) begin
   if      ( !x_rst_ni   )  rx_st  <= RX_IDLE;
   else                     rx_st  <= rx_st_nxt;
end
always_comb begin
   rx_st_nxt   = rx_st; // Default Current
   rx_idle_s   = 1'b0;
   rx_header_s = 1'b0;
   rx_end_s    = 1'b0;
   rx_fault_s  = 1'b0;
   case (rx_st)
      RX_IDLE   :  begin
         rx_idle_s = 1'b1;
         if ( rx_new_dt ) begin
            rx_header_s = 1'b1;
            rx_st_nxt = RX_HEADER; // First Transition 0 to 1
         end
      end
      RX_HEADER :  begin
         rx_header_s = 1'b1;
         if ( rx_last_hd )
            if      ( rx_no_dt  ) rx_st_nxt = RX_END  ; // Package has No Data     
            else if ( rx_new_dt ) rx_st_nxt = RX_DATA ; // Package has Data   
         else if ( rx_time_out  ) rx_st_nxt = RX_FAULT; // TimeOut    
      end
      RX_DATA :  begin
         if      ( rx_last_dt  ) rx_st_nxt = RX_END;     // Last Data Received  
         else if ( rx_time_out ) rx_st_nxt = RX_FAULT;   // TimeOut  
      end
      RX_END    :  begin
         rx_end_s  = 1'b1;
         rx_st_nxt = RX_IDLE;     
      end
      RX_FAULT  :  begin
         rx_fault_s  = 1'b1;
         rx_st_nxt   = RX_IDLE;     
      end
   endcase
end



///////////////////////////////////////////////////////////////////////////////
// #######  #     # 
//    #      #   #  
//    #       # #   
//    #        #    
//    #       # #   
//    #      #   #  
//    #     #     # 
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
// TICK GENERATOR
reg  [ 3:0] tick_cnt ; // Number of tx_clk per Data 
reg   tick_en ; 
reg   tick_clk ; 
reg   tick_dt ; 

always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      tick_cnt    <= 0;
      tick_clk    <= 1'b0;
      tick_dt     <= 1'b0;
   end else begin 
      if (tick_en) begin
         if (tick_cnt == tick_cfg_i) begin
            tick_dt  <= 1'b1;
            tick_cnt  <= 4'd1;
         end else begin 
            tick_dt    <= 1'b0;
            tick_cnt <= tick_cnt + 1'b1 ;
         end
         if (tick_cnt == tick_cfg_i>>1) tick_clk <= 1'b1;
         else                           tick_clk <= 1'b0;
      end else begin 
         tick_cnt    <= tick_cfg_i>>1;
         tick_dt     <= 1'b0;
         tick_clk    <= 1'b0;
      end
   end
end
reg   tx_idle_s, tx_header_s;
 
///////////////////////////////////////////////////////////////////////////////
// TX Encode Header
reg [ 5:0] tx_pack_size ;
reg [39:0] tx_buff;
always_comb begin
   case (tx_header_i[6:5])
      2'b00  : begin // NO DATA
         tx_pack_size = 7;
         tx_buff      = {tx_header_i, 32'd0};
         end
      2'b01  : begin // 8-bit DATA
         tx_pack_size = 15;
         tx_buff      = {tx_header_i, tx_data_i[7:0], 24'd0};
         end
      2'b10  : begin // 16-bit DATA
         tx_pack_size = 23;
         tx_buff      = {tx_header_i, tx_data_i[15:0], 16'd0};
         end
      2'b11  : begin //32-bit DATA
         tx_pack_size = 39;
         tx_buff      = {tx_header_i, tx_data_i};
         end
   endcase
end

///////////////////////////////////////////////////////////////////////////////
// TX Registers
reg  [39:0] tx_out_r ; //Out Shift Register For Par 2 Ser. (Data encoded on tx_dt)
reg  [ 5:0] tx_bit_cnt, tx_pack_size_r; //Number of bits transmited  (Total Defined in tx_pack_size)

reg tx_ck; // Data and Clock

always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      tx_out_r       <= '{default:'0} ; 
      tx_bit_cnt     <= 6'd0;
      tx_pack_size_r <= 6'd0;
      tx_ck          <= 0;
   end else begin 
      if (tx_vld_i & tx_idle_s) begin
         tx_out_r         <= tx_buff;
         tx_bit_cnt       <= 6'd1;
         tx_pack_size_r   <= tx_pack_size;
      end else if ( tx_idle_s ) begin
         tx_ck <= 1'b0;
      end 
      if ( tick_clk )
         tx_ck <= ~tx_ck;
      else if (tick_dt) begin 
         tx_bit_cnt  <= tx_bit_cnt + 1'b1 ;
         tx_out_r    <= tx_out_r << 1;
      end
   end
end

assign tx_last_dt  = (tx_bit_cnt == tx_pack_size_r) ;

///////////////////////////////////////////////////////////////////////////////
///// TX STATE
typedef enum { TX_IDLE, TX_DT, TX_CLK, TX_END, TX_RTZ, TX_WAIT } TYPE_TX_ST ;
(* fsm_encoding = "one_hot" *) TYPE_TX_ST tx_st;
TYPE_TX_ST tx_st_nxt;

always_ff @ (posedge x_clk_i) begin
   if   ( !x_rst_ni )  tx_st  <= TX_IDLE;
   else                tx_st  <= tx_st_nxt;
end
always_comb begin
   tx_st_nxt   = tx_st; // Default Current
   tick_en     = 1'b0;
   tx_idle_s   = 1'b0;
   case (tx_st)
      TX_IDLE   :  begin
         tx_idle_s = 1'b1;
         if ( tx_vld_i ) begin
            tick_en     = 1'b1;
            tx_st_nxt = TX_CLK;
         end     
      end
      TX_DT :  begin
         tick_en     = 1'b1;
         if ( tick_clk ) tx_st_nxt = TX_CLK;
      end
      TX_CLK :  begin
         tick_en     = 1'b1;
         tx_header_s = 1'b1;
         if ( tick_dt ) begin
            if ( tx_last_dt ) tx_st_nxt = TX_END;
            else              tx_st_nxt = TX_DT;
         end
      end
      TX_END    :  begin
         tx_st_nxt = TX_IDLE;
      end
   endcase
end

///////////////////////////////////////////////////////////////////////////////
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

assign tx_ready_o   = tx_idle_s;
assign rx_vld_o     = rx_end_s;
assign rx_cmd_o     = rx_hd_sr[7:4];
assign rx_data_o    = rx_dt_sr;
assign tx_dt_o      = tx_out_r[39] ;
assign tx_ck_o      = tx_ck;
assign xcom_link_do = 0;
   
endmodule
