///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_9
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////

module tx_cmd # (
   parameter CH = 2
)(
// CLK & RST
   input  wire          x_clk_i     ,
   input  wire          x_rst_ni    ,
   input  wire          pulse_sync_i,
// Config 
   input  wire [ 3:0]   tick_cfg_i  ,
// Transmittion 
   input  wire          tx_req_i   ,
   output reg           tx_rdy_o    ,
   input  wire [ 7:0]   tx_hd_i    ,
   input  wire [31:0]   tx_dt_i    ,
// XCOM CNX
   output reg           tx_dt_o     ,
   output reg           tx_ck_o      
   );

// PULSE SYNC 
///////////////////////////////////////////////////////////////////////////////
reg x_pulse_r2 ;
sync_reg #(.DW(1)) x_sync_pulse (
   .dt_i      ( pulse_sync_i) ,
   .clk_i     ( x_clk_i     ) ,
   .rst_ni    ( x_rst_ni    ) ,
   .dt_o      ( x_pulse_r   ) );

always_ff @ (posedge x_clk_i, negedge x_rst_ni) begin
   if (!x_rst_ni)   x_pulse_r2   <= 1'b0; 
   else             x_pulse_r2   <= x_pulse_r;
end
assign x_sync_t01 = !x_pulse_r2 & x_pulse_r ;

assign xcmd_sync     = ( tx_hd_i[7:4] == 4'b1000 ); // Sync Command

// TX Control state
///////////////////////////////////////////////////////////////////////////////
typedef enum { TX_IDLE, TX_WSYNC, TX_WRDY } TYPE_TX_ST ;
(* fsm_encoding = "sequential" *) TYPE_TX_ST tx_st;
TYPE_TX_ST tx_st_nxt;

always_ff @ (posedge x_clk_i) begin
   if      ( !x_rst_ni   )  tx_st  <= TX_IDLE;
   else                     tx_st  <= tx_st_nxt;
end

reg        tx_vld;

always_comb begin
   tx_st_nxt = tx_st; // Default Current
   tx_vld         = 1'b0;
   case (tx_st)
      TX_IDLE   :  begin
         if ( tx_req_i )
            if ( xcmd_sync )
               tx_st_nxt = TX_WSYNC;     
            else begin
               tx_st_nxt = TX_WRDY;     
               tx_vld    = 1'b1;
            end
      end
      TX_WSYNC   :  begin
         if ( x_sync_t01 ) begin 
            tx_vld    = 1'b1;
            tx_st_nxt = TX_WRDY;     
         end
      end
      TX_WRDY   :  begin
         if ( !tx_req_i & tx_rdy ) tx_st_nxt = TX_IDLE;     
      end
      default: tx_st_nxt = tx_st;
   endcase
end


xcom_link_tx TX (
   .x_clk_i       ( x_clk_i    ),
   .x_rst_ni      ( x_rst_ni   ),
   .tick_cfg_i    ( tick_cfg_i ),
   .tx_vld_i      ( tx_vld     ),
   .tx_rdy_o      ( tx_rdy     ),
   .tx_header_i   ( tx_hd_i   ),
   .tx_data_i     ( tx_dt_i   ),
   .tx_dt_o       ( tx_dt_s    ),
   .tx_ck_o       ( tx_ck_s    )
   );

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

assign tx_rdy_o = tx_rdy;  
assign tx_dt_o = tx_dt_s;
assign tx_ck_o = tx_ck_s;

endmodule

