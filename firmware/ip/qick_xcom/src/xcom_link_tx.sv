///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_9
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////

module xcom_link_tx (
// CLK & RST
   input  wire          x_clk_i      ,
   input  wire          x_rst_ni     ,
// Config 
   input  wire [ 3:0]   tick_cfg_i   ,
// Transmittion 
   input  wire          tx_vld_i     ,
   output reg           tx_rdy_o     ,
   input  wire [ 7:0]   tx_header_i  ,
   input  wire [31:0]   tx_data_i    ,
// Xwire COM
   output reg           tx_dt_o      ,
   output reg           tx_ck_o      
   );

wire tx_last_dt;
reg  [ 5:0] tx_bit_cnt, tx_pack_size_r; //Number of bits transmited  (Total Defined in tx_pack_size)


// TICK GENERATOR
///////////////////////////////////////////////////////////////////////////////
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
            tick_cnt <= 4'd1;
         end else begin 
            tick_dt  <= 1'b0;
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
 
// TX Encode Header
///////////////////////////////////////////////////////////////////////////////
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

assign tx_last_dt  = (tx_bit_cnt == tx_pack_size_r) ;

///////////////////////////////////////////////////////////////////////////////
///// TX STATE
typedef enum { TX_IDLE, TX_DT, TX_CLK, TX_END } TYPE_TX_ST ;
(* fsm_encoding = "one_hot" *) TYPE_TX_ST tx_st;
TYPE_TX_ST tx_st_nxt;

reg   tx_idle_s;

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
            tx_st_nxt = TX_DT;
         end     
      end
      TX_CLK :  begin
         tick_en     = 1'b1;
         if ( tick_clk ) tx_st_nxt = TX_DT;
      end
      TX_DT :  begin
         tick_en     = 1'b1;
         if ( tick_dt ) begin
            if ( tx_last_dt ) tx_st_nxt = TX_END;
            else              tx_st_nxt = TX_CLK;
         end
      end
      TX_END    :  begin
         tx_st_nxt = TX_IDLE;
      end
      default: tx_st_nxt = tx_st;
   endcase
end

// TX Registers
///////////////////////////////////////////////////////////////////////////////
reg  [39:0] tx_dt_r ; //Out Shift Register For Par 2 Ser. (Data encoded on tx_dt)
reg tx_ck_r; // Data and Clock

always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni) begin
      tx_ck_r        <= 0;
      tx_dt_r        <= '{default:'0} ; 
      tx_bit_cnt     <= 6'd0;
      tx_pack_size_r <= 6'd0;
   end else begin 
      if (tx_vld_i & tx_idle_s) begin
         tx_dt_r        <= tx_buff;
         tx_bit_cnt     <= 6'd1;
         tx_pack_size_r <= tx_pack_size;
      end else if ( tx_idle_s ) begin
         tx_ck_r <= 1'b0;
      end 
      if ( tick_clk )
         tx_ck_r <= ~tx_ck_r;
      else if (tick_dt) begin 
         tx_dt_r     <= tx_dt_r << 1;
         tx_bit_cnt  <= tx_bit_cnt + 1'b1 ;
      end
   end
end

///////////////////////////////////////////////////////////////////////////////
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

assign tx_rdy_o     = tx_idle_s;
assign tx_dt_o      = tx_dt_r[39] ;
assign tx_ck_o      = tx_ck_r;
   
endmodule
