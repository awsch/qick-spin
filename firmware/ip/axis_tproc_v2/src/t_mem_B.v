// Assembled memory access module. Three modes of accessing the memory:
//
// * Single access using the in/out ports. It's only available when busy_o = 0.
//
// * AXIS read: this mode allows to send data using m_axis_* interface, using
// ADDR_REG as the starting address and LEN_REG to indicate the number of
// samples to be transferred. The last sample will assert m_axis_tlast_o to
// indicate the external block transaction is done. Similar to AXIS write
// mode, the user needs to set START_REG = 1 to start the process.
//
// * AXIS write: this mode receives data from s_axis_* interface and writes
// into the memory using ADDR_REG as the starting address. The user must also
// provide the START_REG = 1 to allow starting receiving data. The block will
// rely on s_axis_tlast_i = 1 to finish the writing process.
//
// When not performing any AXIS transaction, the block will grant access to
// the memory using the single access interface. This is a very basic
// handshake interface to allow external blocks to easily communicate and
// perform single-access transaction. 
//
// Once a AXIS transaction is done, the user must set START_REG = 0 and back
// to 1 if a new AXIS transaction needs to be executed. START_REG = 1 steady
// will not allow further AXIS transactions, and will only allow
// single-access.
//
// Registers:
//
// MODE_REG : indicates the type of the next AXIS transaction.
// * 0 : AXIS Read (from memory to m_axis).
// * 1 : AXIS Write (from s_axis to memory).
//
// START_REG : starts execution of indicated AXIS transaction.
// * 0 : Stop.
// * 1 : Execute Operation.
//
// ADDR_REG : starting memory address for either AXIS read or write.
//
// LEN_REG : number of samples to be transferred in AXIS read mode.
//

module t_mem_B # (
   parameter PMEM_AW = 16 ,
   parameter DMEM_AW = 16 ,
   parameter WMEM_AW = 16 
)(
   // CLK & RST.
   input  wire                f_aclk            ,
   input  wire                f_aresetn         ,
   input  wire                s_ps_dma_aclk     ,
   input  wire                s_ps_dma_aresetn  ,
// PROGRAM MEMORY
   input  wire [PMEM_AW-1:0]  pmem_addr_i    ,
   input  wire                pmem_en_i      ,
   output wire [71:0]         pmem_dt_o      ,
// DATA MEMORY
   input  wire                dmem_we_i      ,
   input  wire [DMEM_AW-1:0]  dmem_addr_i    ,
   input  wire [31:0]         dmem_w_dt_i    ,
   output wire [31:0]         dmem_r_dt_o    ,
// WAVE MEMORY
   input  wire                wmem_we_i      ,
   input  wire [WMEM_AW-1:0]  wmem_addr_i  ,
   input  wire [167:0]        wmem_w_dt_i    ,
   output wire [167:0]        wmem_r_dt_o    ,
   output wire                busy_o         ,
   output wire                end_single_o   ,
// AXIS Slave
   input  wire [255:0]        s_axis_tdata_i ,
   input  wire                s_axis_tlast_i ,
   input  wire                s_axis_tvalid_i,
   output wire                s_axis_tready_o,
// AXIS Master for sending data.
   output wire [255:0]        m_axis_tdata_o ,
   output wire                m_axis_tlast_o ,
   output wire                m_axis_tvalid_o,
   input  wire                m_axis_tready_i,
//Control Regiters
   input  wire [ 7:0 ]        MEM_CTRL       ,
   input  wire [15:0]       MEM_ADDR       ,
   input  wire [15:0]       MEM_LEN        ,
   input  wire [31:0]       MEM_DT_I       ,
   output wire [31:0]       MEM_DT_O       ,
   output wire [7:0]          STATUS_O       ,
   output wire [15:0]         DEBUG_O        );

// SIGNALS
wire                 ar_exec     ;
wire                 ar_exec_ack ;
wire                 aw_exec     ;
wire                 aw_end      ;
// Memory AXIS Read.
wire  [15:0]   mem_addr_aread;
// Memory AXIS Write.
wire  [15:0]   mem_di_awrite;
wire  [15:0]   mem_addr_awrite;

wire                 mem_we_single, mem_we_axis;

wire mem_start, mem_op ;
wire [1:0] mem_sel ;


assign mem_start   = MEM_CTRL[ 0 ] ; // 1-Start Go to 0 For Next
assign mem_op      = MEM_CTRL[ 1 ] ; // 0-READ , 1-WRITE
assign mem_sel     = MEM_CTRL[3:2] ; // 01-Pmem , 10-Dmem , 11-Wmem
assign mem_source  = MEM_CTRL[ 4 ] ; // 0-AXIS, 1-REGISTERS (Single)

assign start_axis   = mem_start & ~mem_source ;
assign start_single = mem_start & mem_source ;

wire [31:0] mem_w_dt_single;
wire [15:0] axis_addr, mem_w_addr_axis, mem_r_addr_axis, mem_addr_single, ext_mem_addr;


data_mem_ctrl #(
      .N(16)
   ) data_mem_ctrl_i (
      .aclk_i        ( s_ps_dma_aclk      ) ,
      .aresetn_i     ( s_ps_dma_aresetn   ) ,
      .ar_exec_o     ( ar_exec            ) ,  
      .ar_exec_ack_i ( ar_end             ) ,
      .aw_exec_o     ( aw_exec            ) ,  
      .aw_exec_ack_i ( aw_end             ) ,
      .busy_o        ( busy_o             ) ,
      .mem_op_i      ( mem_op             ) ,
      .mem_start_i   ( mem_start          ) );

mem_rw  #(
   .N( 16 ),
   .B( 32 )
) mem_rw_i (
   .aclk_i           ( s_ps_dma_aclk      ) ,
   .aresetn_i        ( s_ps_dma_aresetn   ) ,
   .rw_i             ( mem_op             ) ,
   .exec_i           ( start_single       ) ,
   .exec_ack_o       ( end_single_o       ) ,
   .addr_i           ( MEM_ADDR           ) ,
   .di_i             ( MEM_DT_I           ) ,
   .do_o             ( MEM_DT_O           ) ,
   .mem_we_o         ( mem_we_single      ) ,
   .mem_di_o         ( mem_w_dt_single    ) ,
   .mem_do_i         ( mem_r_dt[31:0]     ) ,
   .mem_addr_o       ( mem_addr_single    )	);
   

// Memory Control
assign ext_P_mem_en = (mem_sel== 2'b01) ;
assign ext_D_mem_en = (mem_sel== 2'b10) ;
assign ext_W_mem_en = (mem_sel== 2'b11) ;

assign ext_P_mem_we = ext_P_mem_en & (mem_we_single | mem_we_axis) ;
assign ext_D_mem_we = ext_D_mem_en & (mem_we_single | mem_we_axis) ;
assign ext_W_mem_we = ext_W_mem_en & (mem_we_single | mem_we_axis) ;

assign axis_addr    = mem_op     ? mem_w_addr_axis : mem_r_addr_axis  ;
assign ext_mem_addr = mem_source ? mem_addr_single : axis_addr       ;

wire [255:0] mem_w_dt_axis; 

wire [71:0] ext_P_r_dt;
wire [31:0] ext_D_r_dt;
wire [167:0] wdt;
wire [255:0] ext_W_r_dt;


wire [255:0]   mem_r_dt;
assign mem_r_dt  =   (mem_sel == 2'b01)? ext_P_r_dt  : 
                     (mem_sel == 2'b10)? ext_D_r_dt	 :
                     (mem_sel == 2'b11)? ext_W_r_dt	 :
                     0;

wire [71:0] ext_pmem_w_dt;
assign ext_pmem_w_dt   = mem_w_dt_axis[ 71 :  0];

wire [31:0]  ext_dmem_w_dt;
assign ext_dmem_w_dt = mem_source ? mem_w_dt_single   : mem_w_dt_axis[31:0]   ;

wire [167:0] ext_wmem_w_dt;

wire [31 :0] freq, phase, env, gain, lenght, conf;
assign freq   = mem_w_dt_axis[ 31 :  0] ; // 32-bit FREQ
assign phase  = mem_w_dt_axis[ 63 : 32] ; // 32-bit PHASE
assign env    = mem_w_dt_axis[ 95 : 64] ; // 32-bit ENV
assign gain   = mem_w_dt_axis[127 : 96] ; // 32-bit GAIN 
assign lenght = mem_w_dt_axis[159 :128] ; // 32-bit LENGHT
assign conf   = mem_w_dt_axis[191 :160] ; // 32-bit CONF

assign ext_wmem_w_dt   = {conf[15:0], lenght, gain, env[23:0], phase, freq} ;



axis_read #(
   .N( 16 ),
   .B( 256 )
) axis_read_i (
   .aclk_i           ( s_ps_dma_aclk      ) ,
   .aresetn_i        ( s_ps_dma_aresetn   ) ,
   .m_axis_tdata_o   ( m_axis_tdata_o     ) ,
   .m_axis_tlast_o   ( m_axis_tlast_o     ) ,
   .m_axis_tvalid_o  ( m_axis_tvalid_o    ) ,
   .m_axis_tready_i  ( m_axis_tready_i    ) ,
   .mem_do_i         ( mem_r_dt           ) ,
   .mem_addr_o       ( mem_r_addr_axis    ) ,
   .exec_i           ( ar_exec            ) ,
   .exec_ack_o       ( ar_end             ) ,
   .addr_i           ( MEM_ADDR           ) ,
   .len_i            ( MEM_LEN            ) );

axis_write #(
   .N( 16 ),
   .B( 256 )
) axis_write_i (
   .aclk_i           ( s_ps_dma_aclk      ) ,
   .aresetn_i        ( s_ps_dma_aresetn   ) ,
   .s_axis_tdata_i   ( s_axis_tdata_i     ) ,
   .s_axis_tlast_i   ( s_axis_tlast_i     ) ,
   .s_axis_tvalid_i  ( s_axis_tvalid_i    ) ,
   .s_axis_tready_o  ( s_axis_tready_o    ) ,
   .mem_we_o         ( mem_we_axis        ) ,
   .mem_di_o         ( mem_w_dt_axis      ) ,
   .mem_addr_o       ( mem_w_addr_axis    ) ,
   .exec_i           ( aw_exec            ) ,
   .exec_ack_o       ( aw_end             ) ,
   .addr_i           ( MEM_ADDR           ) );

// PROGRAM MEMORY
///////////////////////////////////////////////////////////////////////////////
bram_dual_port_dc # (
   .MEM_AW     ( PMEM_AW ), 
   .MEM_DW     ( 72 ),
   .RAM_OUT    ("NO_REGISTERED" )
) P_MEM ( 
   .clk_a_i  ( f_aclk         ) ,
   .en_a_i   ( pmem_en_i      ) ,
   .we_a_i   ( 1'b0           ) ,
   .addr_a_i ( pmem_addr_i    ) ,
   .dt_a_i   ( 72'd0         ) ,
   .dt_a_o   ( pmem_dt_o      ) ,
   .clk_b_i  ( s_ps_dma_aclk  ) ,
   .en_b_i   ( ext_P_mem_en   ) ,
   .we_b_i   ( ext_P_mem_we   ) ,
   .addr_b_i ( ext_mem_addr[PMEM_AW-1:0]   ) ,
   .dt_b_i   ( ext_pmem_w_dt  ) ,
   .dt_b_o   ( ext_P_r_dt     ) );
   

// DATA MEMORY
///////////////////////////////////////////////////////////////////////////////
bram_dual_port_dc # (
   .MEM_AW     ( DMEM_AW ), 
   .MEM_DW     ( 32 ),
   .RAM_OUT    ("NO_REGISTERED" )
) D_MEM ( 
   .clk_a_i  ( f_aclk         ) ,
   .en_a_i   ( 1'b1           ) ,
   .we_a_i   ( dmem_we_i      ) ,
   .addr_a_i ( dmem_addr_i    ) ,
   .dt_a_i   ( dmem_w_dt_i    ) ,
   .dt_a_o   ( dmem_r_dt_o    ) ,
   .clk_b_i  ( s_ps_dma_aclk  ) ,
   .en_b_i   ( ext_D_mem_en           ) ,
   .we_b_i   ( ext_D_mem_we   ) ,
   .addr_b_i ( ext_mem_addr[DMEM_AW-1:0]   ) ,
   .dt_b_i   ( ext_dmem_w_dt   ) ,
   .dt_b_o   ( ext_D_r_dt  ) );


// WAVE MEMORY 
/////////////////////////////////////////////////

bram_dual_port_dc # (
   .MEM_AW     ( WMEM_AW ), 
   .MEM_DW     ( 168 ),
   .RAM_OUT    ("NO_REGISTERED" )
) W_MEM ( 
   .clk_a_i  ( f_aclk         ) ,
   .en_a_i   ( 1'b1           ) ,
   .we_a_i   ( wmem_we_i      ) ,
   .addr_a_i ( wmem_addr_i    ) , // Change to READ and WRITE in same PIPELINE STAGE
   .dt_a_i   ( wmem_w_dt_i    ) ,
   .dt_a_o   ( wmem_r_dt_o    ) ,
   .clk_b_i  ( s_ps_dma_aclk  ) ,
   .en_b_i   ( ext_W_mem_en   ) ,
   .we_b_i   ( ext_W_mem_we   ) ,
   .addr_b_i ( ext_mem_addr[WMEM_AW-1:0]   ) ,
   .dt_b_i   ( ext_wmem_w_dt    ) ,
   .dt_b_o   ( wdt     ) );
   
assign ext_W_r_dt = { 80'd0, wdt[167:88],8'd0, wdt[87:0]} ;


assign STATUS_O[7:0]  = {ar_exec, aw_exec, ext_P_mem_en, ext_P_mem_we, ext_D_mem_en, ext_D_mem_we, ext_W_mem_en, ext_W_mem_we} ;
assign DEBUG_O[15:8]  = ext_mem_addr [7:0] ;
assign DEBUG_O[7:0]   = pmem_addr_i[7:0] ;
    


endmodule
