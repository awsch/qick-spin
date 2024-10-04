module cmd_sync (
// CLK & RST
   input  wire             t_clk_i         ,
   input  wire             t_rst_ni        ,
   input  wire             pulse_sync_i    ,
   input  wire             qrst_now_req_i  ,
   input  wire             qrst_sync_req_i ,
   output wire             qrst_ack_o      ,
// TPROC CONTROL
   output reg              qproc_start_o  
);

reg [2:0] qrst_cnt;

// PULSE SYNC 
///////////////////////////////////////////////////////////////////////////////
reg t_pulse_r2 ;
sync_reg # (
   .DW ( 1 )
) t_sync_pulse (
   .dt_i      ( pulse_sync_i     ) ,
   .clk_i     ( t_clk_i     ) ,
   .rst_ni    ( t_rst_ni    ) ,
   .dt_o      ( t_pulse_r    ) );

always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   if (!t_rst_ni)   t_pulse_r2   <= 1'b0; 
   else             t_pulse_r2   <= t_pulse_r;
end
assign t_sync_t01 = !t_pulse_r2 & t_pulse_r ;


///////////////////////////////////////////////////////////////////////////////
typedef enum { QRST_IDLE, QRST_WSYNC, QRST_EXEC, QRST_ACK } TYPE_QCTRL_ST ;
   (* fsm_encoding = "sequential" *) TYPE_QCTRL_ST qctrl_st;
   TYPE_QCTRL_ST qctrl_st_nxt;

always_ff @ (posedge t_clk_i) begin
   if      ( !t_rst_ni   )  qctrl_st  <= QRST_IDLE;
   else                     qctrl_st  <= qctrl_st_nxt;
end

reg sync_ack, qick_rst ;
assign qrst_pulse_end = (qrst_cnt == 3'd7);
always_comb begin
   qctrl_st_nxt   = qctrl_st; // Default Current
   sync_ack  = 1'b0;
   qick_rst  = 1'b0;
   qrst_cnt  = 3'd0;
   case (qctrl_st)
      QRST_IDLE  : 
         if      ( qrst_sync_req_i ) qctrl_st_nxt = QRST_WSYNC;
         else if ( qrst_now_req_i  ) qctrl_st_nxt = QRST_EXEC;     
      QRST_WSYNC : begin
         sync_ack  = 1'b1;
         if ( t_sync_t01  ) qctrl_st_nxt = QRST_EXEC;     
      end
      QRST_EXEC : begin
         sync_ack  = 1'b1;
         qick_rst  = 1'b1;
         qrst_cnt  = qrst_cnt + 1'b1;
         if ( qrst_pulse_end ) qctrl_st_nxt = QRST_ACK;     
      end
      QRST_ACK   : begin
         sync_ack = 1'b1;
         if ( !qrst_now_req_i & !qrst_sync_req_i  )  qctrl_st_nxt = QRST_IDLE;     
      end
      default: qctrl_st_nxt = qctrl_st;
   endcase
end

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////
assign qproc_start_o = qick_rst ;
assign qrst_ack_o    = sync_ack ;

endmodule
