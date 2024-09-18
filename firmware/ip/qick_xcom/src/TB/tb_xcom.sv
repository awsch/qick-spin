///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

`define T_X_CLK         1 
`define T_T_CLK         2 // 1.66 // Half Clock Period for Simulation
`define T_C_CLK         3 
`define T_PS_CLK        5  // Half Clock Period for Simulation

localparam DEBUG    =     0;  // Debugging

// Register ADDRESS
parameter XCOM_CTRL     = 0 * 4 ;
parameter XCOM_CFG      = 1 * 4 ;
parameter RAXI_DT1      = 2 * 4 ;
parameter XCOM_FLAG     = 7 * 4 ;
parameter XCOM_DT1      = 8 * 4 ;
parameter XCOM_DT2      = 9 * 4 ;
parameter XCOM_STATUS   = 10 * 4 ;

import axi_vip_pkg::*;
import axi_mst_0_pkg::*;

module tb_xcom();

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
reg sync_i;
initial begin
  sync_i = 1'b0;
  forever # (1000) sync_i = ~sync_i;
end




// Signals
reg rst_ni;
reg [31:0] data_wr     = 32'h12345678;
reg        c_cmd_i  ;
reg [ 4:0] c_op_i;
reg [31:0] c_dt1_i, c_dt2_i, c_dt3_i ;

//  XCOM1
//////////////////////////////////////////////////////////////////////////
axi_qick_xcom # (
   .DEBUG         ( DEBUG )
) QICK_XCOM_1 (
   .ps_clk        ( ps_clk        ) ,
   .ps_aresetn    ( rst_ni        ) ,
   .c_clk         ( c_clk         ) ,
   .c_aresetn     ( rst_ni        ) ,
   .t_clk         ( t_clk         ) ,
   .t_aresetn     ( rst_ni        ) ,
   .x_clk         ( x_clk         ) ,
   .x_aresetn     ( rst_ni        ) ,
   .sync_i        ( sync_i        ) ,
   .xcom_en_i     ( c_cmd_i       ) ,
   .xcom_op_i     ( c_op_i        ) ,
   .xcom_dt1_i    ( c_dt1_i       ) ,
   .xcom_rdy_o    ( ready         ) ,
   .xcom_dt1_o    ( qcom_dt1_o    ) ,
   .xcom_dt2_o    ( qcom_dt2_o    ) ,
   .xcom_vld_o    ( qcom_vld_o    ) ,
   .xcom_flag_o   ( qcom_flag_o   ) ,
   .qproc_start_o ( qproc_start_o1 ) ,
   .xcom_i        ( xcom_i        ) ,
   .xcom_o        ( xcom_o        ) ,
   .xcom_t        ( xcom_t        ) ,
   .s_axi_awaddr  ( s_axi_awaddr  ) ,
   .s_axi_awprot  ( s_axi_awprot  ) ,
   .s_axi_awvalid ( s_axi_awvalid ) ,
   .s_axi_awready ( s_axi_awready ) ,
   .s_axi_wdata   ( s_axi_wdata   ) ,
   .s_axi_wstrb   ( s_axi_wstrb   ) ,
   .s_axi_wvalid  ( s_axi_wvalid  ) ,
   .s_axi_wready  ( s_axi_wready  ) ,
   .s_axi_bresp   ( s_axi_bresp   ) ,
   .s_axi_bvalid  ( s_axi_bvalid  ) ,
   .s_axi_bready  ( s_axi_bready  ) ,
   .s_axi_araddr  ( s_axi_araddr  ) ,
   .s_axi_arprot  ( s_axi_arprot  ) ,
   .s_axi_arvalid ( s_axi_arvalid ) ,
   .s_axi_arready ( s_axi_arready ) ,
   .s_axi_rdata   ( s_axi_rdata   ) ,
   .s_axi_rresp   ( s_axi_rresp   ) ,
   .s_axi_rvalid  ( s_axi_rvalid  ) ,
   .s_axi_rready  ( s_axi_rready  ) ,         
   .xcom_do       (        ) 
);
/*
//  XCOM_2
//////////////////////////////////////////////////////////////////////////
axi_qick_xcom # (
   .DEBUG         ( DEBUG )
) QICK_XCOM_2 (
   .c_clk         ( c_clk         ) ,
   .c_aresetn     ( rst_ni        ) ,
   .t_clk         ( t_clk         ) ,
   .t_aresetn     ( rst_ni        ) ,
   .ps_clk        ( ps_clk        ) ,
   .ps_aresetn    ( rst_ni        ) ,
   .sync_i        ( sync_i        ) ,
   .qcom_en_i     ( 0 ) ,
   .qcom_op_i     ( 0 ) ,
   .qcom_dt1_i    ( 0 ) ,
   .qcom_rdy_o    (   ) ,
   .qcom_dt1_o    (   ) ,
   .qcom_dt2_o    (   ) ,
   .qcom_vld_o    (   ) ,
   .qcom_flag_o   (   ) ,
   .qproc_start_o ( qproc_start_o2 ) ,
   .pmod_i        ( pmod_o1        ) ,
   .pmod_o        ( pmod_o2        ) ,
   .s_axi_awaddr  ( 0 ) ,
   .s_axi_awprot  ( 0 ) ,
   .s_axi_awvalid ( 0 ) ,
   .s_axi_awready (  ) ,
   .s_axi_wdata   ( 0 ) ,
   .s_axi_wstrb   ( 0 ) ,
   .s_axi_wvalid  ( 0 ) ,
   .s_axi_wready  (  ) ,
   .s_axi_bresp   (  ) ,
   .s_axi_bvalid  (  ) ,
   .s_axi_bready  (  ) ,
   .s_axi_araddr  ( 0 ) ,
   .s_axi_arprot  ( 0 ) ,
   .s_axi_arvalid ( 0 ) ,
   .s_axi_arready (  ) ,
   .s_axi_rdata   (  ) ,
   .s_axi_rresp   (  ) ,
   .s_axi_rvalid  (  ) ,
   .s_axi_rready  (  ) ,         
   .qcom_do       (  ) 
);
*/



initial begin
   START_SIMULATION();
   TEST_AXI () ;
   // SIM_TX();
   //#2000;
   // SIM_RX();

end

task START_SIMULATION (); begin
   $display("START SIMULATION");
  	// Create agents.
	axi_mst_0_agent 	= new("axi_mst_0 VIP Agent",tb_qcom.axi_mst_0_i.inst.IF);
	// Set tag for agents.
	axi_mst_0_agent.set_agent_tag	("axi_mst_0 VIP");
	// Start agents.
	axi_mst_0_agent.start_master();
   rst_ni   = 1'b0;
   c_cmd_i  = 1'b0 ;
   c_op_i   = 5'd0;
   c_dt1_i  = 0;
   c_dt2_i  = 0;
   c_dt3_i  = 0;
   #25;
   @ (posedge ps_clk); #0.1;
   rst_ni            = 1'b1;

end
endtask


task SIM_CMD_PYTHON(); begin
   $display("SIM Command from PYTHON");
   @ (posedge c_clk); #0.1;
   WRITE_AXI( RAXI_DT1 ,  -1); // DATA
   #250; CMD_SET_FLG ();
   #250; CMD_CLR_FLG ();
   #250; CMD_SEND_8B_DT1 ();
   #250; CMD_SEND_8B_DT2 ();
   #250;
   CMD_SEND_16B_DT1 ();
   #250;
   CMD_SEND_16B_DT2 ();
   #250;
   CMD_SEND_32B_DT1 ();
   #500;
   CMD_SEND_32B_DT2 ();
   #500;
   CMD_SYNC_START ();
   #4000;
   WRITE_AXI( RAXI_DT1 , 0 ); // DATA
   CMD_SEND_32B_DT1 ();
   #500;
   CMD_SEND_32B_DT2 ();
   #500;
end
endtask   


task SIM_CMD_TPROC(); begin
   $display("SIM Command from TPROC");
   c_dt1_i  = -1;

   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd8; //SET FLAG
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
   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd7; //SEND 32_BIT
   CMD_RUN();

   @ (posedge c_clk); #0.1;
   c_op_i   = 5'd10; //SYNC
   CMD_RUN();
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



task WRITE_AXI(integer PORT_AXI, DATA_AXI); begin
   @ (posedge ps_clk); #0.1;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(PORT_AXI, prot, DATA_AXI, resp);
   end
endtask

task TEST_AXI (); begin
   $display("-----Writting AXI ");
   WRITE_AXI( RAXI_DT1 ,  -1); // DATA
   WRITE_AXI( XCOM_CTRL ,  1 *2+1); // Set Flag
   WRITE_AXI( XCOM_CTRL ,  0 *2+1); // Clear Flag
   WRITE_AXI( XCOM_CTRL ,  2 *2+1); // Send 8bit (1)
   WRITE_AXI( XCOM_CTRL ,  3 *2+1); // Send 8bit (2)
   WRITE_AXI( XCOM_CTRL ,  4 *2+1); // Send 16bit (1)
   WRITE_AXI( XCOM_CTRL ,  5 *2+1); // Send 16bit (2)
   WRITE_AXI( XCOM_CTRL ,  6 *2+1); // Send 32bit (1)
   WRITE_AXI( XCOM_CTRL ,  7 *2+1); // Send 32bit (2)
   WRITE_AXI( XCOM_CTRL ,  8 *2+1); // SYNC_START
end
endtask


endmodule




