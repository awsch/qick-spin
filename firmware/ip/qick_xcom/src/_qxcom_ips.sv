///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 2024_5
//  Version        : 1
///////////////////////////////////////////////////////////////////////////////

/// Clock Domain Register Change
module sync_reg # (
   parameter DW  = 32
)(
   input  wire [DW-1:0] dt_i     , 
   input  wire          clk_i  ,
   input  wire          rst_ni  ,
   output wire [DW-1:0] dt_o     );
   
(* ASYNC_REG = "TRUE" *) reg [DW-1:0] data_cdc, data_r ;
always_ff @(posedge clk_i)
   if(!rst_ni) begin
      data_cdc  <= 0;
      data_r    <= 0;
   end else begin 
      data_cdc  <= dt_i;
      data_r    <= data_cdc;
      end
assign dt_o = data_r ;

endmodule

/*
module sync_cmd (
   input  wire             dst_clk_i    ,
   input  wire             dst_rst_ni   ,
   input  wire             src_clk_i    ,
   input  wire             src_rst_ni   ,
   // Sync 
   input  wire             sync_i       ,
   
   // Command Input
   input  wire             src_vld_i     ,
   input  wire [ 4:0]      src_op_i      ,
   input  wire [ 3:0]      src_dst_i ,
   input  wire [31:0]      src_dt_i ,
   // Command Execution
   output wire             cmd_int_req_o   ,
   output wire             cmd_ext_req_o   ,
   input  wire             cmd_ack_i   ,
   output wire [ 7:0]      cmd_op_o    ,
   output wire [31:0]      cmd_dt_o ,
   output wire [3:0]       cmd_cnt_do
   
   );

reg        src_req;
reg [ 4:0] src_op_r, src_dst_r;
reg [31:0] src_dt_r ;
reg [ 7:0] cmd_op;
reg [31:0] cmd_dt  ;
reg [ 3:0] cmd_cnt;

// Syncronice SYNC signal with Clock. and generates Pulse
///////////////////////////////////////////////////////////////////////////////
sync_reg #(.DW(1)) sync_pulse (
   .dt_i      ( sync_i     ),
   .clk_i     ( src_clk_i    ),
   .rst_ni    ( src_rst_ni   ),
   .dt_o      ( sync_s     ));
   
reg sync_r ;
always_ff @ (posedge src_clk_i, negedge src_rst_ni) begin
   if (!src_rst_ni) sync_r    <= 1'b0; 
   else             sync_r   <= sync_s;
end
assign sync_t01 = !sync_r & sync_s ;

// Register the Operation and Data.
///////////////////////////////////////////////////////////////////////////////
always_ff @(posedge src_clk_i) 
   if (!src_rst_ni) begin
      src_op_r       <= '{default:'0};
      src_dst_r      <= '{default:'0};
      src_dt_r       <= '{default:'0};
   end else begin 
      if (src_vld_i & !src_ack) begin 
         src_op_r    <= src_op_i;
         src_dst_r   <= src_dst_i;
         src_dt_r    <= src_dt_i;
      end
   end
   
   
// Generates the REQUEST 
///////////////////////////////////////////////////////////////////////////////
assign xcmd_sync     = ( src_op_i[3:0] == 3'b100 ); // Sync Command

typedef enum { IDLE, WSYNC, WRDY } TYPE_CMD_ST ;
(* fsm_encoding = "sequential" *) TYPE_CMD_ST cmd_st;
TYPE_CMD_ST cmd_st_nxt;

always_ff @ (posedge src_clk_i) begin
   if  ( !src_rst_ni ) cmd_st <= IDLE;
   else                cmd_st <= cmd_st_nxt;
end

always_comb begin
   cmd_st_nxt = cmd_st; // Default Current
   src_req        = 1'b0;
   case (cmd_st)
      IDLE   :  begin
         if ( src_vld_i )
            if (xcmd_sync) cmd_st_nxt = WSYNC;     
            else           cmd_st_nxt = WRDY;     
      end
      WSYNC   :  begin
         if ( sync_t01 )   cmd_st_nxt = WRDY;     
      end
      WRDY   :  begin
         src_req = 1'b1;
         if ( src_ack & !src_vld_i)     cmd_st_nxt = IDLE;     
      end
      default: cmd_st_nxt = cmd_st;
   endcase
end


sync_reg #(.DW(1)) sync_req (
   .dt_i      ( src_req    ),
   .clk_i     ( dst_clk_i  ),
   .rst_ni    ( dst_rst_ni ),
   .dt_o      ( dst_req    ));

sync_reg #(.DW(1)) sync_ack (
   .dt_i      ( cmd_req    ),
   .clk_i     ( src_clk_i  ),
   .rst_ni    ( src_rst_ni ),
   .dt_o      ( src_ack    ));

assign cmd_req = cmd_ext_req |  cmd_int_req;

reg cmd_ext_req, cmd_int_req;

always_ff @(posedge dst_clk_i) 
   if (!dst_rst_ni) begin
      cmd_ext_req     <= 1'b0;
      cmd_int_req     <= 1'b0;
      cmd_op      <= '{default:'0};
      cmd_dt      <= '{default:'0};
      cmd_cnt     <= 4'd0;
   end else begin 
      if (dst_req & !cmd_ack_i) begin
         cmd_ext_req  <= !src_op_r[4];
         cmd_int_req  <=  src_op_r[4];
         cmd_op       <= {src_op_r[3:0], src_dst_r} ;
         cmd_dt       <= src_dt_r ;
         cmd_cnt      <= cmd_cnt + 1'b1;
      end else
      if ( cmd_ack_i & !dst_req) begin
         cmd_ext_req  <= 1'b0;
         cmd_int_req  <= 1'b0;
      end
   end

// OUTPUTS
///////////////////////////////////////////////////////////////////////////////
assign cmd_ext_req_o  = cmd_ext_req;
assign cmd_int_req_o  = cmd_int_req;
assign cmd_op_o   = cmd_op;
assign cmd_dt_o   = cmd_dt;

// DEBUG
///////////////////////////////////////////////////////////////////////////////
assign cmd_cnt_do = cmd_cnt; 

endmodule
*/

module req_ack_cmd (
   input  wire             src_clk_i   ,
   input  wire             src_rst_ni  ,
   // Command Input
   input  wire             src_vld_i   ,
   input  wire [ 4:0]      src_op_i    ,
   input  wire [ 3:0]      src_dst_i   ,
   input  wire [31:0]      src_dt_i    ,
   // Command Execution
   output reg              loc_req_o   ,
   output reg              net_req_o   ,
   input  wire             async_ack_i ,
   input  wire             sync_ack_i  ,
   output wire [ 7:0]      cmd_op_o    ,
   output wire [31:0]      cmd_dt_o    ,
   output reg  [3:0]       cmd_cnt_do
);

sync_reg #(.DW(1)) sync_ack (
   .dt_i      ( async_ack_i ),
   .clk_i     ( src_clk_i   ),
   .rst_ni    ( src_rst_ni  ),
   .dt_o      ( async_ack_s  ));

assign ack_s = sync_ack_i | async_ack_s ;
   
typedef enum { IDLE, LOC_REQ, NET_REQ, ACK} TYPE_CMD_ST ;
(* fsm_encoding = "one_hot" *) TYPE_CMD_ST cmd_st;
TYPE_CMD_ST cmd_st_nxt;

always_ff @ (posedge src_clk_i) begin
   if      ( !src_rst_ni ) cmd_st <= IDLE;
   else                    cmd_st <= cmd_st_nxt;
end

always_comb begin
   cmd_st_nxt  = cmd_st; // Default Current
   loc_req_o   = 1'b0;
   net_req_o   = 1'b0;
   case (cmd_st)
      IDLE   :  begin
         if ( src_vld_i ) 
            if (src_op_i[4]) begin
                cmd_st_nxt  = LOC_REQ;
                loc_req_o   =  1'b1;
            end else begin
                cmd_st_nxt  = NET_REQ;
                net_req_o   = 1'b1;
         end
      end
      LOC_REQ  :  begin
         loc_req_o       = 1'b1;
         if ( ack_s ) cmd_st_nxt = ACK;     
      end
      NET_REQ  :  begin
         net_req_o       = 1'b1;
         if ( ack_s ) cmd_st_nxt = ACK;     
      end
      ACK  :  begin
         if ( !ack_s ) cmd_st_nxt = IDLE;     
      end
      default: cmd_st_nxt = cmd_st;
   endcase
end

// assign req = loc_req_o | net_req_o ;

 
reg  [ 7:0]   cmd_op_r;
reg  [31:0]   cmd_dt_r;
reg  [ 3:0]   cmd_cnt;
wire [ 7:0]   cmd_op_s;
assign cmd_op_s = {src_op_i[3:0], src_dst_i};

always_ff @(posedge src_clk_i) 
   if (!src_rst_ni) begin
      cmd_op_r   <= '{default:'0};
      cmd_dt_r   <= '{default:'0};
      cmd_cnt    <= 4'd0;
   end else if ( src_vld_i ) begin
      cmd_op_r   <= cmd_op_s ;
      cmd_dt_r   <= src_dt_i ;
      cmd_cnt    <= cmd_cnt + 1'b1;
   end
   
   
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////
assign cmd_op_o   = src_vld_i ? cmd_op_s : cmd_op_r;
assign cmd_dt_o   = src_vld_i ? src_dt_i : cmd_dt_r;

// DEBUG
///////////////////////////////////////////////////////////////////////////////
assign cmd_cnt_do = cmd_cnt; 

endmodule