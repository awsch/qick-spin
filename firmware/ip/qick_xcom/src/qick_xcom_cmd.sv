///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_5
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////
   
module qick_xcom_cmd (
   input  wire             ps_clk_i    ,
   input  wire             ps_rst_ni   ,
   input  wire             c_clk_i     ,
   input  wire             c_rst_ni    ,
   input  wire             x_clk_i     ,
   input  wire             x_rst_ni    ,
   // Command from tProcessor
   input  wire             c_en_i      ,
   input  wire [ 4:0]      c_op_i      ,
   input  wire [31:0]      c_dt_i [2]  ,
   // Command from Python
   input  wire [ 5:0]      p_ctrl_i    ,
   input  wire [31:0]      p_dt_i [2]  ,
   // Command Execution
   output wire             cmd_loc_req_o ,
   input  wire             cmd_loc_ack_i ,
   output wire             cmd_net_req_o ,
   input  wire             cmd_net_ack_i ,
   output wire [ 7:0]      cmd_op_o      ,
   output wire [31:0]      cmd_dt_o      ,
   output wire [ 7:0]      cmd_cnt_do    );

wire          p_loc_req, c_loc_req; 
wire p_loc_req_s;
wire          p_net_req, c_net_req; 
wire [ 7:0]   p_op , c_op ;  
wire [31:0]   p_dt , c_dt ;
wire [ 3:0]   p_cnt, c_cnt;

// PS Command Request 
///////////////////////////////////////////////////////////////////////////////
req_ack_cmd PS_CMD_SYNC (
   .src_clk_i   ( ps_clk_i       ),
   .src_rst_ni  ( ps_rst_ni      ),
   .src_vld_i   ( p_ctrl_i[0]    ),
   .src_op_i    ( p_ctrl_i[5:1]  ),
   .src_dst_i   ( p_dt_i[0][3:0] ),
   .src_dt_i    ( p_dt_i[1]      ),
   .loc_req_o   ( p_loc_req      ),
   .net_req_o   ( p_net_req      ),
   .async_ack_i ( cmd_req        ),
   .sync_ack_i  ( 0              ),
   .cmd_op_o    ( p_op           ),
   .cmd_dt_o    ( p_dt           ),
   .cmd_cnt_do  ( p_cnt          ));



// C_CLK Command Request
///////////////////////////////////////////////////////////////////////////////
req_ack_cmd C_CMD_SYNC (
   .src_clk_i   ( c_clk_i        ),
   .src_rst_ni  ( c_rst_ni       ),
   .src_vld_i   ( c_en_i         ),
   .src_op_i    ( c_op_i         ),
   .src_dst_i   ( c_dt_i[0][3:0] ),
   .src_dt_i    ( c_dt_i[1]      ),
   .loc_req_o   ( c_loc_req      ),
   .net_req_o   ( c_net_req      ),
   .async_ack_i ( 0 ),
   .sync_ack_i  ( cmd_req        ),
   .cmd_op_o    ( c_op           ),
   .cmd_dt_o    ( c_dt           ),
   .cmd_cnt_do  ( c_cnt          ));


// COMMAND OPERATON
reg cmd_net_req, cmd_loc_req;


sync_reg #(.DW(1)) sync_loc_req (
   .dt_i      ( p_loc_req   ),
   .clk_i     ( c_clk_i   ),
   .rst_ni    ( c_rst_ni  ),
   .dt_o      ( p_loc_req_s ));
   
assign net_req = c_net_req | p_net_req;
assign loc_req = c_loc_req | p_loc_req_s;
assign c_req   = c_loc_req | c_net_req;


sync_reg #(.DW(1)) sync_net_req (
   .dt_i      ( net_req   ),
   .clk_i     ( x_clk_i   ),
   .rst_ni    ( x_rst_ni  ),
   .dt_o      ( net_req_s ));



wire [ 7:0] cmd_op_s;
wire [31:0] cmd_dt_s;
assign cmd_op_s = c_req ? c_op : p_op ;
assign cmd_dt_s = c_req ? c_dt : p_dt ;

// Local Command
always_ff @(posedge c_clk_i) 
   if      ( !c_rst_ni )                 cmd_loc_req <= 1'b0;
   else if (  loc_req & !cmd_loc_ack_i ) cmd_loc_req <= 1'b1;
   else if ( !loc_req &  cmd_loc_ack_i ) cmd_loc_req <= 1'b0;

// Net Command
always_ff @(posedge x_clk_i) 
   if      ( !x_rst_ni )                 cmd_net_req <= 1'b0;
   else if ( net_req_s & !cmd_net_ack_i) cmd_net_req <= 1'b1;
   else if ( !net_req_s & cmd_net_ack_i) cmd_net_req <= 1'b0;


assign cmd_req = cmd_loc_req | cmd_net_req ;

// DEBUG
///////////////////////////////////////////////////////////////////////////////
assign cmd_cnt_do ={ c_cnt, p_cnt };  

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////
assign cmd_net_req_o = cmd_net_req;
assign cmd_loc_req_o = cmd_loc_req;
assign cmd_op_o   = cmd_op_s;
assign cmd_dt_o   = cmd_dt_s;

endmodule