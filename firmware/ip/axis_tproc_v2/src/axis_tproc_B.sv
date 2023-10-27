`include "proc_defines.svh"

module axis_tproc_B # (
   parameter LFSR           =  1 ,
   parameter DIVIDER        =  1 ,
   parameter ARITH          =  1 ,
   parameter TIME_CMP       =  1 ,
   parameter TIME_READ      =  1 ,
   parameter PMEM_AW        =  12 ,
   parameter DMEM_AW        =  10 ,
   parameter WMEM_AW        =  8 ,
   parameter REG_AW         =  4 ,
   parameter IN_PORT_QTY    =  2 ,
   parameter OUT_DPORT_QTY  =  1 ,
   parameter OUT_WPORT_QTY  =  4 
)(
// Core, Time and AXI CLK & RST.
   input  wire                t_clk_i              ,
   input  wire                t_aresetn            ,
   input  wire                c_clk_i              ,
   input  wire                c_aresetn            ,
   input  wire                s_ps_dma_aclk        ,
   input  wire                s_ps_dma_aresetn     ,
// External Control
   input  wire                start_i            ,
// Debug Signals
   output wire [31:0]        debug_do              ,
   output wire [31:0]        t_time_abs_do         ,
   output wire [31:0]        t_fifo_do             ,
   output wire [31:0]        t_debug_do            ,
   output wire [31:0]        c_time_usr_do         ,
   output wire [31:0]        c_time_ref_do         ,
   output wire [31:0]        c_port_do             ,
   output wire [31:0]        c_core_do             ,
// DMA AXIS FOR READ AND WRITE MEMORY             
   input  wire [255 :0]       s_dma_axis_tdata_i   ,
   input  wire                s_dma_axis_tlast_i   ,
   input  wire                s_dma_axis_tvalid_i  ,
   output wire                s_dma_axis_tready_o  ,
   output wire [255 :0]       m_dma_axis_tdata_o   ,
   output wire                m_dma_axis_tlast_o   ,
   output wire                m_dma_axis_tvalid_o  ,
   input  wire                m_dma_axis_tready_i  ,
// AXI-Lite DATA Slave I/F.   
   input  wire [5:0]          s_axi_awaddr         ,
   input  wire [2:0]          s_axi_awprot         ,
   input  wire                s_axi_awvalid        ,
   output wire                s_axi_awready        ,
   input  wire [31:0]         s_axi_wdata          ,
   input  wire [3:0]          s_axi_wstrb          ,
   input  wire                s_axi_wvalid         ,
   output wire                s_axi_wready         ,
   output wire  [1:0]         s_axi_bresp          ,
   output wire                s_axi_bvalid         ,
   input  wire                s_axi_bready         ,
   input  wire [5:0]          s_axi_araddr         ,
   input  wire [2:0]          s_axi_arprot         ,
   input  wire                s_axi_arvalid        ,
   output wire                s_axi_arready        ,
   output wire  [31:0]        s_axi_rdata          ,
   output wire  [1:0]         s_axi_rresp          ,
   output wire                s_axi_rvalid         ,
   input  wire                s_axi_rready         ,
/// DATA PORT INPUT
   input wire [63:0]         s0_axis_tdata         ,
   input wire                s0_axis_tvalid        ,
   input wire [63:0]         s1_axis_tdata         ,
   input wire                s1_axis_tvalid        ,
   input wire [63:0]         s2_axis_tdata         ,
   input wire                s2_axis_tvalid        ,
   input wire [63:0]         s3_axis_tdata         ,
   input wire                s3_axis_tvalid        ,
   input wire [63:0]         s4_axis_tdata         ,
   input wire                s4_axis_tvalid        ,
   input wire [63:0]         s5_axis_tdata         ,
   input wire                s5_axis_tvalid        ,
   input wire [63:0]         s6_axis_tdata         ,
   input wire                s6_axis_tvalid        ,
   input wire [63:0]         s7_axis_tdata         ,
   input wire                s7_axis_tvalid        ,
// OUT WAVE PORTS
   // AXI Stream Master  0 ///
   output wire [167:0]        m0_axis_tdata        ,
   output wire                m0_axis_tvalid       ,
   input  wire                m0_axis_tready       ,
   // AXI Stream Master  1 ///
   output wire [167:0]        m1_axis_tdata        ,
   output wire                m1_axis_tvalid       ,
   input  wire                m1_axis_tready       ,
   // AXI Stream Master  2 ///
   output wire [167:0]        m2_axis_tdata        ,
   output wire                m2_axis_tvalid       ,
   input  wire                m2_axis_tready       ,
   // AXI Stream Master  3 ///
   output wire [167:0]        m3_axis_tdata        ,
   output wire                m3_axis_tvalid       ,
   input  wire                m3_axis_tready       ,
   // AXI Stream Master  4 ///
   output wire [167:0]        m4_axis_tdata        ,
   output wire                m4_axis_tvalid       ,
   input  wire                m4_axis_tready       ,
   // AXI Stream Master  5 ///
   output wire [167:0]        m5_axis_tdata        ,
   output wire                m5_axis_tvalid       ,
   input  wire                m5_axis_tready       ,
   // AXI Stream Master  6 ///
   output wire [167:0]        m6_axis_tdata        ,
   output wire                m6_axis_tvalid       ,
   input  wire                m6_axis_tready       ,
   // AXI Stream Master  7 ///
   output wire [167:0]        m7_axis_tdata        ,
   output wire                m7_axis_tvalid       ,
   input  wire                m7_axis_tready       ,
// OUT DATA PORTS
   output reg [31:0]          port_0_dt_o          ,
   output reg [31:0]          port_1_dt_o          ,
   output reg [31:0]          port_2_dt_o          ,
   output reg [31:0]          port_3_dt_o          );

wire [ 31 : 0 ] TPROC_CTRL      ;
wire [ 31 : 0 ] TPROC_CFG       ;
wire [ 15 : 0 ] MEM_ADDR        ;
wire [ 15 : 0 ] MEM_LEN         ;
wire [ 31 : 0 ] MEM_DT_I        ;
wire [ 31 : 0 ] MEM_DT_O        ;
wire [ 31 : 0 ] TPROC_EXT_DT1_I, TPROC_EXT_DT2_I  ;
wire [ 31 : 0 ] TPROC_EXT_DT1_O, TPROC_EXT_DT2_O  ;
wire [ 31 : 0 ] TPROC_STATUS    ;
wire [ 31 : 0 ] TPROC_DEBUG     ;
wire [ 31 : 0 ] PORT_LSB        ;
wire [ 31 : 0 ] PORT_HSB        ;
wire [ 31 : 0 ] RAND            ;
wire [ 31 : 0 ] TIME_USR, TIME_USR_PS        ;


// AXI Slave.
axi_slv_tproc axi_slv_inst (
   .aclk        ( s_ps_dma_aclk           ) , 
   .aresetn     ( s_ps_dma_aresetn        ) , 
   // Write Address Channel.
   .awaddr           ( s_axi_awaddr [5:0] ) , 
   .awprot           ( s_axi_awprot       ) , 
   .awvalid          ( s_axi_awvalid      ) , 
   .awready          ( s_axi_awready      ) , 
   // Write Data Channel.
   .wdata            ( s_axi_wdata        ) , 
   .wstrb            ( s_axi_wstrb        ) , 
   .wvalid           ( s_axi_wvalid       ) , 
   .wready           ( s_axi_wready       ) , 
   // Write Response Channel.
   .bresp            ( s_axi_bresp        ) , 
   .bvalid           ( s_axi_bvalid       ) , 
   .bready           ( s_axi_bready       ) , 
   // Read Address Channel.
   .araddr           ( s_axi_araddr       ) , 
   .arprot           ( s_axi_arprot       ) , 
   .arvalid          ( s_axi_arvalid      ) , 
   .arready          ( s_axi_arready      ) , 
   // Read Data Channel.
   .rdata            ( s_axi_rdata        ) , 
   .rresp            ( s_axi_rresp        ) , 
   .rvalid           ( s_axi_rvalid       ) , 
   .rready           ( s_axi_rready       ) , 
   // Registers.
   .rst_t_ctrl_i     ( |TPROC_CTRL        ) ,
   .TPROC_CTRL       ( TPROC_CTRL         ) ,
   .RAND             ( RAND               ) ,
   .TPROC_CFG        ( TPROC_CFG          ) ,
   .MEM_ADDR         ( MEM_ADDR           ) ,
   .MEM_LEN          ( MEM_LEN            ) ,
   .MEM_DT_I         ( MEM_DT_I           ) ,
   .TPROC_EXT_DT1_I  ( TPROC_EXT_DT1_I    ) ,
   .TPROC_EXT_DT2_I  ( TPROC_EXT_DT2_I    ) ,
   .PORT_LSB         ( PORT_LSB           ) ,
   .PORT_HSB         ( PORT_HSB           ) ,
   .TIME_USR         ( TIME_USR_PS        ) ,
   .TPROC_EXT_DT1_O  ( TPROC_EXT_DT1_O    ) ,
   .TPROC_EXT_DT2_O  ( TPROC_EXT_DT2_O    ) ,
   .MEM_DT_O         ( MEM_DT_O           ) ,
   .TPROC_STATUS     ( TPROC_STATUS       ) ,
   .TPROC_DEBUG      ( TPROC_DEBUG        ) );


sync_reg sync_time_ps (
   .dt_i      ( TIME_USR         ) ,
   .clk_i     ( s_ps_dma_aclk    ) ,
   .rst_ni    ( s_ps_dma_aresetn ) ,
   .dt_o      ( TIME_USR_PS      ) );

assign port_dt_new = s0_axis_tvalid|s1_axis_tvalid|s2_axis_tvalid|s3_axis_tvalid|s4_axis_tvalid|s5_axis_tvalid|s6_axis_tvalid|s7_axis_tvalid ;
//assign port_dt_new = s8_axis_tvalid|s9_axis_tvalid|s10_axis_tvalid|s11_axis_tvalid|s12_axis_tvalid|s13_axis_tvalid|s14_axis_tvalid|s15_axis_tvalid ;

reg [63:0] port_dt_r [8];
always_ff @(posedge c_clk_i)
   if (!c_aresetn)
      port_dt_r <= '{default:'0} ;
   else begin 
      if (s0_axis_tvalid) port_dt_r[0] <= s0_axis_tdata ;
      if (s1_axis_tvalid) port_dt_r[1] <= s1_axis_tdata ;
      if (s2_axis_tvalid) port_dt_r[2] <= s2_axis_tdata ;
      if (s3_axis_tvalid) port_dt_r[3] <= s3_axis_tdata ;
      if (s4_axis_tvalid) port_dt_r[4] <= s4_axis_tdata ;
      if (s5_axis_tvalid) port_dt_r[5] <= s5_axis_tdata ;
      if (s6_axis_tvalid) port_dt_r[6] <= s6_axis_tdata ;
      if (s7_axis_tvalid) port_dt_r[7] <= s7_axis_tdata ;
   end
        

wire [167:0]         m_axis_tdata_s [8] ;
wire                 m_axis_tvalid_s[8] ; 
wire                 m_axis_tready_s[8] ;

wire [31:0]          port_dt_so     [OUT_DPORT_QTY] ;
wire [167:0]         axis_core      [OUT_WPORT_QTY] ;
wire [31:0]          ext_op_r, ext_dt_r, ext_dt_i   ;
wire [PMEM_AW-1:0]   pmem_addr_s   ;
wire                 pmem_en_s     ;
wire [71:0]          pmem_dt_s     ;
wire                 dmem_we_s     ;
wire [DMEM_AW-1:0]   dmem_addr_s   ;
wire [31:0]          dmem_w_dt_s   ;
wire [31:0]          dmem_r_dt_s   ;
wire                 wmem_we_s     ;
wire [WMEM_AW-1:0]   wmem_addr_s   ;
wire [167:0]         wmem_w_dt_s   ;
wire [167:0]         wmem_r_dt_s   ;

t_proc_B # (
   .LFSR         ( LFSR       ),
   .DIVIDER         ( DIVIDER       ),
   .ARITH         ( ARITH       ),
   .TIME_CMP         ( TIME_CMP       ),
   .TIME_READ         ( TIME_READ       ),
   .PMEM_AW         ( PMEM_AW       ),
   .DMEM_AW         ( DMEM_AW       ),
   .WMEM_AW         ( WMEM_AW       ),
   .REG_AW          ( REG_AW        ),
   .IN_PORT_QTY     ( IN_PORT_QTY   ),
   .OUT_DPORT_QTY   ( OUT_DPORT_QTY ),
   .OUT_WPORT_QTY   ( OUT_WPORT_QTY )
) T_PROC (
   .t_clk_i        ( t_clk_i           ) ,
   .t_rst_ni       ( t_aresetn         ) ,
   .c_clk_i        ( c_clk_i           ) ,
   .c_rst_ni       ( c_aresetn         ) ,
   .start_i        ( start_i           ) ,
   .TPROC_CTRL     ( TPROC_CTRL        ) ,
   .TPROC_CFG      ( TPROC_CFG[31:8]   ) ,
   .ext_dt_i       ( '{TPROC_EXT_DT1_I, TPROC_EXT_DT2_I}  ) ,
   .ext_dt_o       ( '{TPROC_EXT_DT1_O, TPROC_EXT_DT2_O}  ) ,
   .rand_o         ( RAND              ) ,
   .time_usr_o     ( TIME_USR          ) ,
   .pmem_addr_o    ( pmem_addr_s       ) ,
   .pmem_en_o      ( pmem_en_s         ) ,
   .pmem_dt_i      ( pmem_dt_s         ) ,
   .dmem_we_o      ( dmem_we_s         ) ,
   .dmem_addr_o    ( dmem_addr_s       ) ,
   .dmem_w_dt_o    ( dmem_w_dt_s       ) ,
   .dmem_r_dt_i    ( dmem_r_dt_s       ) ,
   .wmem_we_o      ( wmem_we_s         ) ,
   .wmem_addr_o    ( wmem_addr_s       ) ,
   .wmem_w_dt_o    ( wmem_w_dt_s       ) ,
   .wmem_r_dt_i    ( wmem_r_dt_s       ) ,
   .port_dt_new_i  ( port_dt_new       ) ,
   .port_dt_i      ( port_dt_r [0:IN_PORT_QTY-1]    ) ,
   .port_dt_o      ( port_dt_so[0:OUT_DPORT_QTY-1]  ) ,
   .m_axis_tdata   ( axis_core         ) ,
   .m_axis_tvalid  ( m_axis_tvalid_s [0:OUT_WPORT_QTY-1]  ) ,
   .m_axis_tready  ( m_axis_tready_s [0:OUT_WPORT_QTY-1]  ) ,
   .TPROC_STATUS   ( TPROC_STATUS[23:0]) ,
   .DEBUG_O        ( TPROC_DEBUG[15:0] ) ,
   .t_time_abs_do  ( t_time_abs_do     ) ,
   .t_fifo_do      ( t_fifo_do         ) ,
   .t_debug_do     ( t_debug_do        ) ,
   .c_time_ref_do  ( c_time_ref_do     ) ,
   .c_port_do      ( c_port_do         ) ,
   .c_core_do      ( c_core_do         ) );

t_mem_B # (
   .PMEM_AW ( PMEM_AW ),
   .DMEM_AW ( DMEM_AW ),
   .WMEM_AW ( WMEM_AW )
) T_MEM (
   .f_aclk           ( c_clk_i               ) ,
   .f_aresetn        ( c_aresetn             ) ,
   .pmem_addr_i      ( pmem_addr_s           ) ,
   .pmem_en_i        ( pmem_en_s             ) ,
   .pmem_dt_o        ( pmem_dt_s             ) ,
   .dmem_we_i        ( dmem_we_s             ) ,
   .dmem_addr_i      ( dmem_addr_s           ) ,
   .dmem_w_dt_i      ( dmem_w_dt_s           ) ,
   .dmem_r_dt_o      ( dmem_r_dt_s           ) ,
   .wmem_we_i        ( wmem_we_s             ) ,
   .wmem_addr_i      ( wmem_addr_s           ) ,
   .wmem_w_dt_i      ( wmem_w_dt_s           ) ,
   .wmem_r_dt_o      ( wmem_r_dt_s           ) ,
   .busy_o           ( busy_o                ) ,
   .end_single_o     ( end_single_o          ) ,
   .s_ps_dma_aclk    ( s_ps_dma_aclk         ) ,
   .s_ps_dma_aresetn ( s_ps_dma_aresetn      ) ,
   .s_axis_tdata_i   ( s_dma_axis_tdata_i    ) ,
   .s_axis_tlast_i   ( s_dma_axis_tlast_i    ) ,
   .s_axis_tvalid_i  ( s_dma_axis_tvalid_i   ) ,
   .s_axis_tready_o  ( s_dma_axis_tready_o   ) ,
   .m_axis_tdata_o   ( m_dma_axis_tdata_o    ) ,
   .m_axis_tlast_o   ( m_dma_axis_tlast_o    ) ,
   .m_axis_tvalid_o  ( m_dma_axis_tvalid_o   ) ,
   .m_axis_tready_i  ( m_dma_axis_tready_i   ) ,
   .MEM_CTRL         ( TPROC_CFG[7:0]        ) ,
   .MEM_ADDR         ( MEM_ADDR              ) ,
   .MEM_LEN          ( MEM_LEN               ) ,
   .MEM_DT_I         ( MEM_DT_I              ) ,
   .MEM_DT_O         ( MEM_DT_O              ) ,
   .STATUS_O         ( TPROC_STATUS[31:24]   ) ,
   .DEBUG_O          ( TPROC_DEBUG[31:16]    ) );


// OUTPUT ASSIGNMENT
assign port_0_dt_o = port_dt_so[0] ;
assign port_1_dt_o = port_dt_so[1] ;
assign port_2_dt_o = port_dt_so[2] ;
assign port_3_dt_o = port_dt_so[3] ;


// Convert to Signal Generator V6 //OUT OF DATE
genvar ind;
generate
    // Assign OUTS
   for (ind=0; ind < OUT_WPORT_QTY; ind=ind+1) begin: WAVE_PORT_PRESENT
      //assign m_axis_tdata_s[ind] = { axis_core[ind][127:96], 16'd0,axis_core[ind][95:80], 16'd0, axis_core[ind][79:0] } ;
      assign m_axis_tdata_s[ind] = axis_core[ind] ;
   end
    // Assign ZEROS
   //for (ind=OUT_WPORT_QTY; ind < 7; ind=ind+1) begin: WAVE_PORT_NOT_PRESENT
   if (OUT_WPORT_QTY < 8)
      for (ind=7; ind < OUT_WPORT_QTY; ind=ind-1) begin: WAVE_PORT_NOT_PRESENT
         assign m_axis_tdata_s[ind]  = '{default:'0} ;
         assign m_axis_tvalid_s[ind] = 0 ;
      end
endgenerate
      // WaveForm FIFO
      

assign m0_axis_tdata      = m_axis_tdata_s [0]  ;
assign m0_axis_tvalid     = m_axis_tvalid_s[0]  ;
assign m_axis_tready_s[0] = m0_axis_tready      ;
assign m1_axis_tdata      = m_axis_tdata_s [1]  ;
assign m1_axis_tvalid     = m_axis_tvalid_s[1]  ;
assign m_axis_tready_s[1] = m1_axis_tready      ;
assign m2_axis_tdata      = m_axis_tdata_s [2]  ;
assign m2_axis_tvalid     = m_axis_tvalid_s[2]  ;
assign m_axis_tready_s[2] = m2_axis_tready      ;
assign m3_axis_tdata      = m_axis_tdata_s [3]  ;
assign m3_axis_tvalid     = m_axis_tvalid_s[3]  ;
assign m_axis_tready_s[3] = m3_axis_tready      ;
assign m4_axis_tdata      = m_axis_tdata_s [4]  ;
assign m4_axis_tvalid     = m_axis_tvalid_s[4]  ;
assign m_axis_tready_s[4] = m3_axis_tready      ;
assign m5_axis_tdata      = m_axis_tdata_s [5]  ;
assign m5_axis_tvalid     = m_axis_tvalid_s[5]  ;
assign m_axis_tready_s[5] = m3_axis_tready      ;
assign m6_axis_tdata      = m_axis_tdata_s [6]  ;
assign m6_axis_tvalid     = m_axis_tvalid_s[6]  ;
assign m_axis_tready_s[6] = m3_axis_tready      ;
assign m7_axis_tdata      = m_axis_tdata_s [7]  ;
assign m7_axis_tvalid     = m_axis_tvalid_s[7]  ;
assign m_axis_tready_s[7] = m3_axis_tready      ;


assign debug_do = TPROC_DEBUG;
assign c_time_usr_do  = TIME_USR;

endmodule



  
  