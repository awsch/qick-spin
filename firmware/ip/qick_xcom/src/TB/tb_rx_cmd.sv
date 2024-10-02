///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : mdife
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

`define T_C_CLK         2.5 // 1.66 // Half Clock Period for Simulation
`define T_X_CLK         1 // 1.66 // Half Clock Period for Simulation
`define CH              4 // Number of Channels

module tb_rx_cmd();

///////////////////////////////////////////////////////////////////////////////

// Signals
reg c_clk, x_clk;
reg rst_ni;
reg[31:0]       data_wr     = 32'h12345678;

//////////////////////////////////////////////////////////////////////////
//  CLK Generation
initial begin
   c_clk = 1'b0;
   forever # (`T_C_CLK) c_clk = ~c_clk;
end
initial begin
  x_clk = 1'b0;
  forever # (`T_X_CLK) x_clk = ~x_clk;
end

reg   [ 3:0]   xcom_id_i, tick_cfg_i    ;
wire            rx_vld_o     ;
wire   [ 3:0]   rx_cmd_o  ;
wire   [31:0]   rx_data_o    ;
wire   [31:0]   xcom_link_do ;



reg            tx_vld_i    [`CH];
reg   [ 7:0]   tx_header_i [`CH];
reg   [31:0]   tx_data_i   [`CH];
wire            tx_rdy_o   [`CH];
wire    [`CH-1:0]  tx_dt_o           ;
wire    [`CH-1:0]  tx_ck_o           ;

reg   [ 7:0]   tx_header_s ;
reg   [31:0]   tx_data_s   ;
wire  [ 3:0]   cmd_op_o, cmd_id_o;
wire  [31:0]   cmd_op_o;

rx_cmd # (
   .CH ( `CH )
) RX_CMD ( 
   .c_clk_i      ( c_clk      ),
   .c_rst_ni     ( rst_ni     ),
   .x_clk_i      ( x_clk      ),
   .x_rst_ni     ( rst_ni     ),
   .xcom_id_i    ( xcom_id_i    ),
   .rx_dt_i      ( tx_dt_o      ),
   .rx_ck_i      ( tx_ck_o      ),
   .cmd_op_o     ( cmd_op_o     ),
   .cmd_dt_o     ( cmd_dt_o     ),
   .cmd_id_o     ( cmd_id_o    ),
   .cmd_vld_o    ( cmd_vld_o     )
   );
   
   
genvar ind_tx;
generate
   for (ind_tx=0; ind_tx < `CH ; ind_tx=ind_tx+1) begin: TX
 // TX
        xcom_link_tx LINK (
           .x_clk_i       ( x_clk     ),
           .x_rst_ni      ( rst_ni    ),
           .tick_cfg_i    ( tick_cfg_i  ),
           .tx_vld_i      ( tx_vld_i   [ind_tx] ),
           .tx_rdy_o      ( tx_rdy_o   [ind_tx] ),
           .tx_header_i   ( tx_header_i[ind_tx] ),
           .tx_data_i     ( tx_data_i  [ind_tx] ),
           .tx_dt_o       ( tx_dt_o    [ind_tx] ),
           .tx_ck_o       ( tx_ck_o    [ind_tx] )
           );
  end
endgenerate



 
 

	
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
   tick_cfg_i  = 0;
   xcom_id_i   = 0;
   tx_vld_i    = '{default:'0};
   tx_header_i = '{default:'0};
   tx_data_i   = '{default:'0};
   #25;
   @ (posedge x_clk); #0.1;
   rst_ni            = 1'b1;
end
endtask

integer ind_ch;
task SIM_TX (); begin
   tick_cfg_i  = 2;
   $display("SIM TX");
   @ (posedge x_clk); #0.1;
   
   #500;
   tx_header_s = 8'b0110_0010;
   tx_data_s   = 32'd8;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b0000_0010;
   tx_data_s   = 32'd8;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b1001_0010;
   tx_data_s   = 32'd8;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b0010_0010;
   tx_data_s   = 32'd16;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b0101_0010;
   tx_data_s   = 32'd24;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b0110_0010;
   tx_data_s   = 32'd40;
   #100;
   TX_ALL();

   #500;
   tx_header_s = 8'b1000_0000;
   tx_data_s   = 32'd1;
   #100;
   TX_ALL();
   #1000;

end
endtask

task TX_ALL ; begin
   $display("TX_ALL");
   for (ind_ch=0; ind_ch < `CH ; ind_ch=ind_ch+1) begin: STX
      tx_header_i[ind_ch] = tx_header_s;
      tx_data_i[ind_ch]   = tx_data_s+ind_ch;
      TX_DT(ind_ch);
   end
   #500;
end
endtask



task TX_DT (input int channel); begin
   $display("TX_DT %d", channel);
   wait (tx_rdy_o[channel] == 1'b1);
   @ (posedge x_clk); #0.1;
   tx_vld_i[channel]    = 1;
   wait (tx_rdy_o[channel] == 1'b0);
   @ (posedge x_clk); #0.1;
   tx_vld_i[channel]    = 0;
end
endtask

endmodule




