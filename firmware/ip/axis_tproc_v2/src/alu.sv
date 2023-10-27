`include "proc_defines.svh"

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


module div #(
   parameter DWA = 32 ,
   parameter DWB = 32
) (
   
   input  wire            start_i       ,
   input  wire [DWA-1:0]  A_i           ,
   input  wire [DWB-1:0]  B_i           ,
   input  wire            eod_o         ,
   output wire [DWB-1:0]  div_remainder_o    ,
   output wire [DWA-1:0]  div_quotient_o  );

reg [DWA-1     : 0 ] q_temp, r_temp;
reg [DWA+DWB-1   : 0 ] sub_temp;

integer ind_bit;
always_comb begin 
   r_temp   = A_i;
   //sub_temp = B_i;
   for (ind_bit=DWA-1; ind_bit >= 0 ; ind_bit=ind_bit-1) begin
      sub_temp = B_i << ind_bit ;
   	if (r_temp >= sub_temp)
   	 begin
	     q_temp[ind_bit] = 1'b1 ;
	     r_temp = r_temp - sub_temp;
      end else 
	      q_temp[ind_bit] = 1'b0;
   end
end

assign div_remainder_o = r_temp ;
assign div_quotient_o  = q_temp;

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
   if (!rst_ni)         
      en_r  <= 0 ;
   else
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

reg [31:0] alu_out;

// DSP OUTPUTS
wire [47:0] alu_result ;
// DSP INPUTS
reg  [4:0] INMODE   ;
reg  [6:0] OPMODE   ;
reg  [3:0] ALUMODE  ;
reg        CIN      ;


reg signed [29:0] A_dt ; 
reg signed [17:0] B_dt ; 
reg signed [47:0] C_dt ; 
reg signed [24:0] D_dt ; 
reg working, working_r ;

always_ff @ (posedge clk_i, negedge rst_ni) begin
   if (!rst_ni) begin
         A_dt <= 0;
         B_dt <= 0;
         C_dt <= 0;
         D_dt <= 0; 
         INMODE   <= 0;
         OPMODE  <= 0;
         ALUMODE  <= 0;
         CIN      <= 0;
         working  <= 1'b0 ;
         working_r  <= 1'b0 ;
   end else begin
      working_r  <= working ;
      if (start_i) begin
         A_dt     <= A_i[29:0] ;
         B_dt     <= B_i[18:0] ;
         C_dt     <= C_i ;
         D_dt     <= D_i[24:0] ; 
         INMODE   <= { 1'b0, alu_op_i[4:2] , alu_op_i[2]}  ;
         OPMODE   <= { 1'b0, alu_op_i[1], alu_op_i[1] , 4'b0101} ;
         ALUMODE  <= { 3'b000, alu_op_i[0] }   ;
         CIN      <= alu_op_i[0]  ;
         working  <= 1'b1 ;
      end else if (working_r) begin
         working           <= 1'b0;
         working_r         <= 1'b0;
      end
   end
end

//
assign ce = 1; // AL DFF DISABLES

// DSP48E1: 48-bit Multi-Functional Arithmetic Block
//          Virtex-7
// Xilinx HDL Language Template, version 2020.2
   DSP48E1 #(
      // Feature Control Attributes: Data Path Selection
      .A_INPUT    ("DIRECT"),           // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .B_INPUT    ("DIRECT"),           // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .USE_DPORT  ("TRUE"),             // Select D port usage (TRUE or FALSE)
      .USE_MULT   ("MULTIPLY"),         // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
      .USE_SIMD   ("ONE48"),            // SIMD selection ("ONE48", "TWO24", "FOUR12")
      .AUTORESET_PATDET("RESET_MATCH"), // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
      //.MASK(48'h3fffffffffff),        // 48-bit mask value for pattern detect (1=ignore)
      .MASK(48'h000000000000),          // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
      .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
      .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
      .ACASCREG         (0),            // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
      .ADREG            (0),            // Number of pipeline stages for pre-adder (0 or 1)
      .ALUMODEREG       (0),            // Number of pipeline stages for ALUMODE (0 or 1)
      .AREG             (0),            // Number of pipeline stages for A (0, 1 or 2)
      .BCASCREG         (0),            // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
      .BREG             (0),            // Number of pipeline stages for B (0, 1 or 2)
      .CARRYINREG       (1),            // Number of pipeline stages for CARRYIN (0 or 1)
      .CARRYINSELREG    (1),            // Number of pipeline stages for CARRYINSEL (0 or 1)
      .CREG             (1),            // Number of pipeline stages for C (0 or 1)
      .DREG             (0),            // Number of pipeline stages for D (0 or 1)
      .INMODEREG        (1),            // Number of pipeline stages for INMODE (0 or 1)
      .MREG             (1),            // Number of multiplier pipeline stages (0 or 1)
      .OPMODEREG        (1),            // Number of pipeline stages for OPMODE (0 or 1)
      .PREG             (0)             // Number of pipeline stages for P (0 or 1)
   )
   DSP48E1_inst (
      // Cascade: 30-bit (each) output: Cascade Ports
      .ACOUT                  (ACOUT ),  // 30-bit output: A port cascade output
      .BCOUT                  (BCOUT ),  // 18-bit output: B port cascade output
      .CARRYCASCOUT           ( ),       // 1-bit output: Cascade carry output
      .MULTSIGNOUT            ( ),       // 1-bit output: Multiplier sign cascade output
      .PCOUT                  ( ),       // 48-bit output: Cascade output
      .OVERFLOW               ( ),       // 1-bit output: Overflow in add/acc output
      .PATTERNBDETECT         ( ),       // 1-bit output: Pattern bar detect output
      .PATTERNDETECT          ( ),       // 1-bit output: Pattern detect output
      .UNDERFLOW              ( ),       // 1-bit output: Underflow in add/acc output
      .CARRYOUT               ( ),       // 4-bit output: Carry output
      .P                      (alu_result), // 48-bit output: Primary data output
      // Cascade: 30-bit (each) input: Cascade Ports
      .ACIN                   (0),              // 30-bit input: A cascade data input
      .BCIN                   (0),              // 18-bit input: B cascade input
      .CARRYCASCIN            (0),              // 1-bit input: Cascade carry input
      .MULTSIGNIN             (0),              // 1-bit input: Multiplier sign input
      .PCIN                   (0),              // 48-bit input: P cascade input
      // Control: 4-bit (each) input: Control Inputs/Status Bits
      .ALUMODE                (ALUMODE),   // 4-bit input: ALU control input
      .CARRYINSEL             (0),         // 3-bit input: Carry select input
      .CLK                    (clk_i),     // 1-bit input: Clock input
      .INMODE                 (INMODE),    // 5-bit input: INMODE control input
      .OPMODE                 (OPMODE),    // 7-bit input: Operation mode input
      // Data: 30-bit (each) input: Data Ports
      .A                      (A_dt),                           // 30-bit input: A data input
      .B                      (B_dt),                           // 18-bit input: B data input
      .C                      (C_dt),                           // 48-bit input: C data input
      .CARRYIN                (CIN),               // 1-bit input: Carry input signal
      .D                      (D_dt),                           // 25-bit input: D data input
      // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
      .CEA1                   (ce),           // 1-bit input: Clock enable input for 1st stage AREG
      .CEA2                   (ce),           // 1-bit input: Clock enable input for 2nd stage AREG
      .CEAD                   (ce),           // 1-bit input: Clock enable input for ADREG
      .CEALUMODE              (ce),           // 1-bit input: Clock enable input for ALUMODE
      .CEB1                   (ce),           // 1-bit input: Clock enable input for 1st stage BREG
      .CEB2                   (ce),           // 1-bit input: Clock enable input for 2nd stage BREG
      .CEC                    (ce),           // 1-bit input: Clock enable input for CREG
      .CECARRYIN              (ce),           // 1-bit input: Clock enable input for CARRYINREG
      .CECTRL                 (ce),           // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
      .CED                    (ce),           // 1-bit input: Clock enable input for DREG
      .CEINMODE               (ce),           // 1-bit input: Clock enable input for INMODEREG
      .CEM                    (ce),           // 1-bit input: Clock enable input for MREG
      .CEP                    (ce),           // 1-bit input: Clock enable input for PREG
      .RSTA                   (~rst_ni),          // 1-bit input: Reset input for AREG
      .RSTALLCARRYIN          (~rst_ni),          // 1-bit input: Reset input for CARRYINREG
      .RSTALUMODE             (~rst_ni),          // 1-bit input: Reset input for ALUMODEREG
      .RSTB                   (~rst_ni),          // 1-bit input: Reset input for BREG
      .RSTC                   (~rst_ni),          // 1-bit input: Reset input for CREG
      .RSTCTRL                (~rst_ni),          // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
      .RSTD                   (~rst_ni),          // 1-bit input: Reset input for DREG and ADREG
      .RSTINMODE              (~rst_ni),          // 1-bit input: Reset input for INMODEREG
      .RSTM                   (~rst_ni),          // 1-bit input: Reset input for MREG
      .RSTP                   (~rst_ni)           // 1-bit input: Reset input for PREG
   );

   // End of DSP48E1_inst instantiation

// v <= (not add_A(7) and not add_B(7) and Y(7)) or (add_A(7) and add_B(7) and not Y(7))

assign arith_result_o  = alu_result      ;
assign ready_o          = ~ (working | working_r);
endmodule


