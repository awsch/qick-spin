///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// GENERAL
`ifndef DEFINES
   `define DEFINES
/*   `define PMEM_AW        8
   `define DMEM_AW        8           // Data Memory Address Width 
   `define WMEM_AW        8           // Wave Memory Address Width 

   `define REG_AW         4           // Register Address Width 

   `define DMEM_DW        32           // Data Memory Data Width
   `define WMEM_DW       128           // Wave Memory Data Width

   `define IN_PORT_AW      2   // IN Port Address Width 
   `define OUT_PORT_AW     4   // Port Address Width 

   `define IN_PORT_QTY     2   // Total amount of DATA IN Ports 
   `define OUT_DPORT_QTY   4   // Total amount of DATA OUT Ports 
   `define OUT_WPORT_QTY   4   // Total amount of WAVE OUT Ports 


   `define WAV_QTY         (2 ** `WAVE_AW )    // Total Wave Storage
   
*/

   // Data Comming from the AXI Stream
   `define AXIS_IN_DW      32 // 14 - 30
   `define AXI_WDATA_WIDTH 32
   `define AXI_RDATA_WIDTH 32
   `define AXI_WSTRB_WIDTH 4 

   parameter CFG         = 3'b000;
   parameter BRANCH      = 3'b001;
   parameter REG_WR      = 3'b100;
   parameter MEM_WR      = 3'b101;
   parameter PORT_WR     = 3'b110;
   parameter CTRL        = 3'b111;

   
   typedef enum {DATA_MEM, WAVE_MEM, ALU, IMMEDIATE } type_reg_src ;


typedef struct packed {
   bit         we    ;
   bit         wreg_we ;
   bit [6:0]   addr  ;
   bit [1:0]   src  ;
} CTRL_REG;
  

typedef struct packed {
   reg       cfg_addr_imm  ;
   reg       cfg_dt_imm    ;
   reg       cfg_wave_src  ;
   reg       cfg_port_type ;
   reg       cfg_port_time ;
   reg [3:0] cfg_cond      ;
   reg       cfg_alu_src   ;
   reg [3:0] cfg_alu_op    ;
   reg [9:0] usr_ctrl ;
   reg       flag_we ;
   reg       dmem_we ;
   reg       wmem_we ;
   reg       port_we ;
   reg       port_re ;
} CTRL_FLOW;


typedef struct packed {
  logic [ 31 : 0 ]         p_time ;
  logic                    p_type ; // 00-WAVE 01-DATA 10-
  logic [3:0] p_addr ;
  logic [167 : 0 ]  p_data ;
} PORT_DT;


///////////////////////////////////////////////////////////////////////////////



  
   // typedef enum {ADD, SUB, MASK, LSL, LSR, ASR, ROL, ROR} arith_op_type
   // typedef enum {ADD=, SUB, MASK, LSL, LSR, ASR, ROL, ROR} t_proc_header ;
`endif

