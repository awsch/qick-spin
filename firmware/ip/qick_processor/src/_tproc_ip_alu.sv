///////////////////////////////////////////////////////////////////////////////
//  FERMI RESEARCH LAB
///////////////////////////////////////////////////////////////////////////////
//  Author         : Martin Di Federico
//  Date           : 10-2023
//  Version        : 2
///////////////////////////////////////////////////////////////////////////////
//  QICK PROCESSOR :  tProc_v2
/* Description: 

*/
//////////////////////////////////////////////////////////////////////////////

`include "_tproc_defines.svh"

module AB_alu (
   input  wire                clk_i         ,
   input  wire signed [31:0]  A_i         ,
   input  wire signed [31:0]  B_i         ,
   input  wire [3:0]          alu_op_i    ,
   output wire                Z_o,
   output wire                C_o,
   output wire                S_o,
   output wire signed [31:0]  alu_result_o         );

reg [32:0]  result;
wire zero_flag, carry_flag, sign_flag;

//    << .... Left shift   (i.e. a << 2 shifts a two bits to the left)
//    <<< ... Left shift and fill with zeroes
//    >> .... Right shift (i.e. b >> 1 shifts b one bits to the right)
//    >>> ... Right shift and maintain sign bit
			
/*
reg [2:0] shift;
always_comb begin
      case ( B_i[3:0] )
         4'b0001: shift  = 1  ; // 1
         4'b0010: shift  = 2  ; // 2
         4'b0100: shift  = 4  ; // 4
         4'b1000: shift  = 8  ; // 8 
         default: shift  = 0  ; //Others
     endcase
end
*/
wire[3:0] shift ;
assign shift = B_i[3:0];

wire [31:0] neg_B, a_plus_b, a_minus_b, abs_b;
wire [31:0] msh_a, lsh_a, swap_a;  

assign neg_B      = -B_i ;
assign a_plus_b   = A_i + B_i;
assign a_minus_b  = A_i + neg_B;
assign abs_b      = B_i[31] ? neg_B : B_i;
assign msh_a      = {16'b00000000_00000000, A_i[31:16]} ;
assign lsh_a      = {16'b00000000_00000000, A_i[15: 0]} ;
assign swap_a     = {A_i[15:0], A_i[31:16]} ;

wire [31:0] a_cat_b, a_sl_b, a_lsr_b, a_asr_b ;
assign a_cat_b    = {A_i[15:0], B_i[15:0]};
assign a_sl_b     = A_i <<  shift ;
assign a_lsr_b    = A_i >>  shift ;
assign a_asr_b    = A_i >>> shift ;

always_comb begin
   if (~alu_op_i[0])
      // ARITHMETIC
      case ( alu_op_i[3:1] )
         3'b000: result = a_plus_b  ;
         3'b001: result = a_minus_b ;
         3'b010: result = A_i & B_i   ;
         3'b011: result = a_asr_b ;
         3'b100: result = abs_b ;
         3'b101: result = msh_a    ;
         3'b110: result = lsh_a   ;
         3'b111: result = swap_a   ;
      endcase
   else
      // LOGIC
      case ( alu_op_i[3:1] )
         3'b000: result = ~A_i      ;
         3'b001: result = A_i | B_i ;
         3'b010: result = A_i ^ B_i ;
         3'b011: result = a_cat_b ;
         3'b100: result = 0         ;
         3'b101: result = {31'd0, ^A_i}      ;
         3'b110: result =  a_sl_b  ;
         3'b111: result =  a_lsr_b  ;
      endcase
end

assign zero_flag  = (result == 0) ;
assign carry_flag = result[32];
assign sign_flag  = result[31];

assign alu_result_o = result[31:0] ;
assign Z_o = zero_flag ;
assign C_o = carry_flag ;
assign S_o = sign_flag ;

endmodule

////////////////////////////////////////////////////////////////////////////////

module div_r #(
   parameter DW      = 32 ,
   parameter N_PIPE  = 32 
) (
   input  wire             clk_i           ,
   input  wire             rst_ni          ,
   input  wire             start_i         ,
   input  wire [DW-1:0]    A_i             ,
   input  wire [DW-1:0]    B_i             ,
   output wire             ready_o         ,
   output wire [DW-1:0]    div_quotient_o  ,
   output wire [DW-1:0]    div_remainder_o );

localparam comb_per_reg = DW / N_PIPE;

reg [DW-1     : 0 ] inB     ;
reg [DW-1     : 0 ] q_temp     ;
reg [DW-1     : 0 ] r_temp     [N_PIPE] ;
reg [DW-1     : 0 ] r_temp_nxt [N_PIPE] ;
reg [2*DW-1 : 0 ] sub_temp [N_PIPE] ;

integer ind_comb_stage [N_PIPE];
integer ind_bit[N_PIPE]; 

wire working;
reg  [N_PIPE-1:0] en_r  ;

assign working    = |en_r;


always_ff @ (posedge clk_i, negedge rst_ni) begin
   if (!rst_ni) begin        
      en_r      <= 0 ;
      r_temp[0] <= 0 ;
      inB       <= 0 ;
   end else
      if (start_i) begin
         en_r           <= {en_r[N_PIPE-2:0], 1'b1} ;
         r_temp   [0]   <= A_i ;
         inB            <= B_i ;
      end else if (working)
         en_r           <= {en_r[N_PIPE-2:0], 1'b0} ;
end // Always


///////////////////////////////////////////////////////////////////////////
// FIRST STAGE
always @ (r_temp[0], r_temp_nxt[0], inB) begin
   r_temp_nxt[0] = r_temp[0];
   for (ind_comb_stage[0]=0; ind_comb_stage[0] < comb_per_reg ; ind_comb_stage[0]=ind_comb_stage[0]+1) begin
      ind_bit[0] = (DW-1) - ( ind_comb_stage[0] ) ;
      sub_temp[0] = inB << ind_bit[0] ;
      if (r_temp_nxt[0] >= sub_temp[0]) begin
         q_temp [ind_bit[0]]  = 1'b1 ;
         r_temp_nxt[0] = r_temp_nxt[0] - sub_temp[0];
      end else 
         q_temp [ind_bit[0]] = 1'b0;
   end
end

genvar ind_reg_stage;
for (ind_reg_stage=1; ind_reg_stage < N_PIPE ; ind_reg_stage=ind_reg_stage+1) begin
   // SEQUENCIAL PART
   always_ff @ (posedge clk_i) begin 
      r_temp   [ind_reg_stage]   = r_temp_nxt   [ind_reg_stage-1] ;
   end
   // COMBINATORIAL PART
   always_comb begin
      r_temp_nxt[ind_reg_stage] = r_temp[ind_reg_stage];
      for (ind_comb_stage[ind_reg_stage]=0; ind_comb_stage[ind_reg_stage] < comb_per_reg ; ind_comb_stage[ind_reg_stage]=ind_comb_stage[ind_reg_stage]+1) begin
         ind_bit[ind_reg_stage] = (DW-1) - (ind_comb_stage[ind_reg_stage] + (ind_reg_stage * comb_per_reg)) ;
         sub_temp[ind_reg_stage] = inB << ind_bit[ind_reg_stage] ;
         if (r_temp_nxt[ind_reg_stage] >= sub_temp[ind_reg_stage]) begin
            q_temp [ind_bit[ind_reg_stage]]  = 1'b1 ;
            r_temp_nxt[ind_reg_stage] = r_temp_nxt[ind_reg_stage] - sub_temp[ind_reg_stage];
         end else 
            q_temp [ind_bit[ind_reg_stage]] = 1'b0;
      end
   end
end

assign ready_o          = ~working;
assign div_quotient_o   = q_temp;
assign div_remainder_o  = r_temp_nxt[N_PIPE-1];

endmodule

module arith (
   input  wire                clk_i          ,
   input  wire                rst_ni          ,
   input  wire                start_i        ,
   input  wire signed [31:0]  A_i            ,
   input  wire signed [31:0]  B_i            ,
   input  wire signed [31:0]  C_i            ,
   input  wire signed [31:0]  D_i            ,
   input  wire [4:0]          alu_op_i       ,
   output wire                ready_o        ,
   output wire signed [63:0]  arith_result_o   );

// DSP OUTPUTS
wire [45:0] arith_result ;
// DSP INPUTS
reg  [3:0] ALU_OP  ;

reg signed [26:0] A_dt ; 
reg signed [17:0] B_dt ; 
reg signed [31:0] C_dt ; 
reg signed [26:0] D_dt ; 
reg working, working_r ;

always_ff @ (posedge clk_i, negedge rst_ni) begin
   if (!rst_ni) begin
         A_dt <= 0;
         B_dt <= 0;
         C_dt <= 0;
         D_dt <= 0; 
         ALU_OP   <= 0;
         working  <= 1'b0 ;
         working_r  <= 1'b0 ;
   end else begin
      working_r  <= working ;
      if (start_i) begin
         A_dt     <= A_i[26:0] ;
         B_dt     <= B_i[17:0] ;
         C_dt     <= C_i[31:0] ;
         D_dt     <= D_i[26:0] ; 
         ALU_OP   <= { alu_op_i[3:0]}  ;
         working  <= 1'b1 ;
      end else if (working_r) begin
         working           <= 1'b0;
         working_r         <= 1'b0;
      end
   end
end


dsp_macro_0 ARITH_DSP (
  .CLK  ( clk_i),  // input wire CLK
  .SEL  ( ALU_OP ),  // input wire [3 : 0] SEL
  .A    ( A_dt[26:0]   ),      // input wire [26 : 0] A
  .B    ( B_dt[17:0]   ),      // input wire [17 : 0] B
  .C    ( C_dt[31:0]   ),      // input wire [31 : 0] C
  .D    ( D_dt[26:0]   ),      // input wire [26 : 0] D
  .P    ( arith_result      )      // output wire [45 : 0] P
);

//signed extension of 
assign arith_result_o  = { {18{arith_result[45]}}, arith_result}      ;
assign ready_o          = ~ (working | working_r);
endmodule

