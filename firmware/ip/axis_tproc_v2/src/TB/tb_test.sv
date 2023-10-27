///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

//import axi_vip_pkg::*;
//import axi_mst_0_pkg::*;

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




module tb_test ();

///////////////////////////////////////////////////////////////////////////////
// Signals
reg   t_clk, c_clk, rst_ni;

reg         wr_clk_i   ;
reg         wr_rst_ni  ;
reg         wr_en_i    ;
reg         push       ;
reg [31:0]  data_i     ;
reg         rd_clk_i   ;
reg         rd_rst_ni  ;
reg         rd_en_i    ;
reg         pop        ;
reg         flush_i    ;
wire [31:0]  data_o     ; 
wire        empty_o    ; 
wire        full_o     ;


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

BRAM_FIFO_DC_2 # (
   .FIFO_DW (32) , 
   .FIFO_AW (2) 
) fifo_inst ( 
   .wr_clk_i   ( wr_clk_i  ) ,
   .wr_rst_ni  ( wr_rst_ni ) ,
   .wr_en_i    ( wr_en_i   ) ,
   .push_i     ( push      ) ,
   .data_i     ( data_i    ) ,
   .rd_clk_i   ( rd_clk_i  ) ,
   .rd_rst_ni  ( rd_rst_ni ) ,
   .rd_en_i    ( rd_en_i   ) ,
   .pop_i      ( pop       ) ,
   .data_o     ( data_o    ) ,
   .flush_i    ( flush_i   ) ,
   .async_empty_o    ( empty_o   ) ,
   .async_full_o     ( full_o    ) );

assign rd_clk_i = t_clk ;
assign wr_clk_i = c_clk ;
assign wr_rst_ni = rst_ni ;
assign rd_rst_ni = rst_ni ;

// Sample Pointers
reg [31:0] data_read; 
always_ff @(posedge rd_clk_i) begin
   if ( pop ) data_read <= data_o; 
end

///////////////////////////////////////////////////////////////////////////////
initial begin
   fifo_inst.fifo_mem.RAM = '{default:'0} ;

   //RESET
   rst_ni          = 1'b0;
   
   //INITIALIZE SIGNALS
   wr_clk_i   = 0;
   wr_rst_ni  = 0;
   wr_en_i    = 0;
   push       = 0;
   data_i     = 0;
   rd_clk_i   = 0;
   rd_rst_ni  = 0;
   rd_en_i    = 0;
   pop        = 0;
   flush_i    = 0;
   #10
   @ (posedge c_clk); #0.1;
   wr_rst_ni  = 1;
   rd_rst_ni  = 1;
   
   @ (posedge c_clk); #0.1;
   wr_en_i    = 1;
   rd_en_i    = 1;

   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 1;
   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 2;
   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 3;
   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 4;
   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 5;
   @ (posedge c_clk); #0.1;
   if (!full_o) push = 1; else push = 0;
   data_i     = 6;
   @ (posedge c_clk); #0.1;
   push       = 0;
   data_i     = 0;

   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;
   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;

   @ (posedge c_clk); #0.1;
   flush_i    = 1;
   @ (posedge c_clk); #0.1;
   flush_i    = 0;

   @ (posedge c_clk); #0.1;
   @ (posedge c_clk); #0.1;


   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;
   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;
   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;
   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;
   @ (posedge t_clk); #0.1;
   if (!empty_o) pop = 1; else pop = 0;


   PUSH(1);
   PUSH(2);
   PUSH(3);
   PUSH(4);
   POP();
   POP();
   POP();
   POP();

end

task PUSH (input integer DATA);
begin
   $display("Push to FIFO");
   wait (!full_o);
   @ (posedge c_clk); #0.1;
   data_i     = DATA;
   push       = 1;
   @ (posedge c_clk); #0.1;
   data_i     = 0;
   push       = 0;
   end
endtask

task POP();
begin
   $display("POP from FIFO");
   wait (!empty_o);
   @ (posedge t_clk); #0.1;
   pop       = 1;
   @ (posedge t_clk); #0.1;
   data_i     = 0;
   pop       = 0;
   end
endtask



endmodule




