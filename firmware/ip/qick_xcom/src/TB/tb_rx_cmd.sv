///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

`define T_X_CLK         1 // 1.66 // Half Clock Period for Simulation

module tb_rx_cmd();

///////////////////////////////////////////////////////////////////////////////

// Signals
reg x_clk;
reg rst_ni;
reg[31:0]       data_wr     = 32'h12345678;

//////////////////////////////////////////////////////////////////////////
//  CLK Generation
initial begin
  x_clk = 1'b0;
  forever # (`T_X_CLK) x_clk = ~x_clk;
end

reg   [ 3:0]   xcom_id_i, tick_cfg_i    ;
reg            tx_vld_i      ;
reg   [ 7:0]   tx_header_i   ;
reg   [31:0]   tx_data_i     ;
reg      rx_dt_i           ;
reg      rx_ck_i            ;
wire            tx_rdy_o   ;
wire            rx_vld_o     ;
wire   [ 3:0]   rx_cmd_o  ;
wire   [31:0]   rx_data_o    ;
wire      tx_dt_o           ;
wire      tx_ck_o           ;
wire   [31:0]   xcom_link_do ;

assign   rx_dt_i = tx_dt_o ;
assign   rx_ck_i = tx_ck_o ;


// RX
xcom_link_rx RX (
   .x_clk_i     ( x_clk   ),
   .x_rst_ni    ( rst_ni  ),
   .xcom_id_i   ( xcom_id_i),
   .rx_vld_o    ( rx_vld_o  ),
   .rx_cmd_o    ( rx_cmd_o  ),
   .rx_data_o   ( rx_data_o ),
   .rx_dt_i     ( rx_dt_i   ),
   .rx_ck_i     ( rx_ck_i   ),
   .rx_do       (      ) 
   );


// TX
xcom_link_tx TX (
   .x_clk_i       ( x_clk     ),
   .x_rst_ni      ( rst_ni    ),
   .tick_cfg_i    ( tick_cfg_i  ),
   .tx_vld_i      ( tx_vld_i    ),
   .tx_rdy_o      ( tx_rdy_o    ),
   .tx_header_i   ( tx_header_i ),
   .tx_data_i     ( tx_data_i   ),
   .tx_dt_o       ( tx_dt_o     ),
   .tx_ck_o       ( tx_ck_o     ),
   .tx_do         (        )
   );


 
 

	
initial begin
   START_SIMULATION();
   xcom_id_i = 4'b0001;
   SIM_TX();
   xcom_id_i = 4'b0010;
   SIM_TX();
   xcom_id_i = 4'b1010;
   SIM_TX();
   
   
end

task START_SIMULATION (); begin
   $display("START SIMULATION");
   rst_ni   = 1'b0;
   tick_cfg_i  = 2;
   xcom_id_i   = 0;
   tx_vld_i    = 0;
   tx_header_i = 0;
   tx_data_i   = 0;
   rx_dt_i     = 0;
   rx_ck_i     = 0;
   #25;
   @ (posedge x_clk); #0.1;
   rst_ni            = 1'b1;
end
endtask

task SIM_TX (); begin
   $display("SIM TX");
   @ (posedge x_clk); #0.1;
   tx_header_i = 8'b1001_1010;
   tx_data_i   = 32'd8;
   #100;
   TX_DT();
   
   #500;
   tx_header_i = 8'b1010_1010;
   tx_data_i   = 32'd16;
   #100;
   TX_DT();

   #500;
   tx_header_i = 8'b1100_1010;
   tx_data_i   = 32'd24;
   #100;
   TX_DT();

   #500;
   tx_header_i = 8'b1110_1010;
   tx_data_i   = 32'd40;
   #100;
   TX_DT();

   #500;
   tx_header_i = 8'b1000_0000;
   tx_data_i   = 32'd40;
   #100;
   TX_DT();
   #1000;

end
endtask

task TX_DT (); begin
   $display("TX_DT");
   tick_cfg_i  = 2;
   wait (tx_rdy_o == 1'b1);
   @ (posedge x_clk); #0.1;
   tx_vld_i    = 1;
   wait (tx_rdy_o == 1'b0);
   @ (posedge x_clk); #0.1;
   tx_vld_i    = 0;
end
endtask

endmodule




