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
   input  wire             c_clk_i     ,
   input  wire             c_rst_ni    ,
   input  wire             x_clk_i     ,
   input  wire             x_rst_ni    ,
// XCOM CFG
   input  wire  [3:0]      port_id_i   ,
// XCOM CNX
   input  wire [CH-1:0]    rx_dt_i     ,
   input  wire [CH-1:0]    rx_ck_i     ,
// Command Processing
   output wire             cmd_vld_o ,
   output wire [ 3:0]      cmd_op_o  ,
   output wire [31:0]      cmd_dt_o  ,
   output wire [ 3:0]      cmd_id_o  );

wire [CH-1:0]  rx_req_s      ;
reg  [CH-1:0]  rx_ack_s      ;
reg            rx_cmd_valid  ;
wire [ 3:0]    rx_cmd_s  [CH];
wire [31:0]    rx_data_s [CH];
reg  [ 3:0]    rx_cmd_ind    ;

reg            rx_cmd_req, rx_cmd_id_wr;
reg [3:0]      rx_cmd_id ;
wire           rx_cmd_ack;

wire           c_cmd_req ;
reg            c_cmd_ack ;
reg            c_cmd_vld;

// LINK RECEIVERS 
/////////////////////////////////////////////////////////////////////////////
genvar ind_rx;
generate
   for (ind_rx=0; ind_rx < CH ; ind_rx=ind_rx+1) begin: RX
      xcom_link_rx LINK (
         .x_clk_i     ( x_clk_i   ),
         .x_rst_ni    ( x_rst_ni  ),
         .xcom_id_i   ( port_id_i ),
         .rx_req_o    ( rx_req_s [ind_rx] ),
         .rx_ack_i    ( rx_ack_s [ind_rx] ),
         .rx_cmd_o    ( rx_cmd_s [ind_rx] ),
         .rx_data_o   ( rx_data_s[ind_rx] ),
         .rx_dt_i     ( rx_dt_i  [ind_rx] ),
         .rx_ck_i     ( rx_ck_i  [ind_rx] )
      );
  end
endgenerate


// RX Command Priority Encoder
/////////////////////////////////////////////////////////////////////////////
integer i ;
always_comb begin
  rx_cmd_valid  = 1'b0;
  rx_cmd_ind    = 0;
  for (i = 0 ; i < CH; i=i+1)
    if (!rx_cmd_valid & rx_req_s[i]) begin
      rx_cmd_valid   = 1'b1;
      rx_cmd_ind     = i;
   end
end

typedef enum { X_IDLE, X_REQ, X_ACK} TYPE_CMD_ST ;
(* fsm_encoding = "one_hot" *) TYPE_CMD_ST x_cmd_st;
TYPE_CMD_ST x_cmd_st_nxt;

always_ff @ (posedge x_clk_i) begin
   if      ( !x_rst_ni   )  x_cmd_st  <= X_IDLE;
   else                     x_cmd_st  <= x_cmd_st_nxt;
end

always_comb begin
   x_cmd_st_nxt   = x_cmd_st; // Default Current
   rx_cmd_req   = 1'b0;
   rx_cmd_id_wr = 1'b0;
   case (x_cmd_st)
      X_IDLE   :  begin
         if ( rx_cmd_valid ) begin
            x_cmd_st_nxt = X_REQ;
            rx_cmd_req   = 1'b1;
            rx_cmd_id_wr = 1'b1;
         end
      end
      X_REQ  :  begin
         rx_cmd_req       = 1'b1;
         if ( rx_cmd_ack ) x_cmd_st_nxt = X_ACK;     
      end
      X_ACK  :  begin
         if ( !rx_cmd_ack ) x_cmd_st_nxt = X_IDLE;     
      end
      default: x_cmd_st_nxt = x_cmd_st;
   endcase
end

// RX Caller ID
/////////////////////////////////////////////////////////////////////////////
always_ff @ (posedge x_clk_i) begin
   if      ( !x_rst_ni   )  rx_cmd_id  <= 0;
   else if ( rx_cmd_id_wr ) rx_cmd_id  <= rx_cmd_ind;
end

// RX Command Decoder ACK
/////////////////////////////////////////////////////////////////////////////
integer ind_ch;
always_comb begin
   for (ind_ch=0; ind_ch < CH ; ind_ch=ind_ch+1) begin: RX_DECOX
      if (ind_ch == rx_cmd_id)
         rx_ack_s[ind_ch] = rx_cmd_ack;
      else 
         rx_ack_s[ind_ch] = 1'b0;
    end
end

// C CLOCK REQ SYNC 
///////////////////////////////////////////////////////////////////////////////
sync_reg #(.DW(1)) rx_req_sync (
   .dt_i      ( rx_cmd_req  ) ,
   .clk_i     ( c_clk_i     ) ,
   .rst_ni    ( c_rst_ni    ) ,
   .dt_o      ( c_cmd_req   ) );


// X CLOCK ACK SYNC 
/////////////////////////////////////////////////////////////////////////////
sync_reg #(.DW(1)) SYNC (
   .dt_i      ( c_cmd_ack   ) ,
   .clk_i     ( x_clk_i     ) ,
   .rst_ni    ( x_rst_ni    ) ,
   .dt_o      ( rx_cmd_ack  ) );
   
 
typedef enum { C_IDLE, C_EXEC, C_ACK} TYPE_C_CMD_ST ;
(* fsm_encoding = "one_hot" *) TYPE_C_CMD_ST c_cmd_st;
TYPE_C_CMD_ST c_cmd_st_nxt;

always_ff @ (posedge c_clk_i) begin
   if      ( !c_rst_ni   )  c_cmd_st  <= C_IDLE;
   else                     c_cmd_st  <= c_cmd_st_nxt;
end

always_comb begin
   c_cmd_st_nxt = c_cmd_st; // Default Current
   c_cmd_vld    = 1'b0;
   c_cmd_ack    = 1'b0;
   case (c_cmd_st)
      C_IDLE : begin
         if ( c_cmd_req ) begin
            c_cmd_vld    = 1'b1;
            c_cmd_ack    = 1'b1;
            c_cmd_st_nxt  = C_ACK;
         end
      end
      C_EXEC : begin
         c_cmd_vld    = 1'b1;
         c_cmd_ack    = 1'b1;
         c_cmd_st_nxt = C_ACK;     
      end
      C_ACK : begin
         c_cmd_ack    = 1'b1;
         if ( !c_cmd_req )
            c_cmd_st_nxt  = C_IDLE; 
      end
      default: c_cmd_st_nxt = c_cmd_st;
   endcase
end

wire [ 3:0] c_cmd_id, c_cmd_op ;
wire [31:0] c_cmd_dt ;

assign c_cmd_op = rx_cmd_s[rx_cmd_id];
assign c_cmd_dt = rx_data_s[rx_cmd_id];
assign c_cmd_id = rx_cmd_id;

  
// OUTPUTS
///////////////////////////////////////////////////////////////////////////////
assign cmd_op_o  = c_cmd_op ;
assign cmd_dt_o  = c_cmd_dt ;
assign cmd_id_o  = c_cmd_id ;
assign cmd_vld_o = c_cmd_vld;

endmodule
