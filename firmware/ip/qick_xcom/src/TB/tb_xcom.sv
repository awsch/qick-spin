///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

`define T_X_CLK         1 
`define T_T_CLK         2 // 1.66 // Half Clock Period for Simulation
`define T_C_CLK         2 
`define T_PS_CLK        5  // Half Clock Period for Simulation

localparam CH       =     7;  // Debugging
localparam SYNC     =     1;  // Debugging
localparam DEBUG    =     1;  // Debugging

// Register ADDRESS
parameter XCOM_CTRL     = 0 * 4 ;
parameter XCOM_CFG      = 1 * 4 ;
parameter RAXI_DT1      = 2 * 4 ;
parameter RAXI_DT2      = 3 * 4 ;
parameter XCOM_ADDR     = 4 * 4 ;
parameter XCOM_FLAG     = 7 * 4 ;
parameter XCOM_DT1      = 8 * 4 ;
parameter XCOM_DT2      = 9 * 4 ;
parameter XCOM_RX_DT    = 12 * 4 ;
parameter XCOM_TX_DT    = 13 * 4 ;
parameter XCOM_STATUS   = 14 * 4 ;
parameter XCOM_DEBUG    = 15 * 4 ;

import axi_vip_pkg::*;
import axi_mst_0_pkg::*;

module tb_axi_xcom();

// AXI 
///////////////////////////////////////////////////////////////////////////////

// VIP Agent
axi_mst_0_mst_t  axi_mst_0_agent;
xil_axi_prot_t   prot = 0;
xil_axi_resp_t   resp;

//AXI-LITE
wire [7:0]             s_axi_awaddr  ;
wire [2:0]             s_axi_awprot  ;
wire                   s_axi_awvalid ;
wire                   s_axi_awready ;
wire [31:0]            s_axi_wdata   ;
wire [3:0]             s_axi_wstrb   ;
wire                   s_axi_wvalid  ;
wire                   s_axi_wready  ;
wire  [1:0]            s_axi_bresp   ;
wire                   s_axi_bvalid  ;
wire                   s_axi_bready  ;
wire [7:0]             s_axi_araddr  ;
wire [2:0]             s_axi_arprot  ;
wire                   s_axi_arvalid ;
wire                   s_axi_arready ;
wire  [31:0]           s_axi_rdata   ;
wire  [1:0]            s_axi_rresp   ;
wire                   s_axi_rvalid  ;
wire                   s_axi_rready  ;

//  AXI AGENT
//////////////////////////////////////////////////////////////////////////
axi_mst_0 axi_mst_0_i (
   .aclk			   (ps_clk		   ),
   .aresetn		   (rst_ni	      ),
   .m_axi_araddr	(s_axi_araddr	),
   .m_axi_arprot	(s_axi_arprot	),
   .m_axi_arready	(s_axi_arready	),
   .m_axi_arvalid	(s_axi_arvalid	),
   .m_axi_awaddr	(s_axi_awaddr	),
   .m_axi_awprot	(s_axi_awprot	),
   .m_axi_awready	(s_axi_awready	),
   .m_axi_awvalid	(s_axi_awvalid	),
   .m_axi_bready	(s_axi_bready	),
   .m_axi_bresp	(s_axi_bresp	),
   .m_axi_bvalid	(s_axi_bvalid	),
   .m_axi_rdata	(s_axi_rdata	),
   .m_axi_rready	(s_axi_rready	),
   .m_axi_rresp	(s_axi_rresp	),
   .m_axi_rvalid	(s_axi_rvalid	),
   .m_axi_wdata	(s_axi_wdata	),
   .m_axi_wready	(s_axi_wready	),
   .m_axi_wstrb	(s_axi_wstrb	),
   .m_axi_wvalid	(s_axi_wvalid	)
);

//  CLK Generation
//////////////////////////////////////////////////////////////////////////
reg x_clk, c_clk, t_clk, ps_clk;
initial begin
  x_clk = 1'b0;
  forever # (`T_X_CLK) x_clk = ~x_clk;
end
initial begin
  t_clk = 1'b0;
  forever # (`T_T_CLK) t_clk = ~t_clk;
end
initial begin
  c_clk = 1'b0;
  forever # (`T_C_CLK) c_clk = ~c_clk;
end
initial begin
  ps_clk = 1'b0;
  forever # (`T_PS_CLK) ps_clk = ~ps_clk;
end

//  SYNC Signal Generation
//////////////////////////////////////////////////////////////////////////
reg pulse_sync_i;
initial begin
  pulse_sync_i = 1'b0;
  forever # (1000) pulse_sync_i = ~pulse_sync_i;
end




// Signals
wire qp_rdy ;
reg rst_ni;
reg [31:0] data_wr     = 32'h12345678;
reg        c_cmd_i  ;
reg [ 4:0] c_op_i;
reg [31:0] c_dt1_i, c_dt2_i, c_dt3_i ;
wire [3:0] id_1, id_2;

wire          xcom_dt1, xcom_ck1, xcom_dt2  , xcom_ck2;
wire [CH-1:0] xcom_dt , xcom_ck ;

//  XCOM1
//////////////////////////////////////////////////////////////////////////
axi_qick_xcom # (
   .CH            ( CH ),
   .SYNC          ( SYNC ),
   .DEBUG         ( DEBUG )
) QICK_XCOM_1 (
   .ps_clk        ( ps_clk        ),
   .ps_aresetn    ( rst_ni        ),
   .c_clk         ( c_clk         ),
   .c_aresetn     ( rst_ni        ),
   .t_clk         ( t_clk         ),
   .t_aresetn     ( rst_ni        ),
   .x_clk         ( x_clk         ),
   .x_aresetn     ( rst_ni        ),
   .pulse_sync_i  ( pulse_sync_i        ),
   .qp_en_i       ( 0 ),
   .qp_op_i       ( 0 ),
   .qp_dt1_i      ( 0 ),
   .qp_dt2_i      ( 0 ),
   .qp_rdy_o      (  ),
   .qp_vld_o      (  ),
   .qp_flag_o     (  ),
   .qp_dt1_o      (  ),
   .qp_dt2_o      (  ),
   .qproc_start_o ( qproc_start_o ),
   .xcom_id_o     ( id_1     ),
   .xcom_ck_i     ( xcom_ck     ),
   .xcom_dt_i     ( xcom_dt     ),
   .xcom_ck_o     ( xcom_ck1     ),
   .xcom_dt_o     ( xcom_dt1     ),
   .s_axi_awaddr  ( s_axi_awaddr  ),
   .s_axi_awprot  ( s_axi_awprot  ),
   .s_axi_awvalid ( s_axi_awvalid ),
   .s_axi_awready ( s_axi_awready ),
   .s_axi_wdata   ( s_axi_wdata   ),
   .s_axi_wstrb   ( s_axi_wstrb   ),
   .s_axi_wvalid  ( s_axi_wvalid  ),
   .s_axi_wready  ( s_axi_wready  ),
   .s_axi_bresp   ( s_axi_bresp   ),
   .s_axi_bvalid  ( s_axi_bvalid  ),
   .s_axi_bready  ( s_axi_bready  ),
   .s_axi_araddr  ( s_axi_araddr  ),
   .s_axi_arprot  ( s_axi_arprot  ),
   .s_axi_arvalid ( s_axi_arvalid ),
   .s_axi_arready ( s_axi_arready ),
   .s_axi_rdata   ( s_axi_rdata   ),
   .s_axi_rresp   ( s_axi_rresp   ),
   .s_axi_rvalid  ( s_axi_rvalid  ),
   .s_axi_rready  ( s_axi_rready  ),         
   .xcom_do       (        ) 
);

//  XCOM2
//////////////////////////////////////////////////////////////////////////
axi_qick_xcom # (
   .CH            ( CH ),
   .SYNC          ( SYNC ),
   .DEBUG         ( DEBUG )
) QICK_XCOM_2 (
   .ps_clk        ( ps_clk        ),
   .ps_aresetn    ( rst_ni        ),
   .c_clk         ( c_clk         ),
   .c_aresetn     ( rst_ni        ),
   .t_clk         ( t_clk         ),
   .t_aresetn     ( rst_ni        ),
   .x_clk         ( x_clk         ),
   .x_aresetn     ( rst_ni        ),
   .pulse_sync_i  ( pulse_sync_i  ),
   .qp_en_i       ( c_cmd_i ),
   .qp_op_i       ( c_op_i  ),
   .qp_dt1_i      ( c_dt1_i ),
   .qp_dt2_i      ( c_dt2_i ),
   .qp_rdy_o      ( qp_rdy ),
   .qp_vld_o      (  ),
   .qp_flag_o     (  ),
   .qp_dt1_o      (  ),
   .qp_dt2_o      (  ),
   .qproc_start_o ( qproc_start_o ),
   .xcom_id_o     ( id_2     ),
   .xcom_ck_i     ( xcom_ck  ),
   .xcom_dt_i     ( xcom_dt  ),
   .xcom_dt_o     ( xcom_dt2     ),
   .xcom_ck_o     ( xcom_ck2     ),
   .s_axi_awaddr  (  ),
   .s_axi_awprot  (  ),
   .s_axi_awvalid (  ),
   .s_axi_awready (  ),
   .s_axi_wdata   (  ),
   .s_axi_wstrb   (  ),
   .s_axi_wvalid  (  ),
   .s_axi_wready  (  ),
   .s_axi_bresp   (  ),
   .s_axi_bvalid  (  ),
   .s_axi_bready  (  ),
   .s_axi_araddr  (  ),
   .s_axi_arprot  (  ),
   .s_axi_arvalid (  ),
   .s_axi_arready (  ),
   .s_axi_rdata   (  ),
   .s_axi_rresp   (  ),
   .s_axi_rvalid  (  ),
   .s_axi_rready  (  ),         
   .xcom_do       (        ) 
);

assign xcom_dt = { 13'd0, xcom_dt2, xcom_dt1 } ;
assign xcom_ck = { 13'd0, xcom_ck2, xcom_ck1 } ;

initial begin
   START_SIMULATION();
   // TEST_AXI () ;
   SIM_SET_ID();
   SIM_CMD_PYTHON () ;
   SIM_CMD_TPROC ();
   // SIM_TX();
   //#2000;
   // SIM_RX();

end

task START_SIMULATION (); begin
   $display("START SIMULATION");
  	// Create agents.
	axi_mst_0_agent 	= new("axi_mst_0 VIP Agent",tb_axi_xcom.axi_mst_0_i.inst.IF);
	// Set tag for agents.
	axi_mst_0_agent.set_agent_tag	("axi_mst_0 VIP");
	// Start agents.
	axi_mst_0_agent.start_master();
   rst_ni   = 1'b0;
   c_cmd_i  = 1'b0 ;
   c_op_i   = 5'd0;
   c_dt1_i  = 0;
   c_dt2_i  = 0;
   #25;
   @ (posedge ps_clk); #0.1;
   rst_ni            = 1'b1;

end
endtask

task SIM_SET_ID(); begin
   $display("SIM Set ID from PYTHON");

   @ (posedge ps_clk); #0.1;
   WRITE_AXI( RAXI_DT1 ,  1); // DATA
   #250; CMD_SET_ID ();
   WRITE_AXI( RAXI_DT1 ,  2); // DATA
   #250; CMD_SET_ID ();
   WRITE_AXI( RAXI_DT1 ,  3); // DATA
   #250; CMD_SET_ID ();
   WRITE_AXI( RAXI_DT1 ,  0); // DATA
   #250; CMD_AUTO_ID ();
 
   #1000;

   @ (posedge c_clk); #0.1;
   c_dt1_i  = 1; // ADDR
   c_op_i   = 5'd16; //SET ID
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_dt1_i  = 2; // ADDR
   c_op_i   = 5'd16; //SET ID
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_dt1_i  = 3; // ADDR
   c_op_i   = 5'd16; //SET ID
   CMD_RUN();

   c_op_i   = 5'd9; //AUTO ID
   CMD_RUN();
end
endtask

task CMD_RUN ();
   wait (qp_rdy == 1'b1);
   @ (posedge c_clk); #0.1;
   c_cmd_i  = 1'b1 ;
   @ (posedge c_clk); #0.1;
   c_cmd_i  = 1'b0 ;
   #250;
endtask

task SIM_CMD_PYTHON(); begin
   $display("SIM Command from PYTHON");
   #250; CMD_SET_FLG ();
   #250; CMD_CLR_FLG ();
   WRITE_AXI( RAXI_DT1 ,  2 ); // ADDR
   
   WRITE_AXI( RAXI_DT2 ,  1); // DATA
   #250; CMD_SEND_8B_DT1 ();
   #250; CMD_SEND_8B_DT2 ();
   
   WRITE_AXI( RAXI_DT2 ,   2); // DATA
   #250; CMD_SEND_16B_DT1 ();
   #250; CMD_SEND_16B_DT2 ();

   WRITE_AXI( RAXI_DT2 ,   3); // DATA
   #500; CMD_SEND_32B_DT1 ();
   #500; CMD_SEND_32B_DT2 ();

   WRITE_AXI( RAXI_DT2 ,   111); // DATA
   #500; CMD_UPDT_8 ();
   WRITE_AXI( RAXI_DT2 ,   2222); // DATA
   #500; CMD_UPDT_16 ();
   WRITE_AXI( RAXI_DT2 ,   33333); // DATA
   #500; CMD_UPDT_32 ();
   #500;

   WRITE_AXI( RAXI_DT1,   1); // FLAG_DATA
   #250; CMD_WR_FLG ();
   WRITE_AXI( RAXI_DT1,   0); // FLAG_DATA
   #250; CMD_WR_FLG ();
   
   WRITE_AXI( RAXI_DT1,   0); // DATA
   WRITE_AXI( RAXI_DT2,   123); // DATA
   #500; CMD_WR_REG ();
   WRITE_AXI( RAXI_DT1,   1); // DATA
   WRITE_AXI( RAXI_DT2,   456); // DATA
   #500; CMD_WR_REG ();
   
   
   WRITE_AXI( RAXI_DT1,   0); // DATA
   WRITE_AXI( RAXI_DT2 ,  11111); // DATA
   #500; CMD_WR_MEM ();

   //#500; CMD_SYNC_START ();
end
endtask   


task SIM_CMD_TPROC(); begin
   $display("SIM Command from TPROC");
   c_dt1_i  = 1 ; // ADDR
   c_dt2_i  = -1; // DATA

   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd1; //SET FLAG
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd0; //CLR FLAG
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd2; //SEND 8_BIT
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd3; //SEND 8_BIT
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd4; //SEND 16_BIT
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd5; //SEND 16_BIT
   CMD_RUN();

   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd6; //SEND 32_BIT
   CMD_RUN();
   #250;
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd7; //SEND 32_BIT
   CMD_RUN();
   #250;

   @ (posedge c_clk); #0.1;
   c_dt1_i  =  0; // ADDR
   c_dt2_i  = 11; // DATA
   c_op_i   = 5'd10; //UPDATE 8_BIT
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_dt2_i  = 2020; // DATA
   c_op_i   = 5'd12; //UPDATE 16_BIT
   CMD_RUN();
   @ (posedge c_clk); #0.1;
   c_dt2_i  = 303030; // DATA
   c_op_i   = 5'd14; //UPDATE 32_BIT
   CMD_RUN();
   #250;

   @ (posedge c_clk); #0.1;
   //c_op_i   = 5'd10; //SYNC
   //CMD_RUN();
   end
   #4000;
endtask



task CMD_CLR_FLG ();
   WRITE_AXI( XCOM_CTRL ,  0 *2+1); // Clear Flag
endtask
task CMD_SET_FLG ();
   WRITE_AXI( XCOM_CTRL ,  1 *2+1); // Set Flag
endtask
task CMD_SEND_8B_DT1 ();
   WRITE_AXI( XCOM_CTRL ,  2 *2+1); // Send 8bit (1)
endtask
task CMD_SEND_8B_DT2 ();
   WRITE_AXI( XCOM_CTRL ,  3 *2+1); // Send 8bit (2)
endtask
task CMD_SEND_16B_DT1 ();
   WRITE_AXI( XCOM_CTRL ,  4 *2+1); // Send 16bit (1)
endtask
task CMD_SEND_16B_DT2 ();
   WRITE_AXI( XCOM_CTRL ,  5 *2+1); // Send 16bit (2)
endtask
task CMD_SEND_32B_DT1 ();
   WRITE_AXI( XCOM_CTRL ,  6 *2+1); // Send 32bit (1)
endtask
task CMD_SEND_32B_DT2 ();
   WRITE_AXI( XCOM_CTRL ,  7 *2+1); // Send 32bit (2)
endtask
task CMD_SYNC_START ();
   WRITE_AXI( XCOM_CTRL ,  8 *2+1); // SYNC_START
endtask
task CMD_AUTO_ID ();
   WRITE_AXI( XCOM_CTRL ,  9 *2+1); // AUTO_AI
endtask
task CMD_UPDT_8 ();
   WRITE_AXI( XCOM_CTRL ,  10 *2+1); // CMD_UPDT_8
endtask
task CMD_UPDT_16 ();
   WRITE_AXI( XCOM_CTRL ,  12 *2+1); // CMD_UPDT_16
endtask
task CMD_UPDT_32 ();
   WRITE_AXI( XCOM_CTRL ,  14 *2+1); // CMD_UPDT_32
endtask
task CMD_SET_ID ();
   WRITE_AXI( XCOM_CTRL ,  16 *2+1); // SYNC_START
endtask
task CMD_WR_FLG ();
   WRITE_AXI( XCOM_CTRL ,  17 *2+1); // 
endtask
task CMD_WR_REG ();
   WRITE_AXI( XCOM_CTRL ,  18 *2+1); // 
endtask
task CMD_WR_MEM ();
   WRITE_AXI( XCOM_CTRL ,  19 *2+1); // 
endtask


task CMD_ALL_1 ();
   WRITE_AXI( XCOM_CTRL ,  31 *2+1); // SYNC_START
endtask


task WRITE_AXI(integer PORT_AXI, DATA_AXI); begin
   @ (posedge ps_clk); #0.1;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(PORT_AXI, prot, DATA_AXI, resp);
   end
endtask

integer ind;

task TEST_AXI (); begin
   $display("-----Writting AXI ");
   WRITE_AXI( RAXI_DT1 ,  -1); // DATA
   WRITE_AXI( XCOM_CTRL ,  0 *2+1); // Clear Flag
   WRITE_AXI( XCOM_CTRL ,  1 *2+1); // Set Flag
   WRITE_AXI( XCOM_CTRL ,  0 *2+1); // Clear Flag
   WRITE_AXI( XCOM_CTRL ,  2 *2+1); // Send 8bit (1)
   WRITE_AXI( XCOM_CTRL ,  3 *2+1); // Send 8bit (2)
   WRITE_AXI( XCOM_CTRL ,  4 *2+1); // Send 16bit (1)
   WRITE_AXI( XCOM_CTRL ,  5 *2+1); // Send 16bit (2)
   WRITE_AXI( XCOM_CTRL ,  6 *2+1); // Send 32bit (1)
   WRITE_AXI( XCOM_CTRL ,  7 *2+1); // Send 32bit (2)
   WRITE_AXI( XCOM_CTRL ,  8 *2+1); // SYNC_START
   WRITE_AXI( XCOM_CTRL ,  9 *2+1); // AUTO_ID
   WRITE_AXI( XCOM_CTRL ,  10 *2+1); // UPDATE DT8
   WRITE_AXI( XCOM_CTRL ,  12 *2+1); // UPDATE DT16
   WRITE_AXI( XCOM_CTRL ,  14 *2+1); // UPDATE DT32
   WRITE_AXI( XCOM_CTRL ,  11 *2+1); // SET_ID
end
   WRITE_AXI( XCOM_CFG ,  1); 
   for (ind = 0; ind <= 15; ind=ind+1) begin
      WRITE_AXI( RAXI_DT1 ,  ind);
      WRITE_AXI( RAXI_DT2 ,  ind); 
      WRITE_AXI( XCOM_ADDR , ind);;
   end

endtask


endmodule




