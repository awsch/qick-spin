module bram_dual_port_dc # (
   parameter MEM_AW  = 16 , 
   parameter MEM_DW  = 16 ,
   parameter RAM_OUT  = "NO_REGISTERED" // Select "NO_REGISTERED" or "REGISTERED" 
) ( 
   input  wire               clk_a_i  ,
   input  wire               en_a_i  ,
   input  wire               we_a_i  ,
   input  wire [MEM_AW-1:0]  addr_a_i  ,
   input  wire [MEM_DW-1:0]  dt_a_i  ,
   output wire [MEM_DW-1:0]  dt_a_o  ,
   input  wire               clk_b_i  ,
   input  wire               en_b_i  ,
   input  wire               we_b_i  ,
   input  wire [MEM_AW-1:0]  addr_b_i  ,
   input  wire [MEM_DW-1:0]  dt_b_i  ,
   output wire [MEM_DW-1:0]  dt_b_o  );

localparam RAM_SIZE = 2**MEM_AW ;
  
reg [MEM_DW-1:0] RAM [RAM_SIZE];
reg [MEM_DW-1:0] ram_dt_a = {MEM_DW{1'b0}};
reg [MEM_DW-1:0] ram_dt_b = {MEM_DW{1'b0}};

always @(posedge clk_a_i)
   if (en_a_i) begin
      ram_dt_a <= RAM[addr_a_i] ;
      if (we_a_i)
         RAM[addr_a_i] <= dt_a_i;
      //else
      //   ram_dt_a <= RAM[addr_a_i] ;
   end
always @(posedge clk_b_i)
   if (en_b_i)
      if (we_b_i)
         RAM[addr_b_i] <= dt_b_i;
      else
         ram_dt_b <= RAM[addr_b_i] ;

generate
   if (RAM_OUT == "NO_REGISTERED") begin: no_output_register // 1 clock cycle read
      assign dt_a_o = ram_dt_a ;
      assign dt_b_o = ram_dt_b ;
   end else begin: output_register // 2 clock cycle read
      reg [MEM_DW-1:0] ram_dt_a_r = {MEM_DW{1'b0}};
      reg [MEM_DW-1:0] ram_dt_b_r = {MEM_DW{1'b0}};
      always @(posedge clk_a_i) ram_dt_a_r <= ram_dt_a;
      always @(posedge clk_b_i) ram_dt_b_r <= ram_dt_b;
      assign dt_a_o = ram_dt_a_r ;
      assign dt_b_o = ram_dt_b_r ;
   end
endgenerate

endmodule

module LIFO # (
   parameter WIDTH = 16 , 
   parameter DEPTH = 8    // MAX 256
) ( 
   input  wire                clk_i   ,
   input  wire                rst_ni  ,
   input  wire  [WIDTH - 1:0] data_i  ,
   input  wire                   push ,
   input  wire                   pop  ,
   output wire  [WIDTH - 1:0] data_o  ,
   output wire empty_o                  ,
   output wire full_o                   );
   

wire [7:0]        ptr_p1, ptr_m1 ;
reg  [7:0]        ptr            ;
reg  [WIDTH-1:0]  stack [DEPTH]  ;

assign ptr_p1 = ptr + 1'b1;
assign ptr_m1 = ptr - 1'b1;

// Pointer
always_ff @(posedge clk_i) begin
   if (!rst_ni)      ptr <= 0;
   else if (push & !full_o) ptr <= ptr_p1;
   else if (pop  & !empty_o) ptr <= ptr_m1;
end

// Data
always_ff @(posedge clk_i) begin
   if (!rst_ni)   stack      <= '{default:'0} ;
   if(push & !full_o)       stack[ptr] <= data_i ;
end

assign empty_o = !(|ptr)      ;
assign full_o  = !(|(ptr ^ DEPTH));
assign data_o = stack[ptr_m1];

endmodule




module BRAM_FIFO_DC # (
   parameter FIFO_DW = 16 , 
   parameter FIFO_AW = 8 
) ( 
   input  wire                   wr_clk_i    ,
   input  wire                   wr_rst_ni   ,
   input  wire                   wr_en_i     ,
   input  wire                   push        ,
   input  wire [FIFO_DW - 1:0]   data_i      ,
   input  wire                   rd_clk_i    ,
   input  wire                   rd_rst_ni   ,
   input  wire                   rd_en_i     ,
   input  wire                   pop         ,
   output wire  [FIFO_DW - 1:0]  data_o      ,
   input  wire                   flush_i     ,
   output wire                   empty_o     ,
   output wire                   full_o      );

// The WRITE_POINTER is on the Last Empty Value
// The READ_POINTER is on the Last Value
wire [FIFO_AW-1:0] rd_gptr_p1   ;
wire [FIFO_AW-1:0] wr_gptr_p1   ;
wire [FIFO_AW-1:0] rd_ptr, wr_ptr, rd_gptr, wr_gptr  ;

// Sample Pointers
reg [FIFO_AW-1:0] wr_gptr_rcd, wr_gptr_r, wr_gptr_p1_rcd, wr_gptr_p1_r; 
always_ff @(posedge rd_clk_i) begin
   wr_gptr_rcd      <= wr_gptr;
   wr_gptr_r        <= wr_gptr_rcd;
   wr_gptr_p1_rcd   <= wr_gptr_p1;
   wr_gptr_p1_r     <= wr_gptr_p1_rcd;
end

wire [FIFO_DW - 1:0] mem_dt;

wire empty, full;
assign empty_2   = (rd_gptr == wr_gptr_r) ;   
assign empty   = ~|(rd_gptr ^ wr_gptr_r) ;   
assign full    = (rd_gptr == wr_gptr_p1_r);

// ALWAYS POP
//wire do_pop, do_push;
assign do_pop_2  = pop & !empty;
assign do_push_2 = push & !full;


// REG POP
reg do_pop;
wire do_push;
//reg do_pop_2, do_push_2;
always_ff @(posedge rd_clk_i) begin
   do_pop      <= pop & !empty;
end

assign do_push    = push & !full;



//Gray Code Counters
gcc #(
   .DW	( FIFO_AW )
) gcc_wr_ptr  (
   .clk_i            ( wr_clk_i     ) ,
   .rst_ni           ( wr_rst_ni    ) ,
   .async_clear_i    ( flush_i      ) ,
   .clear_o          ( clr_wr       ) ,
   .cnt_en_i         ( do_push      ) ,
   .count_bin_o      ( wr_ptr       ) ,
   .count_gray_o     ( wr_gptr      ) ,
   .count_bin_p1_o   (     ) ,
   .count_gray_p1_o  ( wr_gptr_p1   ) );

gcc #(
   .DW	( FIFO_AW )
) gcc_rd_ptr (
   .clk_i            ( rd_clk_i     ) ,
   .rst_ni           ( rd_rst_ni    ) ,
   .async_clear_i    ( flush_i      ) ,
   .clear_o          ( clr_rd       ) ,
   .cnt_en_i         ( do_pop       ) ,
   .count_bin_o      ( rd_ptr       ) ,
   .count_gray_o     ( rd_gptr      ) ,
   .count_bin_p1_o   (     ) ,
   .count_gray_p1_o  ( rd_gptr_p1   ) );

// Data
bram_dual_port_dc  # (
   .MEM_AW  ( FIFO_AW     )  , 
   .MEM_DW  ( FIFO_DW     )  ,
   .RAM_OUT ( "NO_REGISTERED" ) // Select "NO_REGISTERED" or "REGISTERED" 
) wave_mem ( 
   .clk_a_i    ( wr_clk_i  ) ,
   .en_a_i     ( wr_en_i   ) ,
   .we_a_i     ( do_push   ) ,
   .addr_a_i   ( wr_ptr    ) ,
   .dt_a_i     ( data_i    ) ,
   .dt_a_o     ( ) ,
   .clk_b_i    ( rd_clk_i  ) ,
   .en_b_i     ( rd_en_i   ) ,
   .we_b_i     ( 1'b0      ) ,
   .addr_b_i   ( rd_ptr    ) ,
   .dt_b_i     (     ) ,
   .dt_b_o     ( mem_dt    ) );
   
assign empty_o = empty | flush_i | clr_rd | clr_wr;
assign full_o  = full;
assign data_o  = mem_dt;

endmodule



/// Clock Domain Register Change
module sync_reg # (
   parameter DW  = 32
)(
   input  wire [DW-1:0] dt_i     , 
   input  wire          clk_i  ,
   input  wire          rst_ni  ,
   output wire [DW-1:0] dt_o     );
   
// FAST REGISTER GRAY TRANSFORM OF INPUT
reg [DW-1:0] data_rcd, data_r ;
always_ff @(posedge clk_i)
   if(!rst_ni) begin
      data_rcd  <= 0;
      data_r    <= 0;
   end else begin 
      data_rcd  <= dt_i;
      data_r    <= data_rcd;
      end
assign dt_o = data_r ;

endmodule

//GRAY CODE COUNTER
module gcc # (
   parameter DW  = 32
)(
   input  wire          clk_i          ,
   input  wire          rst_ni         ,
   input  wire          async_clear_i  ,
   output wire          clear_o  ,
   input  wire          cnt_en_i       ,
   output wire [DW-1:0] count_bin_o    , 
   output wire [DW-1:0] count_gray_o   ,
   output wire [DW-1:0] count_bin_p1_o , 
   output wire [DW-1:0] count_gray_p1_o);
   
reg [DW-1:0] count_bin  ;    // count turned into binary number
wire [DW-1:0] count_bin_p1; // count_bin+1

reg [DW-1:0] count_bin_r, count_gray_r;

integer ind;
always_comb begin
   count_bin[DW-1] = count_gray_r[DW-1];
   for (ind=DW-2 ; ind>=0; ind=ind-1) begin
      count_bin[ind] = count_bin[ind+1]^count_gray_r[ind];
   end
end

reg clear_rcd, clear_r;
always_ff @(posedge clk_i, negedge rst_ni)
   if(!rst_ni) begin
      clear_rcd       <= 0;
      clear_r         <= 0;
   end else begin
      clear_rcd       <= async_clear_i;
      clear_r         <= clear_rcd;
   end
   
assign count_bin_p1 = count_bin + 1 ; 

reg [DW-1:0] count_bin_2r, count_gray_2r;
always_ff @(posedge clk_i, negedge rst_ni)
   if(!rst_ni) begin
      count_gray_r      <= 1;
      count_bin_r       <= 1;
      count_gray_2r     <= 0;
      count_bin_2r      <= 0;
   end else begin
      if (clear_r) begin
         count_gray_r      <= 1;
         count_bin_r       <= 1;
         count_gray_2r     <= 0;
         count_bin_2r      <= 0;
      end else if (cnt_en_i) begin
         count_gray_r   <= count_bin_p1 ^ {1'b0,count_bin_p1[DW-1:1]};
         count_bin_r    <= count_bin_p1;
         count_gray_2r  <= count_gray_r;
         count_bin_2r   <= count_bin_r;
      
      end
  end

assign clear_o = clear_r ;
assign count_bin_o      = count_bin_2r ;
assign count_gray_o     = count_gray_2r ;
assign count_bin_p1_o   = count_bin_r ;
assign count_gray_p1_o  = count_gray_r ;

endmodule


module BRAM_FIFO_DC_2 # (
   parameter FIFO_DW = 16 , 
   parameter FIFO_AW = 8 
) ( 
   input  wire                   wr_clk_i    ,
   input  wire                   wr_rst_ni   ,
   input  wire                   wr_en_i     ,
   input  wire                   push_i        ,
   input  wire [FIFO_DW - 1:0]   data_i      ,
   input  wire                   rd_clk_i    ,
   input  wire                   rd_rst_ni   ,
   input  wire                   rd_en_i     ,
   input  wire                   pop_i         ,
   output wire  [FIFO_DW - 1:0]  data_o      ,
   input  wire                   flush_i     ,
   output wire                   async_empty_o     ,
   output wire                   async_full_o      );

// The WRITE_POINTER is on the Last Empty Value
// The READ_POINTER is on the Last Value
wire [FIFO_AW-1:0] rd_gptr_p1   ;
wire [FIFO_AW-1:0] wr_gptr_p1   ;
wire [FIFO_AW-1:0] rd_ptr, wr_ptr, rd_gptr, wr_gptr  ;

// Sample Pointers
reg [FIFO_AW-1:0] wr_gptr_rcd, wr_gptr_r, wr_gptr_p1_rcd, wr_gptr_p1_r; 
always_ff @(posedge rd_clk_i) begin
   wr_gptr_rcd      <= wr_gptr;
   wr_gptr_r        <= wr_gptr_rcd;
   wr_gptr_p1_rcd   <= wr_gptr_p1;
   wr_gptr_p1_r     <= wr_gptr_p1_rcd;
end
reg [FIFO_AW-1:0] rd_gptr_rcd, rd_gptr_r; 
always_ff @(posedge rd_clk_i) begin
   rd_gptr_rcd      <= rd_gptr;
   rd_gptr_r        <= rd_gptr_rcd;
end

reg clr_fifo_req, clr_fifo_ack;
always_ff @(posedge wr_clk_i, negedge wr_rst_ni) begin
   if (!wr_rst_ni) begin
      clr_fifo_req <= 0 ;
      clr_fifo_ack <= 0 ;
   end else begin
      if (flush_i) 
         clr_fifo_req <= 1 ;
      else if (clr_fifo_ack )
         clr_fifo_req <= 0 ;

      if (clr_rd & clr_wr) 
          clr_fifo_ack <= 1 ;
      else if (clr_fifo_ack & !clr_rd & !clr_wr)
          clr_fifo_ack <= 0 ;
   end
end

assign busy = clr_fifo_ack | clr_fifo_req ;

wire [FIFO_DW - 1:0] mem_dt;

wire async_empty, async_full;

//SYNC with POP (RD_CLK)
assign async_empty   = (rd_gptr == wr_gptr_r) ; //| pop_i & (rd_gptr_p1 == wr_gptr_p1);   

//SYNC with PUSH (WR_CLK)
assign async_full    = (rd_gptr_r == wr_gptr_p1) ;

wire do_pop, do_push;
assign do_pop  = pop_i & !async_empty;
assign do_push = push_i & !async_full;

assign async_empty_o = async_empty | busy;
assign async_full_o  = async_full  | busy;
assign data_o  = mem_dt;

//Gray Code Counters
gcc #(
   .DW	( FIFO_AW )
) gcc_wr_ptr  (
   .clk_i            ( wr_clk_i     ) ,
   .rst_ni           ( wr_rst_ni    ) ,
   .async_clear_i    ( clr_fifo_req      ) ,
   .clear_o          ( clr_wr       ) ,
   .cnt_en_i         ( do_push      ) ,
   .count_bin_o      ( wr_ptr       ) ,
   .count_gray_o     ( wr_gptr      ) ,
   .count_bin_p1_o   (     ) ,
   .count_gray_p1_o  ( wr_gptr_p1   ) );

gcc #(
   .DW	( FIFO_AW )
) gcc_rd_ptr (
   .clk_i            ( rd_clk_i     ) ,
   .rst_ni           ( rd_rst_ni    ) ,
   .async_clear_i    ( clr_fifo_req      ) ,
   .clear_o          ( clr_rd       ) ,
   .cnt_en_i         ( do_pop       ) ,
   .count_bin_o      ( rd_ptr       ) ,
   .count_gray_o     ( rd_gptr      ) ,
   .count_bin_p1_o   (     ) ,
   .count_gray_p1_o  ( rd_gptr_p1   ) );

// Data
bram_dual_port_dc  # (
   .MEM_AW  ( FIFO_AW     )  , 
   .MEM_DW  ( FIFO_DW     )  ,
   .RAM_OUT ( "NO_REGISTERED" ) // Select "NO_REGISTERED" or "REGISTERED" 
) fifo_mem ( 
   .clk_a_i    ( wr_clk_i  ) ,
   .en_a_i     ( wr_en_i   ) ,
   .we_a_i     ( do_push   ) ,
   .addr_a_i   ( wr_ptr    ) ,
   .dt_a_i     ( data_i    ) ,
   .dt_a_o     ( ) ,
   .clk_b_i    ( rd_clk_i  ) ,
   .en_b_i     ( rd_en_i   ) ,
   .we_b_i     ( 1'b0      ) ,
   .addr_b_i   ( rd_ptr    ) ,
   .dt_b_i     (     ) ,
   .dt_b_o     ( mem_dt    ) );
   
endmodule

