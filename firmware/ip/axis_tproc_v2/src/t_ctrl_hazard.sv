`include "proc_defines.svh"
/* DATA FORWARDING 
The Data Forwaring occurs when Data from the ALU processing should be used in the next stage of the PIpeline, before the Write Back.Mem shopuld be usad in a Register
This block compares the Destination address and the Write_Reg_EN to see if the Data used in the current instruction is going to be wriotten 
in ther next steps and is still in the PIPELINE
*/
   
module t_ctrl_hazard (
   input   wire               clk_i             ,
   input   wire               rst_ni            ,
   input   wire [5:0]         rs_A_addr_i [2]   ,
   input   wire [15:0]        rs_A_dt_i   [2]   ,

   input   wire [6:0]         rs_D_addr_i [2]   ,
   input   wire [31:0]        rs_D_dt_i   [2]   ,
   // Register 
   input CTRL_REG             rd_reg_i          ,
   input CTRL_REG             x1_reg_i          ,
   input CTRL_REG             x2_reg_i          ,
   input CTRL_REG             wr_reg_i          ,
   input   wire [31:0]        wr_reg_dt_i       ,
   // Wave Register
   input wire                 id_wreg_used      ,
   // Time Condition 
   input wire                 id_tc_used        ,
   input wire                 tc_we           ,
   // Flag 
   input wire                 id_flag_used      ,
   input wire                 flag_we        ,
   // JUMP 
   input wire                 id_jmp_i          ,
   // ALU (00) Data in each Pipeline Stage
   input   wire [31:0]        x1_alu_dt_i       ,
   input   wire [31:0]        x2_alu_dt_i       ,
   // DMEM (01) in each Pipeline Stage
   input   wire [31:0]        x2_dmem_dt_i      ,
   // WAVE_REG (10) in each Pipeline Stage
   input   wire [31:0]        x2_wreg_dt_i      ,
   // IMM Data (11) in each Pipeline Stage
   input   wire [31:0]        rd_imm_dt_i       ,
   input   wire [31:0]        x1_imm_dt_i       ,
   input   wire [31:0]        x2_imm_dt_i       ,
   // New Data to avoid Hazard
   output  wire [15:0]        reg_A_dt_o [2]      ,      
   output  wire [31:0]        reg_D_dt_o [2]      ,      
   // Bubble in RD and Wait for DATA
   output  wire               bubble_id_o       ,       
   output  wire               bubble_rd_o       );


// DATA HAZARD
reg  [31:0]    reg_D_nxt [2] ;
reg  [1 :0]    stall_D_rd     ;

reg  [31:0]    data_nxt [4] ;
reg  [31:0]    data_r   [4] ;
reg  [3 :0]    stall_rd     ;
reg            stall_id, stall_id_f, stall_id_j     ;



// DATA FORWARDING
genvar ind_D;
generate
   for (ind_D=0; ind_D <2 ; ind_D=ind_D+1) begin
      always_comb begin
         reg_D_nxt[ind_D] = rs_D_dt_i[ind_D];
         stall_D_rd[ind_D] = 1'b0;
            if ( (rs_D_addr_i[ind_D] ==  x1_reg_i.addr ) & x1_reg_i.we )     //Data is in X1 STage
               unique case (x1_reg_i.src)
                  2'b00 : reg_D_nxt[ind_D] = x1_alu_dt_i  ; // Data Comes from ALU 
                  2'b01 : stall_D_rd[ind_D] = 1'b1          ; // Data Comes from DATA MEMORY
                  2'b10 : stall_D_rd[ind_D] = 1'b1          ; // Data Comes from WAVE REG 
                  2'b11 : reg_D_nxt[ind_D] = x1_imm_dt_i  ; // Data Comes from Imm 
               endcase
            else if ( (rs_D_addr_i[ind_D] ==  x2_reg_i.addr ) & x2_reg_i.we )     //Data is in X2 STage
               unique case (x2_reg_i.src)
                  2'b00 : reg_D_nxt[ind_D] = x2_alu_dt_i  ; // Data Comes from ALU 
                  2'b01 : reg_D_nxt[ind_D] = x2_dmem_dt_i ; // Data Comes from DATA MEMORY
                  2'b10 : reg_D_nxt[ind_D] = x2_wreg_dt_i ; // Data Comes from WAVE REG 
                  2'b11 : reg_D_nxt[ind_D] = x2_imm_dt_i  ; // Data Comes from Imm 
               endcase
            else  if ( (rs_D_addr_i[ind_D] ==  wr_reg_i.addr ) & wr_reg_i.we )     //Data was Written
               reg_D_nxt[ind_D] = wr_reg_dt_i;
      end // always_comb
   end //for
endgenerate

// ADDRESS FORWARDING
reg  [15:0]    reg_A_nxt [2] ;
reg  [1 :0]    stall_A_rd     ;

genvar ind_A;
generate
   for (ind_A=0; ind_A <2 ; ind_A=ind_A+1) begin
      always_comb begin
         reg_A_nxt[ind_A] = rs_A_dt_i[ind_A];
         stall_A_rd[ind_A] = 1'b0;
            if ( ( {1'b0,rs_A_addr_i[ind_A]} ==  x1_reg_i.addr ) & x1_reg_i.we )     //Data is in X1 STage
               unique case (x1_reg_i.src)
                  2'b00 : reg_A_nxt[ind_A] = x1_alu_dt_i   ; // Data Comes from ALU 
                  2'b01 : stall_A_rd[ind_A] = 1'b1         ; // Data Comes from DATA MEMORY
                  2'b10 : stall_A_rd[ind_A] = 1'b1         ; // Data Comes from WAVE REG 
                  2'b11 : reg_A_nxt[ind_A] = x1_imm_dt_i   ; // Data Comes from Imm 
               endcase
            else if ( ( {1'b0,rs_A_addr_i[ind_A]} ==  x2_reg_i.addr ) & x2_reg_i.we )     //Data is in X2 STage
               unique case (x2_reg_i.src)
                  2'b00 : reg_A_nxt[ind_A] = x2_alu_dt_i  ; // Data Comes from ALU 
                  2'b01 : reg_A_nxt[ind_A] = x2_dmem_dt_i ; // Data Comes from DATA MEMORY
                  2'b10 : reg_A_nxt[ind_A] = x2_wreg_dt_i ; // Data Comes from WAVE REG 
                  2'b11 : reg_A_nxt[ind_A] = x2_imm_dt_i  ; // Data Comes from Imm 
               endcase
            else  if ( ( {1'b0,rs_A_addr_i[ind_A]} ==  wr_reg_i.addr ) & wr_reg_i.we )     //Data was Written
               reg_A_nxt[ind_A] = wr_reg_dt_i;
      end // always_comb
   end //for
endgenerate


// WAVE Modification STALL 
// Wave Parameter Detection 
assign rd_w_wreg = (rd_reg_i.addr[6:5] == 2'b01) ;
assign x1_w_wreg = (x1_reg_i.addr[6:5] == 2'b01) ;
assign x2_w_wreg = (x2_reg_i.addr[6:5] == 2'b01) ;
assign w_wreg = rd_w_wreg | x1_w_wreg | x2_w_wreg ;

reg stall_id_w;
always_comb begin
   stall_id_w    = 1'b0    ;
   if (id_wreg_used) begin             // Wave Register will be Writtem to Memory
      if ( w_wreg )                    // Wave Register is going to be UPDATED
         stall_id_w    = 1'b1    ;     // Give time to UPDATE WAVE REG
   end
end



// FLAG DETECTION
always_comb begin
   stall_id_f    = 1'b0    ;
   if (id_flag_used) begin       // FLAG WILL BE USED
      if ( flag_we | tc_we)             // Flag is going to be UPDATED
         stall_id_f    = 1'b1    ;     // Give time to UPDATE FLAG
   end
end

wire rd_w_reg_addr, x1_w_reg_addr, x2_w_reg_addr  ;

assign rd_w_reg_addr = (rd_reg_i.addr == 7'b1001111) ;
assign x1_w_reg_addr = (x1_reg_i.addr == 7'b1001111) ;
assign x2_w_reg_addr = (x2_reg_i.addr == 7'b1001111) ;

assign w_reg_addr = rd_w_reg_addr | x1_w_reg_addr | x2_w_reg_addr ;

// ADDR DETECTION..SEE TO FORWARD IT
always_comb begin
   stall_id_j    = 1'b0    ;
   if (id_jmp_i) begin           // REAG_ADDR WILL BE UPDATED
      if ( w_reg_addr )          // REG_ADDR is going to be UPDATED
         stall_id_j    = 1'b1    ; // Give time to UPDATE FLAG
   end
end

reg  [15:0]    reg_A     [2] ;
reg  [31:0]    reg_D     [2] ;

//Register DATA & ADDRESS OUT
always_ff @ (posedge clk_i, negedge rst_ni)
   if (!rst_ni) begin
      reg_A          = '{default:'0};
      reg_D          = '{default:'0};
   end else begin 
      reg_A          = reg_A_nxt ;
      reg_D          = reg_D_nxt ;
   end

assign reg_A_dt_o      = reg_A;
assign reg_D_dt_o      = reg_D;
assign bubble_id_o   = stall_id_j | stall_id_f | stall_id_w;
assign bubble_rd_o   = |stall_A_rd | |stall_D_rd;

endmodule
