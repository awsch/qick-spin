///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

import axi_vip_pkg::*;
import axi_mst_0_pkg::*;

`include "proc_defines.svh"

//`define T_TCLK         1.953125  // Half Clock Period for Simulation
`define T_TCLK         1.162574  // Half Clock Period for Simulation
`define T_CCLK         1.66 // Half Clock Period for Simulation
`define T_SCLK         5  // Half Clock Period for Simulation


`define LFSR             1
`define DIVIDER          1
`define ARITH            1
`define TIME_CMP         1
`define TIME_READ        1
`define PMEM_AW          7 
`define DMEM_AW          6 
`define WMEM_AW          5 
`define REG_AW           4 
`define IN_PORT_QTY      3 
`define OUT_DPORT_QTY    1 
`define OUT_WPORT_QTY    8 




module tb_axis_tproc_B ();

///////////////////////////////////////////////////////////////////////////////
// Signals
reg   t_clk, c_clk, s_ps_dma_aclk, rst_ni;

  
   
wire [31:0] port_data_o [`OUT_WPORT_QTY] ;
wire m_axis_tvalid [`OUT_WPORT_QTY] ;
wire m_axis_tdata [`OUT_WPORT_QTY] ;


// VIP Agent
axi_mst_0_mst_t 	axi_mst_0_agent;
xil_axi_prot_t  prot        = 0;
reg[31:0]       data_wr     = 32'h12345678;
xil_axi_resp_t  resp;
//AXI-LITE
//wire                   s_axi_aclk       ;
wire                   s_ps_dma_aresetn    ;
wire [5:0]             s_axi_awaddr     ;
wire [2:0]             s_axi_awprot     ;
wire                   s_axi_awvalid    ;
wire                   s_axi_awready    ;
wire [31:0]            s_axi_wdata      ;
wire [3:0]             s_axi_wstrb      ;
wire                   s_axi_wvalid     ;
wire                   s_axi_wready     ;
wire  [1:0]            s_axi_bresp      ;
wire                   s_axi_bvalid     ;
wire                   s_axi_bready     ;
wire [5:0]             s_axi_araddr     ;
wire [2:0]             s_axi_arprot     ;
wire                   s_axi_arvalid    ;
wire                   s_axi_arready    ;
wire  [31:0]           s_axi_rdata      ;
wire  [1:0]            s_axi_rresp      ;
wire                   s_axi_rvalid     ;
wire                   s_axi_rready     ;

//////////////////////////////////////////////////////////////////////////
//  CLK Generation
initial begin
  t_clk = 1'b0;
  forever # (`T_TCLK) t_clk = ~t_clk;
end
initial begin
  c_clk = 1'b0;
  forever # (`T_CCLK) c_clk = ~c_clk;
end
initial begin
  s_ps_dma_aclk = 1'b0;
  #0.5
  forever # (`T_SCLK) s_ps_dma_aclk = ~s_ps_dma_aclk;
end

  assign s_ps_dma_aresetn  = rst_ni;


reg [255:0] max_value ;
reg axis_dma_start  ;

   

  
reg [255 :0]       s_dma_axis_tdata_i   ;
reg                s_dma_axis_tlast_i   ;
reg                s_dma_axis_tvalid_i  ;
reg                m_dma_axis_tready_i  ;
reg [63 :0]        port_0_dt_i          ;
reg [63 :0]        port_1_dt_i          ;
reg                s_axi_aclk           ;
reg                s_axi_aresetn        ;
reg [5:0]          s_axi_awaddr         ;
reg [2:0]          s_axi_awprot         ;
reg                s_axi_awvalid        ;
reg [31:0]         s_axi_wdata          ;
reg [3:0]          s_axi_wstrb          ;
reg                s_axi_wvalid         ;
reg                s_axi_bready         ;
reg [5:0]          s_axi_araddr         ;
reg [2:0]          s_axi_arprot         ;
reg                s_axi_arvalid        ;
reg                s_axi_rready         ;
reg                axis_aclk            ;
reg                axis_aresetn         ;
reg                m0_axis_tready       ;
reg                m1_axis_tready       ;
reg                m2_axis_tready       ;
reg                m3_axis_tready       ;
wire               s_dma_axis_tready_o  ;
wire [255 :0]      m_dma_axis_tdata_o   ;
wire               m_dma_axis_tlast_o   ;
wire               m_dma_axis_tvalid_o  ;
wire               s_axi_awready        ;
wire               s_axi_wready         ;
wire  [1:0]        s_axi_bresp          ;
wire               s_axi_bvalid         ;
wire               s_axi_arready        ;
wire  [31:0]       s_axi_rdata          ;
wire  [1:0]        s_axi_rresp          ;
wire               s_axi_rvalid         ;
wire [167:0]       m0_axis_tdata        ;
wire               m0_axis_tvalid       ;
wire [167:0]       m1_axis_tdata        ;
wire               m1_axis_tvalid       ;
wire [167:0]       m2_axis_tdata        ;
wire               m2_axis_tvalid       ;
wire [167:0]       m3_axis_tdata        ;
wire               m3_axis_tvalid       ;
wire [167:0]       m4_axis_tdata        ;
wire               m4_axis_tvalid       ;
wire [167:0]       m5_axis_tdata        ;
wire               m5_axis_tvalid       ;
wire [167:0]       m6_axis_tdata        ;
wire               m6_axis_tvalid       ;
wire [31:0]         port_0_dt_o         ;
wire [31:0]         port_1_dt_o         ;
wire [31:0]         port_2_dt_o         ;
wire [31:0]         port_3_dt_o         ;

int val_A, val_B, val_C, val_D, result ;
reg [31:0] result_r, result_2r, result_3r ;

always_ff @ (posedge c_clk) begin 
   result_r        <= result;
   result_2r       <= result_r;
   result_3r       <= result_2r;
end

// Register ADDRESS
parameter REG_TPROC_CTRL       = 0  * 4 ;
parameter REG_RAND             = 1  * 4 ;
parameter TPROC_CFG            = 2  * 4 ;
parameter REG_MEM_ADDR         = 3  * 4 ;
parameter REG_MEM_LEN          = 4  * 4 ;
parameter REG_MEM_DT_I         = 5  * 4 ;
parameter REG_MEM_DT_O         = 6 * 4 ;
parameter REG_TPROC_EXT_I1     = 7  * 4 ;
parameter REG_TPROC_EXT_I2     = 8  * 4 ;
parameter REG_PORT_LSW         = 9  * 4 ;
parameter REG_PORT_HSW         = 10  * 4 ;
parameter REG_TIME_USR         = 11 * 4 ;
parameter REG_TPROC_EXT_O1     = 12 * 4 ;
parameter REG_TPROC_EXT_O2     = 13 * 4 ;
parameter REG_TPROC_STATUS     = 14 * 4 ;
parameter REG_TPROC_DEBUG      = 15 * 4 ;

reg [31:0] data_wr;

axi_mst_0 axi_mst_0_i
	(
		.aclk			   (s_ps_dma_aclk		),
		.aresetn		   (s_ps_dma_aresetn	),
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
reg div_start;   
wire div_end, div_busy;
wire [31:0] div_remainder, div_quotient;

div #(
   .DWA (32) ,
   .DWB (32)
) div_inst (
   .start_i         ( div_start         ) ,
   .A_i             ( port_0_dt_i[31:0] ) ,
   .B_i             ( port_1_dt_i[31:0] ) ,
   .eod_o           (            ) ,
   .div_remainder_o (      ) ,
   .div_quotient_o  (      ) );

div_r #(
   .DW ( 32 ) ,
   .N_PIPE ( 32 )
) div_r_inst (
   .clk_i           ( c_clk ) ,
   .rst_ni          ( rst_ni ) ,
   .start_i         ( div_start ) ,
   .A_i             ( port_0_dt_i[31:0] ) ,
   .B_i             ( port_1_dt_i[31:0] ) ,
   .ready_o         ( div_end  ) ,
   .div_remainder_o ( div_remainder ) ,
   .div_quotient_o  ( div_quotient ) );
   


axis_tproc_B # (
   .LFSR         (  `LFSR ) ,
   .DIVIDER      (  `DIVIDER ) ,
   .ARITH        (  `ARITH ) ,
   .TIME_CMP     (  `TIME_CMP ) ,
   .TIME_READ    (  `TIME_READ ) ,
   .PMEM_AW        (  `PMEM_AW ) ,
   .DMEM_AW        (  `DMEM_AW ) ,
   .WMEM_AW        (  `WMEM_AW ) ,
   .REG_AW         (  `REG_AW ) ,
   .IN_PORT_QTY    (  `IN_PORT_QTY ) ,
   .OUT_DPORT_QTY  (  `OUT_DPORT_QTY ) ,
   .OUT_WPORT_QTY  (  `OUT_WPORT_QTY ) 
) axis_tproc_B (
   .t_clk_i              ( t_clk              ) ,
   .t_aresetn            ( rst_ni              ) ,
   .c_clk_i              ( c_clk              ) ,
   .c_aresetn            ( rst_ni              ) ,
   .s_ps_dma_aclk        ( s_ps_dma_aclk       ) ,
   .s_ps_dma_aresetn     ( s_ps_dma_aresetn    ) ,
   .s_dma_axis_tdata_i   ( s_dma_axis_tdata_i  ) ,
   .s_dma_axis_tlast_i   ( s_dma_axis_tlast_i  ) ,
   .s_dma_axis_tvalid_i  ( s_dma_axis_tvalid_i ) ,
   .s_dma_axis_tready_o  ( s_dma_axis_tready_o ) ,
   .m_dma_axis_tdata_o   ( m_dma_axis_tdata_o  ) ,
   .m_dma_axis_tlast_o   ( m_dma_axis_tlast_o  ) ,
   .m_dma_axis_tvalid_o  ( m_dma_axis_tvalid_o ) ,
   .m_dma_axis_tready_i  ( m_dma_axis_tready_i ) ,
   .s0_axis_tdata        ( port_0_dt_i    ) ,
   .s0_axis_tvalid       ( s0_axis_tvalid ) ,
   .s1_axis_tdata        ( port_1_dt_i    ) ,
   .s1_axis_tvalid       ( s1_axis_tvalid ) ,
   .s2_axis_tdata        ( 64'd2          ) ,
   .s2_axis_tvalid       ( 1'b0 ) ,
   .s3_axis_tdata        ( 64'd3          ) ,
   .s3_axis_tvalid       ( 1'b0 ) ,
   .s4_axis_tdata        ( 64'd4          ) ,
   .s4_axis_tvalid       ( 1'b0 ) ,
   .s5_axis_tdata        ( 64'd5          ) ,
   .s5_axis_tvalid       ( 1'b0 ) ,
   .s6_axis_tdata        ( 64'd6          ) ,
   .s6_axis_tvalid       ( 1'b0 ) ,
   .s7_axis_tdata        ( 64'd7          ) ,
   .s7_axis_tvalid       ( 1'b0 ) , 
   .s_axi_awaddr         ( s_axi_awaddr        ) ,
   .s_axi_awprot         ( s_axi_awprot        ) ,
   .s_axi_awvalid        ( s_axi_awvalid       ) ,
   .s_axi_awready        ( s_axi_awready       ) ,
   .s_axi_wdata          ( s_axi_wdata         ) ,
   .s_axi_wstrb          ( s_axi_wstrb         ) ,
   .s_axi_wvalid         ( s_axi_wvalid        ) ,
   .s_axi_wready         ( s_axi_wready        ) ,
   .s_axi_bresp          ( s_axi_bresp         ) ,
   .s_axi_bvalid         ( s_axi_bvalid        ) ,
   .s_axi_bready         ( s_axi_bready        ) ,
   .s_axi_araddr         ( s_axi_araddr        ) ,
   .s_axi_arprot         ( s_axi_arprot        ) ,
   .s_axi_arvalid        ( s_axi_arvalid       ) ,
   .s_axi_arready        ( s_axi_arready       ) ,
   .s_axi_rdata          ( s_axi_rdata         ) ,
   .s_axi_rresp          ( s_axi_rresp         ) ,
   .s_axi_rvalid         ( s_axi_rvalid        ) ,
   .s_axi_rready         ( s_axi_rready        ) ,
   .m0_axis_tdata        ( m0_axis_tdata       ) ,
   .m0_axis_tvalid       ( m0_axis_tvalid      ) ,
   .m0_axis_tready       ( m0_axis_tready      ) ,
   .m1_axis_tdata        ( m1_axis_tdata       ) ,
   .m1_axis_tvalid       ( m1_axis_tvalid      ) ,
   .m1_axis_tready       ( m1_axis_tready      ) ,
   .m2_axis_tdata        ( m2_axis_tdata       ) ,
   .m2_axis_tvalid       ( m2_axis_tvalid      ) ,
   .m2_axis_tready       ( m2_axis_tready      ) ,
   .m3_axis_tdata        ( m3_axis_tdata       ) ,
   .m3_axis_tvalid       ( m3_axis_tvalid      ) ,
   .m3_axis_tready       ( m3_axis_tready      ) ,
   .m4_axis_tdata        ( m4_axis_tdata       ) ,
   .m4_axis_tvalid       ( m4_axis_tvalid      ) ,
   .m4_axis_tready       ( m4_axis_tready      ) ,
   .m5_axis_tdata        ( m5_axis_tdata       ) ,
   .m5_axis_tvalid       ( m5_axis_tvalid      ) ,
   .m5_axis_tready       ( m5_axis_tready      ) ,
   .m6_axis_tdata        ( m6_axis_tdata       ) ,
   .m6_axis_tvalid       ( m6_axis_tvalid      ) ,
   .m6_axis_tready       ( m6_axis_tready      ) ,
   .port_0_dt_o          ( port_0_dt_o         ) ,
   .port_1_dt_o          ( port_1_dt_o         ) ,
   .port_2_dt_o          ( port_2_dt_o         ) ,
   .port_3_dt_o          ( port_3_dt_o         ) );


reg    s0_axis_tvalid ,    s1_axis_tvalid ;

initial begin

   $display("AXI_WDATA_WIDTH %d",  `AXI_WDATA_WIDTH);

   $display("LFSR %d",  `LFSR);
   $display("DIVIDER %d",  `DIVIDER);
   $display("ARITH %d",  `ARITH);
   $display("TIME_CMP %d",  `TIME_CMP);
   $display("TIME_READ %d",  `TIME_READ);

   $display("DMEM_AW %d",  `DMEM_AW);
   $display("WMEM_AW %d",  `WMEM_AW);
   $display("REG_AW %d",  `REG_AW);
   $display("IN_PORT_QTY %d",  `IN_PORT_QTY);
   $display("OUT_DPORT_QTY %d",  `OUT_DPORT_QTY);
   $display("OUT_WPORT_QTY %d",  `OUT_WPORT_QTY);
   
  
   axis_tproc_B.T_MEM.D_MEM.RAM = '{default:'0} ;
   axis_tproc_B.T_MEM.W_MEM.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.DATA_FIFO[0].data_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[0].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[1].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[2].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[3].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[4].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[5].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[6].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   axis_tproc_B.T_PROC.WAVE_FIFO[7].wave_fifo_inst.fifo_mem.RAM = '{default:'0} ;
   
   $readmemb("/home/mdifeder/Projects/20.2/IPs/axis_tproc_v2/src/TB/prog.bin", axis_tproc_B.T_MEM.P_MEM.RAM);
   
  	// Create agents.
	axi_mst_0_agent 	= new("axi_mst_0 VIP Agent",tb_axis_tproc_B.axi_mst_0_i.inst.IF);
	// Set tag for agents.
	axi_mst_0_agent.set_agent_tag	("axi_mst_0 VIP");
	// Start agents.
	axi_mst_0_agent.start_master();

   rst_ni          = 1'b0;
   axis_dma_start  = 1'b0;
   s0_axis_tvalid  = 1'b0 ;
   s1_axis_tvalid  = 1'b0 ;

   div_start = 1'b0;
   m_dma_axis_tready_i = 1'b1; 
   max_value   = 0;
   #10;
   @ (posedge s_ps_dma_aclk); #0.1;
	rst_ni = 1'b1;
   #10;
   @ (posedge s_ps_dma_aclk); #0.1;
   // LOAD PORT DATA
   port_0_dt_i = 36;
   port_1_dt_i = -1;
   s0_axis_tvalid  = 1'b1 ;
   s1_axis_tvalid  = 1'b1 ;
   @ (posedge s_ps_dma_aclk); #0.1;
   s0_axis_tvalid  = 1'b0 ;
   s1_axis_tvalid  = 1'b0 ;

   @ (posedge c_clk); #0.1;
   div_start = 1'b1;
   @ (posedge c_clk); #0.1;
   div_start = 1'b0;

   WRITE_AXI( REG_TPROC_CTRL, 1); //RST
   WRITE_AXI( REG_TPROC_CTRL, 16); //PLAY

   #500;
   // LOAD PORT DATA
/*   @ (posedge s_ps_dma_aclk); #0.1;
   port_0_dt_i = 249;
   port_1_dt_i = 10;
   s0_axis_tvalid  = 1'b1 ;
   s1_axis_tvalid  = 1'b1 ;
   @ (posedge s_ps_dma_aclk); #0.1;
   s0_axis_tvalid  = 1'b0 ;
   s1_axis_tvalid  = 1'b0 ;
   @ (posedge s_ps_dma_aclk); #0.1;
*/
/*
//Test DIV
   @ (posedge c_clk); #0.1;
   div_start = 1'b1;
   @ (posedge c_clk); #0.1;
   div_start = 1'b0;
   @ (posedge c_clk); #0.1;
*/


   #15000
   WRITE_AXI( REG_TPROC_CTRL, 1); //RST
   WRITE_AXI( REG_TPROC_CTRL, 16); //PLAY

   #40000
   WRITE_AXI( REG_TPROC_CTRL, 1); //RST
   WRITE_AXI( REG_TPROC_CTRL, 16); //PLAY

   #40000
   WRITE_AXI( REG_TPROC_CTRL, 1); //RST
   WRITE_AXI( REG_TPROC_CTRL, 16); //PLAY
   
   WRITE_AXI( REG_TPROC_EXT_I2, 0);
  
   WRITE_AXI( REG_TPROC_EXT_I1, 0);
   COND_SET;
   COND_CLEAR;

   WRITE_AXI( REG_TPROC_EXT_I1, 1);
   COND_SET;
   COND_CLEAR;
   
   WRITE_AXI( REG_TPROC_EXT_I1, 2);
   COND_SET;
   COND_CLEAR;
   
   WRITE_AXI( REG_TPROC_EXT_I1, 3);
   COND_SET;
   COND_CLEAR;

   WRITE_AXI( REG_TPROC_EXT_I1, 4);
   COND_SET;
   COND_CLEAR;
   WRITE_AXI( REG_TPROC_EXT_I1, 5);
   COND_SET;
   COND_CLEAR;
   WRITE_AXI( REG_TPROC_EXT_I1, 6);
   COND_SET;
   COND_CLEAR;


   #50000;

   $display("RESET");
   WRITE_AXI( REG_TPROC_CTRL, 1);
  

  
   //WAVE MEMORY WRITE
   data_wr = 32'b00000000_0000000_00000000_0000_11_11;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);
   //Start DMA TRANSFER
   axis_dma_start = 1'b1;
   @(posedge s_dma_axis_tlast_i);
   axis_dma_start = 1'b0;
   data_wr = 32'b00000000_0000000_00000000_00000000;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);
   @ (posedge s_ps_dma_aclk); #0.1;

   //DATA MEMORY READ
   data_wr   = 0; // START ADDR 0
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_MEM_ADDR, prot, data_wr, resp);

   data_wr   = 24; // Amount of data
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_MEM_LEN, prot, data_wr, resp);

   data_wr = 32'b00000000_0000000_00000000_00001001;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);

   //Wait for DMA TRANSFER
   @(posedge m_dma_axis_tlast_o);
   data_wr = 32'b00000000_0000000_00000000_00000000;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);
   @ (posedge s_ps_dma_aclk); #0.1;


   //DATA MEMORY READ
   data_wr   = 10; // START ADDR 10
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_MEM_ADDR, prot, data_wr, resp);
   data_wr   = 10; // Amount of data
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_MEM_LEN, prot, data_wr, resp);

   @ (posedge s_ps_dma_aclk); #0.1;

   data_wr = 32'b00000000_0000000_00000000_00001001;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);
   //Wait for DMA TRANSFER
   @(posedge m_dma_axis_tlast_o);
   data_wr = 32'b00000000_0000000_00000000_00000000;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(TPROC_CFG, prot, data_wr, resp);

   @ (posedge s_ps_dma_aclk); #0.1;
   #(`T_SCLK/2)

   @ (posedge s_ps_dma_aclk); #0.1;
   data_wr   = 1; //RST
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_TPROC_CTRL, prot, data_wr, resp);
   @ (posedge s_ps_dma_aclk); #0.1;
   #(`T_SCLK/2)
   data_wr   = 2; //PLAY
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_TPROC_CTRL, prot, data_wr, resp);
   #100000;



end


task WRITE_AXI(integer PORT_AXI, DATA_AXI); begin
   $display("Write to AXI");
   $display("PORT %d",  PORT_AXI);
   $display("DATA %d",  DATA_AXI);

   @ (posedge s_ps_dma_aclk); #0.1;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(PORT_AXI, prot, DATA_AXI, resp);
   end
endtask

task COND_CLEAR; begin
   $display("COND CLEAR");
   @ (posedge s_ps_dma_aclk); #0.1;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_TPROC_CTRL, prot, 2048, resp);
   end
endtask

task COND_SET; begin
   $display("COND SET");
   @ (posedge s_ps_dma_aclk); #0.1;
   axi_mst_0_agent.AXI4LITE_WRITE_BURST(REG_TPROC_CTRL, prot, 20481024, resp);
   end
endtask




endmodule




