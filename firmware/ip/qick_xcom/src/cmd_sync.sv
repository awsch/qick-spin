module cmd_sync (
// CLK & RST
   input  wire             c_clk_i        ,
   input  wire             c_rst_ni       ,
   input  wire             t_clk_i        ,
   input  wire             t_rst_ni       ,
// XCOM CFG
   input  wire             pulse_i        ,
   input  wire             sync_req_i      ,
   output wire             sync_ack_o      ,
// TPROC CONTROL
   output reg              qproc_start_o  
);

reg [2:0] t_start_cnt;
reg t_start_ack, t_start_r;

// PULSE SYNC 
///////////////////////////////////////////////////////////////////////////////
reg t_pulse_r2 ;
sync_reg # (
   .DW ( 1 )
) t_sync_pulse (
   .dt_i      ( pulse_i     ) ,
   .clk_i     ( t_clk_i     ) ,
   .rst_ni    ( t_rst_ni    ) ,
   .dt_o      ( t_pulse_r    ) );

always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   if (!t_rst_ni)   t_pulse_r2   <= 1'b0; 
   else             t_pulse_r2   <= t_pulse_r;
end
assign t_sync_t01 = !t_pulse_r2 & t_pulse_r ;


///////////////////////////////////////////////////////////////////////////////
typedef enum { QRST_IDLE, QRST_REQ, QRST_ACK } TYPE_QCTRL_ST ;
   (* fsm_encoding = "sequential" *) TYPE_QCTRL_ST qctrl_st;
   TYPE_QCTRL_ST qctrl_st_nxt;

always_ff @ (posedge c_clk_i) begin
   if      ( !c_rst_ni   )  qctrl_st  <= QRST_IDLE;
   else                     qctrl_st  <= qctrl_st_nxt;
end
reg sync_ack, start_req;
always_comb begin
   qctrl_st_nxt   = qctrl_st; // Default Current
   sync_ack  = 1'b0;
   start_req = 1'b0;
   case (qctrl_st)
      QRST_IDLE  : 
         if ( sync_req_i ) qctrl_st_nxt = QRST_REQ;     
      QRST_REQ : begin
         start_req  = 1'b1;
         if ( start_ack  ) qctrl_st_nxt = QRST_ACK;     
      end
      QRST_ACK   : begin
      sync_ack = 1'b1;
         if ( !start_ack  )  qctrl_st_nxt = QRST_IDLE;     
      end
      default: qctrl_st_nxt = qctrl_st;
   endcase
end

///////////////////////////////////////////////////////////////////////////////
// REQ - ACK SYNC 
sync_reg # (.DW(1)) t_sync_start_req (
   .dt_i      ( start_req   ) ,
   .clk_i     ( t_clk_i     ) ,
   .rst_ni    ( t_rst_ni    ) ,
   .dt_o      ( t_start_req ) );
 
sync_reg # (.DW(1)) c_sync_start_ack (
   .dt_i      ( t_start_r ) ,
   .clk_i     ( c_clk_i     ) ,
   .rst_ni    ( c_rst_ni    ) ,
   .dt_o      ( start_ack   ) );



always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   if (!t_rst_ni)   begin
      t_start_cnt   <= 0; 
      t_start_ack   <= 1'b0; 
      t_start_r     <= 1'b0; 
   end else begin
      if      ( t_start_req ) t_start_ack  <= 1'b1;
      else if ( qproc_hit   ) t_start_ack  <= 1'b0; 

      if      ( qproc_hit         )  t_start_r   <= 1'b1;
      else if ( t_start_cnt==3'd7 )  t_start_r   <= 1'b0;

      if ( t_start_r ) t_start_cnt <= t_start_cnt+1'b1;
      else             t_start_cnt <= 0;
   end
end

assign qproc_hit = t_start_ack & t_sync_t01;

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////

assign qproc_start_o = t_start_r ;
assign sync_ack_o    = sync_ack ;
endmodule
