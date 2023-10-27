`include "proc_defines.svh"

module t_proc_B # (
   parameter LFSR           =  1 ,
   parameter DIVIDER        =  1 ,
   parameter ARITH          =  1 ,
   parameter TIME_CMP       =  1 ,
   parameter TIME_READ      =  1 ,
   parameter PMEM_AW        =  8 ,
   parameter DMEM_AW        =  8 ,
   parameter WMEM_AW        =  8 ,
   parameter REG_AW         =  4 ,
   parameter IN_PORT_QTY    =  2 ,
   parameter OUT_DPORT_QTY  =  4 ,
   parameter OUT_WPORT_QTY  =  4 
)(
   input   wire                     t_clk_i        ,
   input   wire                     t_rst_ni       ,
   input   wire                     c_clk_i        ,
   input   wire                     c_rst_ni       ,
   input   wire                     start_i        ,
   input   wire [15:0]              TPROC_CTRL     ,
   input   wire [23:0]              TPROC_CFG      ,
   input   wire [31:0]              ext_dt_i [2]   ,
   output  wire [31:0]              ext_dt_o [2]   ,
   output  wire [31:0]              rand_o         ,
   output  wire [31:0]              time_usr_o     ,
// PROGRAM MEMORY
   output  wire [PMEM_AW-1:0]       pmem_addr_o    ,
   output  wire                     pmem_en_o      ,
   input   wire [71:0]              pmem_dt_i      ,
// DATA MEMORY
   output  wire                     dmem_we_o      ,
   output  wire [DMEM_AW-1:0]       dmem_addr_o    ,
   output  wire [31:0]              dmem_w_dt_o    ,
   input   wire [31:0]              dmem_r_dt_i    ,
// WAVE MEMORY
   output  wire                     wmem_we_o      ,
   output  wire [WMEM_AW-1:0]       wmem_addr_o    ,
   output  wire [167:0]             wmem_w_dt_o    ,
   input   wire [167:0]             wmem_r_dt_i    ,
// DATA INTERFACE
   input   wire                     port_dt_new_i  ,
   input   wire [63:0]              port_dt_i      [ IN_PORT_QTY  ],
   output  wire [31:0]              port_dt_o      [ OUT_DPORT_QTY],
   // AXI Stream Master I/F.                          
   output  wire [167:0]             m_axis_tdata   [OUT_WPORT_QTY] ,
   output  wire                     m_axis_tvalid  [OUT_WPORT_QTY] ,
   input   wire                     m_axis_tready  [OUT_WPORT_QTY] ,
// DEBUG INTERFACE                       
   output  wire [23:0]              TPROC_STATUS   ,
   output  wire [15:0]              DEBUG_O        ,
   output  wire [31:0]              t_time_abs_do  ,
   output  wire [31:0]              t_fifo_do      ,
   output  wire [31:0]              t_debug_do     ,
   output  wire [31:0]              c_time_ref_do  ,
   output  wire [31:0]              c_port_do      ,
   output  wire [31:0]              c_core_do      );


// SIGNALS
///////////////////////////////////////////////////////////////////////////////
// PROGRAM MEMORY
wire [PMEM_AW-1:0]   pmem_addr_r    ;
wire [71:0]          pmem_data_r    ;
// DATA MEMORY
wire                 core_dmem_we   ;
wire [DMEM_AW-1:0]   core_dmem_r_addr, core_dmem_w_addr ;
wire [31:0]          core_dmem_r_dt  , core_dmem_w_dt   ;
// WAVE MEMORY
wire                 core_wmem_we   ;
wire [WMEM_AW-1:0]   core_wmem_r_addr, core_wmem_w_addr ;
wire [167:0]         core_wmem_r_dt  , core_wmem_w_dt   ;
// PORTS
wire                 port_re, port_we        ;
wire [31:0]          dout           ;
reg [63:0]           in_port_dt_r ;
PORT_DT              out_port_data  ;


// T-PROCESSOR CONTROL
///////////////////////////////////////////////////////////////////////////////

// T-PROCESSOR STATE MACHINE
localparam  ST_RESET   = 3'd0;
localparam  ST_PLAY    = 3'd1;
localparam  ST_PAUSE   = 3'd2;
localparam  ST_FREEZE  = 3'd3;
localparam  END_STEP   = 3'd4;
localparam  ST_STOP    = 3'd5;

wire step, ctrl_core_step, ctrl_time_step, ctrl_proc_step, ctrl_pause_core, ctrl_freeze_time, ctrl_stop, ctrl_rst, ctrl_play;

assign ctrl_rst         = TPROC_CTRL[0]  ; // 1
assign ctrl_stop        = TPROC_CTRL[1]  ; // 2
assign ctrl_pause_core  = TPROC_CTRL[2]  ; // 4
assign ctrl_freeze_time = TPROC_CTRL[3]  ; // 8
assign ctrl_play        = TPROC_CTRL[4]  | start_i; // 16
assign ctrl_proc_step   = TPROC_CTRL[5]  ; // 32
assign ctrl_core_step   = TPROC_CTRL[6]  ; // 64
assign ctrl_time_step   = TPROC_CTRL[7]  ; // 128

assign step = ctrl_core_step | ctrl_time_step | ctrl_proc_step;
reg step_r;
always_ff @(posedge c_clk_i)
   if (!c_rst_ni)
      step_r <= 0;
   else 
      step_r = step;

reg [2:0] proc_st_nxt, proc_st = ST_RESET;
reg c_core_en, proc_rst, c_time_en, c_time_rst_ext;

wire [4:0] core_usr_ctrl, core_usr_operation;



always_ff @(posedge c_clk_i)
   if (!c_rst_ni)
      proc_st <= ST_RESET;
   else 
      proc_st = proc_st_nxt;
      
always_comb begin
   c_core_en  = 0;
   proc_rst = 0;
   c_time_en  = 0;
   c_time_rst_ext = 0;
   proc_st_nxt = proc_st;
   //COMMON TRANSITIONS
   if       ( ctrl_rst )            proc_st_nxt = ST_RESET;
   else if  ( ctrl_play )           proc_st_nxt = ST_PLAY;
   else if  ( ctrl_stop )           proc_st_nxt = ST_STOP;
   else if  ( ctrl_pause_core )     proc_st_nxt = ST_PAUSE;
   else if  ( ctrl_freeze_time )    proc_st_nxt = ST_FREEZE;
   else if  ( ctrl_proc_step )      proc_st_nxt = ST_PLAY;
   else if  ( ctrl_time_step )      proc_st_nxt = ST_PAUSE;
   else if  ( ctrl_core_step )      proc_st_nxt = ST_FREEZE;
   case (proc_st)
      ST_RESET : begin
         if ( !ctrl_rst )    proc_st_nxt = ST_STOP ;
         proc_rst = 1;            
         c_time_rst_ext = 1;
      end
      ST_PLAY: begin
         if    ( step_r )      proc_st_nxt = END_STEP;
         c_time_en = 1;
         c_core_en = 1;
      end
      ST_PAUSE: begin
         if    ( step_r )      proc_st_nxt = END_STEP;
         c_time_en = 1;
      end
      ST_FREEZE: begin
         if    ( step_r )      proc_st_nxt = END_STEP;
         c_core_en = 1;
      end
      END_STEP: begin
         if  (!step)            
            proc_st_nxt = ST_STOP;
         else
            proc_st_nxt = END_STEP;
      end

   endcase
end

///////////////////////////////////////////////////////////////////////////////
// Timing Control    // CHECK CLOCK BOUNDARY CROSSING //
///////////////////////////////////////////////////////////////////////////////
wire c_time_rst;
assign c_time_rst    = c_time_rst_ext | (core_usr_ctrl[0]&core_usr_operation[0]) ;

reg time_rst_ext_rcd, t_time_rst_r;
reg time_en_rcd, t_time_en_r ;

// CROSS DOMAIN SIGNALS
always_ff @(posedge t_clk_i) begin
   if (!t_rst_ni) begin
      time_rst_ext_rcd     <= 0;
      time_en_rcd          <= 0;
      t_time_rst_r    <= 0;
      t_time_en_r          <= 0;
   end else begin
      time_rst_ext_rcd     <= c_time_rst;
      time_en_rcd          <= c_time_en;
      t_time_rst_r         <= time_rst_ext_rcd;
      t_time_en_r          <= time_en_rcd;
   end
end
// Time REF - SYNC
///////////////////////////////////////////////////////////////////////////////
reg [47:0] time_abs, c_time_ref_dt;
wire [31:0] core_usr_a_dt, core_usr_b_dt, core_usr_c_dt, core_usr_d_dt ;

always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   if (!t_rst_ni)          time_abs          <= '{default:'0} ;
   else if (t_time_rst_r)  time_abs          <= '{default:'0} ;
   else if (t_time_en_r)   time_abs          <= time_abs + 1'b1 ;
end

always_ff @ (posedge c_clk_i, negedge c_rst_ni) begin
   if (!c_rst_ni)                c_time_ref_dt       <= '{default:'0} ;
   else if (c_time_rst)          c_time_ref_dt       <= '{default:'0} ;
   else if (c_time_en)
      if (core_usr_ctrl[0])
         if       (core_usr_operation[1] )  c_time_ref_dt  <=  {16'd0, core_usr_b_dt} ;
         else if  (core_usr_operation[2] )  c_time_ref_dt  <=  c_time_ref_dt + {16'd0, core_usr_b_dt} ;
end

// CONDITION GENERATION (TIME AND CUSTOM)
///////////////////////////////////////////////////////////////////////////////
reg ext_cond_r, time_cond_r ;
wire [31:0] time_cmp_result ;
// CORE

wire cond_ext_set, cond_ext_clear;
assign cond_ext_set   = TPROC_CTRL[10] | (core_usr_ctrl[1] & core_usr_operation[0]);
assign cond_ext_clear = TPROC_CTRL[11] | (core_usr_ctrl[1] & core_usr_operation[1]);
wire div_rdy;
reg div_rdy_r;

// Register Signals CHANGING DOMAIN
reg [31:0] time_cmp_dt, time_cmp_dt_r, time_cmp_dt_wen_r;
wire time_cmp_dt_wen, tc_updt;
reg in_port_dt_new;

assign time_cmp_dt_wen  = core_usr_ctrl[0] & core_usr_operation[3] ;
assign tc_updt  = time_cmp_dt_wen | time_cmp_dt_wen_r;

always_ff @(posedge c_clk_i) begin
   if (proc_rst) begin
      time_cmp_dt_wen_r <= 0;
      time_cmp_dt_r     <= 0;
      ext_cond_r        <= 0;
      time_cond_r       <= 0;
   end else begin 
      div_rdy_r <= div_rdy;
      time_cond_r      <= time_cmp_result[31] & ~(time_cmp_dt_wen | time_cmp_dt_wen_r);
      time_cmp_dt_wen_r <= time_cmp_dt_wen;
      if ( time_cmp_dt_wen )  time_cmp_dt_r  <= core_usr_b_dt ; // STORE Time Value for Condition
      // Condition 
      if       ( cond_ext_set   )     ext_cond_r     <= 1 ; // SET COND
      else if  ( cond_ext_clear )     ext_cond_r     <= 0 ; // CLEAR COND
      else if  (div_rdy & ~div_rdy_r) ext_cond_r     <= 1 ; // SET COND
      else if  (~div_rdy & div_rdy_r) ext_cond_r     <= 0 ; // CLEAR COND
      else if  ( in_port_dt_new  )    ext_cond_r     <= 1 ; // SET COND
   end
end


// PORT READ
///////////////////////////////////////////////////////////////////////////////

always_ff @(posedge c_clk_i) begin
   if (proc_rst) begin
      in_port_dt_r      <= 0 ;
      in_port_dt_new    <= 0 ;
   end else
      if (port_re) begin
         in_port_dt_r   <= port_dt_i[out_port_data.p_addr];
         in_port_dt_new <= 0;
      end else if (port_dt_new_i)
         in_port_dt_new <= 1;
end
wire [7:0] STATUS;
assign STATUS[0] =  div_rdy;
assign STATUS[1] =  in_port_dt_new ;
assign STATUS[2] =  dfifo_full ;
assign STATUS[3] =  wfifo_full ;
assign STATUS[4] =  wfifo_full ;
assign STATUS[7:5] =  0 ;




// Co Processors
///////////////////////////////////////////////////////////////////////////////

wire [63:0] arith_result;
wire [31:0] div_remainder, div_quotient;

generate
   if (DIVIDER == 1) begin : DIVIDER_YES
      div_r #(
         .DW     ( 32 ) ,
         .N_PIPE ( 32 )
      ) div_r_inst (
         .clk_i           ( c_clk_i ) ,
         .rst_ni          ( c_rst_ni ) ,
         .start_i         ( core_usr_ctrl[3] ) ,
         .A_i             ( core_usr_a_dt ) ,
         .B_i             ( core_usr_b_dt ) ,
         .ready_o         ( div_rdy  ) ,
         .div_remainder_o ( div_remainder ) ,
         .div_quotient_o  ( div_quotient ) );
   end else begin : DIVIDER_NO
      assign div_rdy          = 0;
      assign div_remainder    = 0;
      assign div_quotient     = 0;
   end
endgenerate

generate
   if (ARITH == 1) begin : ARITH_YES
      arith arith_inst (
         .clk_i          ( c_clk_i ) ,
         .rst_ni         ( c_rst_ni ) ,
         .start_i        ( core_usr_ctrl[2] ) ,
         .A_i            ( core_usr_a_dt ) ,
         .B_i            ( core_usr_b_dt ) ,
         .C_i            ( core_usr_c_dt ) ,
         .D_i            ( core_usr_d_dt ) ,
         .alu_op_i       ( core_usr_operation ) ,
         .ready_o        (  ) ,
         .arith_result_o ( arith_result ) );
   end else begin : ARITH_NO
      assign arith_result     = 0;
   end
endgenerate



wire [31:0] c_time_usr, t_time_usr;
generate
   if ( (TIME_CMP == 1) | (TIME_READ == 1))  begin : TIME_YES
      assign t_time_usr = (time_abs - c_time_ref_dt);

      if (TIME_CMP == 1) begin : TIME_CMP_YES
         ADDSUB_MACRO #(
            .DEVICE     ( "7SERIES" ),       // Target Device: "7SERIES" 
            .LATENCY    ( 1         ),       // Desired clock cycle latency, 0-2
            .WIDTH      ( 32        )        // Input / output bus width, 1-48
         ) ADDSUB_MACRO_inst (
            .CARRYOUT   (                 ), // 1-bit carry-out output signal
            .RESULT     ( time_cmp_result ), // Add/sub result output, width defined by WIDTH parameter
            .B          ( t_time_usr      ), // Input A bus, width defined by WIDTH parameter
            .A          ( time_cmp_dt_r   ), // Input B bus, width defined by WIDTH parameter
            .ADD_SUB    ( 1'b0            ), // 1-bit add/sub input, high selects add, low selects subtract
            .CARRYIN    ( 1'b0            ), // 1-bit carry-in input
            .CE         ( 1'b1            ), // 1-bit clock enable input
            .CLK        ( t_clk_i         ), // 1-bit clock input
            .RST        ( ~t_rst_ni         )  // 1-bit active high synchronous reset
         );
      end else begin : TIME_CMP_NO
         assign time_cmp_result     = 0;
      end
      if (TIME_READ == 1) begin : TIME_READ_YES
         sync_reg sync_time_usr_c (
            .dt_i       ( t_time_usr   ) ,
            .clk_i      ( c_clk_i      ) ,
            .rst_ni     ( c_rst_ni     ) ,
            .dt_o       ( c_time_usr   ) );
      end else begin : TIME_READ_NO
         assign c_time_usr     = 789;
      end
   end else begin : TIME_NO
      assign time_cmp_result  = 0;
      assign t_time_usr       = 0;
      assign c_time_usr       = 0;
   end
      

endgenerate



      
///////////////////////////////////////////////////////////////////////////////
// INSTANCES
///////////////////////////////////////////////////////////////////////////////

// T PROCESSOR CORE
///////////////////////////////////////////////////////////////////////////////
wire [15:0] core_do;

wire [OUT_DPORT_QTY-1:0]  fifo_data_empty, fifo_data_full  ;
wire [OUT_WPORT_QTY-1:0]  fifo_wave_empty, fifo_wave_full  ;

assign dfifo_full = |fifo_data_full & ~TPROC_CFG[2]; // With 0 BLOCK
assign wfifo_full = |fifo_wave_full & ~TPROC_CFG[3]; // With 0 BLOCK
assign fifo_ok    = ~wfifo_full & ~dfifo_full ;

assign core_en = c_core_en  & fifo_ok; 

t_core_B # (
   .LFSR       (  LFSR  ),
   .PMEM_AW    (   PMEM_AW  ),
   .DMEM_AW    (   DMEM_AW  ),
   .WMEM_AW    (   WMEM_AW  ),
   .REG_AW     (   REG_AW  )
) t_core_B_inst (
   .clk_i        ( c_clk_i          ) ,
   .rst_ni       ( c_rst_ni         ) ,
   .restart_i    ( proc_rst         ) ,
   .en_i         ( core_en          ) ,
   .cfg_i        ( TPROC_CFG[1:0]   ) ,
   .status_i     ( STATUS [7:0]     ) ,
   .core_do      ( core_do          ) ,
   .ext_cond_i   ( ext_cond_r       ) ,
   .tc_updt_i    ( tc_updt          ) ,
   .time_cond_i  ( time_cond_r      ) ,
   .sreg_arith_i ( arith_result     ) ,
   .sreg_div_i   ( '{div_quotient ,div_remainder} ) ,
   .ext_dt_i     ( ext_dt_i         ) ,
   .port_dt_i    ( in_port_dt_r     ) ,
   .time_dt_i    ( c_time_usr       ) ,
   .sreg_dt_o    ( ext_dt_o         ) ,
   .usr_dt_a_o   ( core_usr_a_dt    ) ,
   .usr_dt_b_o   ( core_usr_b_dt    ) ,
   .usr_dt_c_o   ( core_usr_c_dt    ) ,
   .usr_dt_d_o   ( core_usr_d_dt    ) ,
   .usr_ctrl_o   ( {core_usr_operation, core_usr_ctrl}  ) ,
   .pmem_addr_o  ( pmem_addr_o      ) ,
   .pmem_en_o    ( pmem_en_o        ) ,
   .pmem_dt_i    ( pmem_dt_i        ) ,
   .dmem_we_o    ( dmem_we_o        ) ,
   .dmem_addr_o  ( dmem_addr_o      ) ,
   .dmem_w_dt_o  ( dmem_w_dt_o      ) ,
   .dmem_r_dt_i  ( dmem_r_dt_i      ) ,
   .wmem_we_o    ( wmem_we_o        ) ,
   .wmem_addr_o  ( wmem_addr_o      ) ,
   .wmem_w_dt_o  ( wmem_w_dt_o      ) ,
   .wmem_r_dt_i  ( wmem_r_dt_i      ) ,
   .port_we_o    ( port_we          ) ,
   .port_re_o    ( port_re          ) ,
   .port_o       ( out_port_data    ) ,
   .lfsr_o       ( rand_o           ) );


///////////////////////////////////////////////////////////////////////////////
/// FIFO 
///////////////////////////////////////////////////////////////////////////////
 
wire [167:0]        fifo_wave_dt      [OUT_WPORT_QTY-1:0];
wire [47:0]                fifo_wave_time    [OUT_WPORT_QTY-1:0];
wire [47 :0]               W_RESULT          [OUT_WPORT_QTY-1:0] ;

reg  [OUT_DPORT_QTY-1:0]  data_pop, data_pop_r, data_pop_r2, data_pop_r3, data_pop_r4; 

wire [31 :0]               fifo_data_dt      [OUT_DPORT_QTY-1:0] ;
wire [47: 0]               fifo_data_time    [OUT_DPORT_QTY-1:0];
wire [47 :0]               D_RESULT          [OUT_DPORT_QTY-1:0] ;


reg  [OUT_WPORT_QTY-1:0]  fifo_wave_push, fifo_wave_push_r ;
reg  [OUT_DPORT_QTY-1:0]  fifo_data_push, fifo_data_push_r ; 
reg [47 :0]                fifo_time_in_r ;
reg [167:0]         fifo_data_in_r ;
reg data_pop_prev [OUT_DPORT_QTY-1:0] ;

/// FIFO CTRL-REG
///////////////////////////////////////////////////////////////////////////////
wire fifo_we;
assign fifo_we = port_we & core_en ;

always_ff @ (posedge c_clk_i, negedge c_rst_ni) begin
   if (!c_rst_ni) begin
      fifo_data_in_r       <= '{default:'0} ;
      fifo_time_in_r       <= '{default:'0} ;
      fifo_wave_push_r     <= '{default:'0} ;
      fifo_data_push_r     <= '{default:'0} ;
   end else begin
      fifo_data_in_r       <= out_port_data.p_data ;
      fifo_time_in_r       <= {16'd0, out_port_data.p_time} + c_time_ref_dt;
      fifo_data_push_r     <= fifo_data_push ;
      fifo_wave_push_r     <= fifo_wave_push ;
   end
end

always_comb begin
   fifo_wave_push    = 0;
   fifo_data_push    = 0;
   if (fifo_we)
      if (out_port_data.p_type)
         fifo_data_push [out_port_data.p_addr] = 1'b1 ;
      else
         fifo_wave_push [out_port_data.p_addr] = 1'b1 ;
end   

 ///////////////////////////////////////////////////////////////////////////////
/// WAVE PORT
///////////////////////////////////////////////////////////////////////////////
reg [OUT_WPORT_QTY-1:0] wave_t_eq, wave_t_gr;
reg                     wave_pop_prev      [OUT_WPORT_QTY-1:0] ;
reg [OUT_WPORT_QTY-1:0]  wave_pop ;
reg [OUT_WPORT_QTY-1:0]  wave_pop_r, wave_pop_r2, wave_pop_r3;

genvar ind_wfifo;
generate
   for (ind_wfifo=0; ind_wfifo < OUT_WPORT_QTY; ind_wfifo=ind_wfifo+1) begin: WAVE_FIFO
      // WaveForm FIFO
      BRAM_FIFO_DC_2 # (
         .FIFO_DW (168+48) , 
         .FIFO_AW (8) 
      ) wave_fifo_inst ( 
         .wr_clk_i   ( c_clk_i   ) ,
         .wr_rst_ni  ( c_rst_ni  ) ,
         .wr_en_i    ( core_en   ) ,
         .push_i     ( fifo_wave_push_r   [ind_wfifo] ) ,
         .data_i     ( {fifo_data_in_r,fifo_time_in_r}     ) ,
         .rd_clk_i   ( t_clk_i   ) ,
         .rd_rst_ni  ( t_rst_ni  ) ,
         .rd_en_i    ( t_time_en_r ) ,
         .pop_i      ( wave_pop         [ind_wfifo] ) ,
         .data_o     ( {fifo_wave_dt[ind_wfifo],fifo_wave_time[ind_wfifo]} ) ,
         .flush_i    ( proc_rst ),
         .async_empty_o ( fifo_wave_empty [ind_wfifo] ) ,
         .async_full_o  ( fifo_wave_full  [ind_wfifo] ) );
      // Time Comparator
         ADDSUB_MACRO #(
            .DEVICE     ( "7SERIES" ),                   // Target Device: "7SERIES" 
            .LATENCY    ( 1         ),                   // Desired clock cycle latency, 0-2
            .WIDTH      ( 48        )                    // Input / output bus width, 1-48
         ) ADDSUB_MACRO_inst (
            .CARRYOUT   (                             ), // 1-bit carry-out output signal
            .RESULT     ( W_RESULT[ind_wfifo]         ), // Add/sub result output, width defined by WIDTH parameter
            .B          ( time_abs[47:0]              ), // Input A bus, width defined by WIDTH parameter
            .A          ( fifo_wave_time[ind_wfifo]   ), // Input B bus, width defined by WIDTH parameter
            .ADD_SUB    ( 1'b0                        ), // 1-bit add/sub input, high selects add, low selects subtract
            .CARRYIN    ( 1'b0                        ), // 1-bit carry-in input
            .CE         ( 1'b1                        ), // 1-bit clock enable input
            .CLK        ( t_clk_i                       ), // 1-bit clock input
            .RST        ( ~t_rst_ni                     )  // 1-bit active high synchronous reset
         );
      // POP Generator
      always_comb begin : WAVE_DISPATCHER
         wave_t_eq[ind_wfifo]  = (time_abs == fifo_wave_time[ind_wfifo]) ;
         wave_t_gr[ind_wfifo]  = W_RESULT[ind_wfifo][47];
         wave_pop[ind_wfifo]   = 0;
         wave_pop_prev[ind_wfifo] = wave_pop_r[ind_wfifo] | wave_pop_r2[ind_wfifo] | wave_pop_r3[ind_wfifo];
         if (t_time_en_r & ~fifo_wave_empty[ind_wfifo])
            if ( ( wave_t_eq[ind_wfifo] | wave_t_gr[ind_wfifo] ) & ~wave_pop_prev[ind_wfifo] ) 
               wave_pop      [ind_wfifo] = 1'b1 ;
      end //ALWAYS
   end // FOR
endgenerate



///////////////////////////////////////////////////////////////////////////////
/// DATA PORT
///////////////////////////////////////////////////////////////////////////////
reg [OUT_DPORT_QTY-1:0] data_t_eq, data_t_gr;

genvar ind_dfifo;
generate
   for (ind_dfifo=0; ind_dfifo < OUT_DPORT_QTY; ind_dfifo=ind_dfifo+1) begin: DATA_FIFO
      // DATA FIFO
      BRAM_FIFO_DC_2 # (
         .FIFO_DW (32+48) , 
         .FIFO_AW (8) 
      ) data_fifo_inst ( 
         .wr_clk_i   ( c_clk_i      ) ,
         .wr_rst_ni  ( c_rst_ni     ) ,
         .wr_en_i    ( core_en      ) ,
         .push_i     ( fifo_data_push_r[ind_dfifo] ) ,
         .data_i     ( {fifo_data_in_r[31:0],fifo_time_in_r}  ) ,
         .rd_clk_i   ( t_clk_i      ) ,
         .rd_rst_ni  ( t_rst_ni     ) ,
         .rd_en_i    ( t_time_en_r    ) ,
         .pop_i      ( data_pop        [ind_dfifo] ) ,
         .data_o     ( {fifo_data_dt[ind_dfifo], fifo_data_time[ind_dfifo]} ) ,
         .flush_i    ( proc_rst     ),
         .async_empty_o ( fifo_data_empty [ind_dfifo] ) ,
         .async_full_o  ( fifo_data_full  [ind_dfifo] ) );
      // Time Comparator
      ADDSUB_MACRO #(
            .DEVICE     ("7SERIES"),        // Target Device: "7SERIES" 
            .LATENCY    ( 1   ),            // Desired clock cycle latency, 0-2
            .WIDTH      ( 48  )             // Input / output bus width, 1-48
         ) ADDSUB_MACRO_inst (
            .CARRYOUT   (                             ),    // 1-bit carry-out output signal
            .RESULT     ( D_RESULT[ind_dfifo]         ), // Add/sub result output, width defined by WIDTH parameter
            .B          ( time_abs[47:0]              ),    // Input A bus, width defined by WIDTH parameter
            .ADD_SUB    ( 1'b0                        ),    // 1-bit add/sub input, high selects add, low selects subtract
            .A          ( fifo_data_time[ind_dfifo]   ),   // Input B bus, width defined by WIDTH parameter
            .CARRYIN    ( 1'b0                        ),    // 1-bit carry-in input
            .CE         ( 1'b1                        ),    // 1-bit clock enable input
            .CLK        ( t_clk_i                     ),    // 1-bit clock input
            .RST        ( ~t_rst_ni                   )     // 1-bit active high synchronous reset
         );

      // POP Generator
      always_comb begin : DATA_DISPATCHER
        data_t_eq[ind_dfifo]  = (time_abs == fifo_data_time[ind_dfifo]) ;
        data_t_gr[ind_dfifo]  = D_RESULT[ind_dfifo][47];
         data_pop[ind_dfifo] = 0;
         data_pop_prev[ind_dfifo] = data_pop_r[ind_dfifo] | data_pop_r2[ind_dfifo] | data_pop_r3[ind_dfifo];
         if (t_time_en_r & ~fifo_data_empty[ind_dfifo] )
            if ( ( data_t_eq[ind_dfifo] | data_t_gr[ind_dfifo] ) & ~data_pop_prev[ind_dfifo] ) 
               data_pop      [ind_dfifo] = 1'b1 ;
      end //ALWAYS
   end //FOR      
endgenerate      




// OUT DATA
///////////////////////////////////////////////////////////////////////////////
always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   if (!t_rst_ni) begin
      data_pop_r     <= '{default:'0} ;
      data_pop_r2    <= '{default:'0} ;
      data_pop_r3    <= '{default:'0} ;
      wave_pop_r     <= '{default:'0} ;
      wave_pop_r2    <= '{default:'0} ;
      wave_pop_r3    <= '{default:'0} ;
   end else begin
      data_pop_r     <= data_pop;
      data_pop_r2    <= data_pop_r;
      data_pop_r3    <= data_pop_r2;
      wave_pop_r      <= wave_pop;
      wave_pop_r2     <= wave_pop_r;
      wave_pop_r3     <= wave_pop_r2;

   end
end

reg [31:0]  port_dt_r [OUT_DPORT_QTY];
integer ind_dport;

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////


// OUT DATA
///////////////////////////////////////////////////////////////////////////////
always_ff @ (posedge t_clk_i, negedge t_rst_ni) begin
   for (ind_dport=0; ind_dport < OUT_DPORT_QTY; ind_dport=ind_dport+1) begin: DATA_PORT
      if (!t_rst_ni) 
         port_dt_r[ind_dport]   <= '{default:'0} ;
      else 
        if (data_pop_r[ind_dport]) port_dt_r[ind_dport] <= fifo_data_dt[ind_dport] ;
   end
end
assign port_dt_o = port_dt_r;

assign time_usr_o = c_time_usr ;


// OUT WAVES
///////////////////////////////////////////////////////////////////////////////
genvar ind_wport ;
generate
   for (ind_wport=0; ind_wport < OUT_WPORT_QTY; ind_wport=ind_wport+1) begin: WAVE_PORT
      assign m_axis_tvalid[ind_wport]  = wave_pop_r      [ind_wport] ;
      assign m_axis_tdata [ind_wport]  = fifo_wave_dt [ind_wport] ;
   end
endgenerate

// DEBUG OUTPUTS
//assign dbg_dt_push   = |data_push;
//assign dbg_dt_pop    = |data_pop ;
//assign dbg_wv_push   = |wave_push;
//assign dbg_wv_pop    = |wave_pop  ;



assign TPROC_STATUS[23 : 20]  = { fifo_data_empty[0], fifo_data_full[0], fifo_data_empty[1], fifo_data_full[1]};
assign TPROC_STATUS[19 : 16]  = { fifo_wave_empty[0], fifo_wave_full[0], fifo_wave_empty[1], fifo_wave_full[1] };
assign TPROC_STATUS[15 : 12]  = { pmem_en_o, dmem_we_o, wmem_we_o, port_we};
assign TPROC_STATUS[11 :  8]  = { 2'b00 , time_cond_r, ext_cond_r};
assign TPROC_STATUS[7  :  4]  = { 1'b0  , c_time_en, c_core_en, core_en};
assign TPROC_STATUS[3  :  0]  = { 1'b0  , proc_st};

//assign DEBUG_O[15:12]  = { dbg_dt_push, dbg_dt_pop, dbg_wv_push, dbg_wv_pop};
//assign DEBUG_O[15:12]  = { time_ctrl_2r, time_en_r};
//assign DEBUG_O[11: 8]  = { time_abs[3:0] } ;
//assign DEBUG_O[7 : 4]  = { ext_dt_en, pmem_dt_i[68:66] } ;
//assign DEBUG_O[3 : 0]  = { proc_rst , pmem_dt_i[71:69]};

assign DEBUG_O[15: 8]  = { c_time_ref_dt[7:0] } ;
assign DEBUG_O[7 : 4]  = { fifo_data_time[0][3:0]} ;
assign DEBUG_O[3 : 0]  = { fifo_ok, pmem_dt_i[71:69]};

// core_usr_ctrl[1] & core_usr_operation[0]
// fifo_wave_dt[ind_wfifo],fifo_wave_time[ind_wfifo]

assign t_time_abs_do = time_abs ;
assign t_fifo_do     = {fifo_wave_dt[0][3:0], fifo_wave_time[0][11:0], fifo_data_dt[0][3:0], fifo_data_time[0][11:0] } ;

assign t_debug_do[31 : 28]   = { fifo_wave_full[3], fifo_wave_full[2], fifo_wave_full[1], fifo_wave_full[0] };
assign t_debug_do[27 : 24]   = { fifo_wave_empty[3],fifo_wave_empty[2],fifo_wave_empty[1],fifo_wave_empty[0]  };
assign t_debug_do[23 : 20]   = 0 ;
assign t_debug_do[19 : 16]   = { fifo_data_push_r[0], fifo_wave_push_r[0] } ;
assign t_debug_do[15 : 12]   = { data_t_eq[0], data_t_gr[0], data_pop[0], data_pop_prev[0] } ;
assign t_debug_do[11 : 8]    = { wave_t_eq[0], wave_t_gr[0], wave_pop[0], wave_pop_prev[0] } ;
assign t_debug_do[7 : 4]     = 0;
assign t_debug_do[3 : 0]     = {ctrl_rst, ctrl_play, ctrl_stop, proc_rst};

assign c_core_do     = core_do ;
assign c_port_do     = {fifo_data_in_r[15:0] , fifo_time_in_r[15:0] } ;
assign c_time_ref_do = c_time_ref_dt;

endmodule


