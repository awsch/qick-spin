`include "_qick_defines.svh"

module axi_lite_deco_4 # (
   parameter OUTS         =  4
)(
   input wire              ps_aclk      ,    
   input wire              ps_aresetn   ,    
   TYPE_AXI_LITE_IF_IN.slave     s_axi_lite   ,
   TYPE_IF_AXI_REG.master         m00_axi_lite ,
   TYPE_IF_AXI_REG.master         m01_axi_lite ,
   TYPE_IF_AXI_REG.master         m10_axi_lite ,
   TYPE_IF_AXI_REG.master         m11_axi_lite );

// OUTPUTS


// REGISTER BANK 
reg [1:0] reg_bank ;
always_ff @ (posedge ps_aclk, negedge ps_aresetn) begin
   if (!ps_aresetn)          
      reg_bank <= 2'b00;
   else begin
      if (s_axi_lite.axi_arvalid)
         reg_bank  <= s_axi_lite.axi_araddr[7:6];
      else if (s_axi_lite.axi_awvalid)
         reg_bank  <= s_axi_lite.axi_awaddr[7:6];
   end
end // Always

generate
always_comb begin
   m00_axi_lite.axi_awaddr  = 0 ;
   m00_axi_lite.axi_awprot  = 0 ;
   m00_axi_lite.axi_awvalid = 0 ;
   m00_axi_lite.axi_wdata   = 0 ;
   m00_axi_lite.axi_wstrb   = 0 ;
   m00_axi_lite.axi_wvalid  = 0 ;
   m00_axi_lite.axi_bready  = 0 ;
   m00_axi_lite.axi_araddr  = 0 ;
   m00_axi_lite.axi_arprot  = 0 ;
   m00_axi_lite.axi_arvalid = 0 ;
   m00_axi_lite.axi_rready  = 0 ;
   m01_axi_lite.axi_awaddr  = 0 ;
   m01_axi_lite.axi_awprot  = 0 ;
   m01_axi_lite.axi_awvalid = 0 ;
   m01_axi_lite.axi_wdata   = 0 ;
   m01_axi_lite.axi_wstrb   = 0 ;
   m01_axi_lite.axi_wvalid  = 0 ;
   m01_axi_lite.axi_bready  = 0 ;
   m01_axi_lite.axi_araddr  = 0 ;
   m01_axi_lite.axi_arprot  = 0 ;
   m01_axi_lite.axi_arvalid = 0 ;
   m01_axi_lite.axi_rready  = 0 ;
   m10_axi_lite.axi_awaddr  = 0 ;
   m10_axi_lite.axi_awprot  = 0 ;
   m10_axi_lite.axi_awvalid = 0 ;
   m10_axi_lite.axi_wdata   = 0 ;
   m10_axi_lite.axi_wstrb   = 0 ;
   m10_axi_lite.axi_wvalid  = 0 ;
   m10_axi_lite.axi_bready  = 0 ;
   m10_axi_lite.axi_araddr  = 0 ;
   m10_axi_lite.axi_arprot  = 0 ;
   m10_axi_lite.axi_arvalid = 0 ;
   m10_axi_lite.axi_rready  = 0 ;
   m11_axi_lite.axi_awaddr  = 0 ;
   m11_axi_lite.axi_awprot  = 0 ;
   m11_axi_lite.axi_awvalid = 0 ;
   m11_axi_lite.axi_wdata   = 0 ;
   m11_axi_lite.axi_wstrb   = 0 ;
   m11_axi_lite.axi_wvalid  = 0 ;
   m11_axi_lite.axi_bready  = 0 ;
   m11_axi_lite.axi_araddr  = 0 ;
   m11_axi_lite.axi_arprot  = 0 ;
   m11_axi_lite.axi_arvalid = 0 ;
   m11_axi_lite.axi_rready  = 0 ;
   
   
   case (reg_bank)
      2'b00  : begin
         m00_axi_lite.axi_awaddr  = s_axi_lite.axi_awaddr  ;
         m00_axi_lite.axi_awprot  = s_axi_lite.axi_awprot  ;
         m00_axi_lite.axi_awvalid = s_axi_lite.axi_awvalid ;
         m00_axi_lite.axi_wdata   = s_axi_lite.axi_wdata   ;
         m00_axi_lite.axi_wstrb   = s_axi_lite.axi_wstrb   ;
         m00_axi_lite.axi_wvalid  = s_axi_lite.axi_wvalid  ;
         m00_axi_lite.axi_bready  = s_axi_lite.axi_bready  ;
         m00_axi_lite.axi_araddr  = s_axi_lite.axi_araddr  ;
         m00_axi_lite.axi_arprot  = s_axi_lite.axi_arprot  ;
         m00_axi_lite.axi_arvalid = s_axi_lite.axi_arvalid ;
         m00_axi_lite.axi_rready  = s_axi_lite.axi_rready  ;

         s_axi_lite.axi_awready   = m00_axi_lite.axi_awready;
         s_axi_lite.axi_arready   = m00_axi_lite.axi_arready;
         s_axi_lite.axi_bresp     = m00_axi_lite.axi_bresp  ;
         s_axi_lite.axi_bvalid    = m00_axi_lite.axi_bvalid ;
         s_axi_lite.axi_wready    = m00_axi_lite.axi_wready ;
         s_axi_lite.axi_rdata     = m00_axi_lite.axi_rdata  ;
         s_axi_lite.axi_rresp     = m00_axi_lite.axi_rresp  ;
         s_axi_lite.axi_rvalid    = m00_axi_lite.axi_rvalid ;
      end
      2'b01  : begin
         m01_axi_lite.axi_awaddr  = s_axi_lite.axi_awaddr  ;
         m01_axi_lite.axi_awprot  = s_axi_lite.axi_awprot  ;
         m01_axi_lite.axi_awvalid = s_axi_lite.axi_awvalid ;
         m01_axi_lite.axi_wdata   = s_axi_lite.axi_wdata   ;
         m01_axi_lite.axi_wstrb   = s_axi_lite.axi_wstrb   ;
         m01_axi_lite.axi_wvalid  = s_axi_lite.axi_wvalid  ;
         m01_axi_lite.axi_bready  = s_axi_lite.axi_bready  ;
         m01_axi_lite.axi_araddr  = s_axi_lite.axi_araddr  ;
         m01_axi_lite.axi_arprot  = s_axi_lite.axi_arprot  ;
         m01_axi_lite.axi_arvalid = s_axi_lite.axi_arvalid ;
         m01_axi_lite.axi_rready  = s_axi_lite.axi_rready  ;

         s_axi_lite.axi_awready   = m01_axi_lite.axi_awready;
         s_axi_lite.axi_arready   = m01_axi_lite.axi_arready;
         s_axi_lite.axi_bresp     = m01_axi_lite.axi_bresp  ;
         s_axi_lite.axi_bvalid    = m01_axi_lite.axi_bvalid ;
         s_axi_lite.axi_wready    = m01_axi_lite.axi_wready ;
         s_axi_lite.axi_rdata     = m01_axi_lite.axi_rdata  ;
         s_axi_lite.axi_rresp     = m01_axi_lite.axi_rresp  ;
         s_axi_lite.axi_rvalid    = m01_axi_lite.axi_rvalid ;
      end
      2'b10  : begin
         if (OUTS > 2 ) begin
            m10_axi_lite.axi_awaddr  = s_axi_lite.axi_awaddr  ;
            m10_axi_lite.axi_awprot  = s_axi_lite.axi_awprot  ;
            m10_axi_lite.axi_awvalid = s_axi_lite.axi_awvalid ;
            m10_axi_lite.axi_wdata   = s_axi_lite.axi_wdata   ;
            m10_axi_lite.axi_wstrb   = s_axi_lite.axi_wstrb   ;
            m10_axi_lite.axi_wvalid  = s_axi_lite.axi_wvalid  ;
            m10_axi_lite.axi_bready  = s_axi_lite.axi_bready  ;
            m10_axi_lite.axi_araddr  = s_axi_lite.axi_araddr  ;
            m10_axi_lite.axi_arprot  = s_axi_lite.axi_arprot  ;
            m10_axi_lite.axi_arvalid = s_axi_lite.axi_arvalid ;
            m10_axi_lite.axi_rready  = s_axi_lite.axi_rready  ;
            s_axi_lite.axi_awready   = m10_axi_lite.axi_awready;
            s_axi_lite.axi_arready   = m10_axi_lite.axi_arready;
            s_axi_lite.axi_bresp     = m10_axi_lite.axi_bresp  ;
            s_axi_lite.axi_bvalid    = m10_axi_lite.axi_bvalid ;
            s_axi_lite.axi_wready    = m10_axi_lite.axi_wready ;
            s_axi_lite.axi_rdata     = m10_axi_lite.axi_rdata  ;
            s_axi_lite.axi_rresp     = m10_axi_lite.axi_rresp  ;
            s_axi_lite.axi_rvalid    = m10_axi_lite.axi_rvalid ;
         end else begin
            s_axi_lite.axi_awready   = awready;
            s_axi_lite.axi_arready   = arready;
            s_axi_lite.axi_bresp     = 0;
            s_axi_lite.axi_bvalid    = bvalid;
            s_axi_lite.axi_wready    = wready ;
            s_axi_lite.axi_rdata     = 0 ;
            s_axi_lite.axi_rresp     = 0 ;
            s_axi_lite.axi_rvalid    = rvalid ;
         end
      end
      2'b11  : begin
         if (OUTS > 3 ) begin
            m11_axi_lite.axi_awaddr  = s_axi_lite.axi_awaddr  ;
            m11_axi_lite.axi_awprot  = s_axi_lite.axi_awprot  ;
            m11_axi_lite.axi_awvalid = s_axi_lite.axi_awvalid ;
            m11_axi_lite.axi_wdata   = s_axi_lite.axi_wdata   ;
            m11_axi_lite.axi_wstrb   = s_axi_lite.axi_wstrb   ;
            m11_axi_lite.axi_wvalid  = s_axi_lite.axi_wvalid  ;
            m11_axi_lite.axi_bready  = s_axi_lite.axi_bready  ;
            m11_axi_lite.axi_araddr  = s_axi_lite.axi_araddr  ;
            m11_axi_lite.axi_arprot  = s_axi_lite.axi_arprot  ;
            m11_axi_lite.axi_arvalid = s_axi_lite.axi_arvalid ;
            m11_axi_lite.axi_rready  = s_axi_lite.axi_rready  ;
         
            s_axi_lite.axi_awready   = m11_axi_lite.axi_awready;
            s_axi_lite.axi_arready   = m11_axi_lite.axi_arready;
            s_axi_lite.axi_bresp     = m11_axi_lite.axi_bresp  ;
            s_axi_lite.axi_bvalid    = m11_axi_lite.axi_bvalid ;
            s_axi_lite.axi_wready    = m11_axi_lite.axi_wready ;
            s_axi_lite.axi_rdata     = m11_axi_lite.axi_rdata  ;
            s_axi_lite.axi_rresp     = m11_axi_lite.axi_rresp  ;
            s_axi_lite.axi_rvalid    = m11_axi_lite.axi_rvalid ;
         end else begin
            s_axi_lite.axi_awready   = awready;
            s_axi_lite.axi_arready   = arready;
            s_axi_lite.axi_bresp     = 0;
            s_axi_lite.axi_bvalid    = bvalid;
            s_axi_lite.axi_wready    = wready ;
            s_axi_lite.axi_rdata     = 0 ;
            s_axi_lite.axi_rresp     = 0 ;
            s_axi_lite.axi_rvalid    = rvalid ;
         end
      end
   endcase
   
   
end
endgenerate

// RESPONSE
reg arready, awready, wready, rvalid, bvalid;
always_ff @ (posedge ps_aclk, negedge ps_aresetn) begin
   if (!ps_aresetn) begin         
      arready <= 1'b0 ;
      awready <= 1'b0 ;
      wready  <= 1'b0 ;
      rvalid <= 1'b0 ;
      bvalid <= 1'b0 ;
   end else begin
      if (s_axi_lite.axi_arvalid) 
         arready <= 1'b1 ;
      else if (s_axi_lite.axi_awvalid) 
         awready <= 1'b1 ;
      else if (s_axi_lite.axi_wvalid)
         wready <= 1'b1 ;
      else begin
         arready <= 1'b0 ;
         awready <= 1'b0 ;
         wready  <= 1'b0 ;
      end
      if (arready)          
         rvalid <= 1'b1 ;
      if (rvalid & s_axi_lite.axi_rready)         
         rvalid <= 1'b0 ;
      if (wready)          
         bvalid <= 1'b1 ;
      if (bvalid & s_axi_lite.axi_bready)         
         bvalid <= 1'b0 ;
   end
end // Always

/*
generate
   case(OUTS)
      2: begin
         assign s_axi_lite.axi_awready = m00_axi_lite.axi_awready|m01_axi_lite.axi_awready;
         assign s_axi_lite.axi_arready = m00_axi_lite.axi_arready|m01_axi_lite.axi_arready;
      end
      3: begin
         assign s_axi_lite.axi_awready = m00_axi_lite.axi_awready|m01_axi_lite.axi_awready|m10_axi_lite.axi_awready;
         assign s_axi_lite.axi_arready = m00_axi_lite.axi_arready|m01_axi_lite.axi_arready|m10_axi_lite.axi_arready;
      end
      4: begin
         assign s_axi_lite.axi_awready = m00_axi_lite.axi_awready|m01_axi_lite.axi_awready|m10_axi_lite.axi_awready|m11_axi_lite.axi_awready;
         assign s_axi_lite.axi_arready = m00_axi_lite.axi_arready|m01_axi_lite.axi_arready|m10_axi_lite.axi_arready|m11_axi_lite.axi_arready;
      end
   endcase
endgenerate
*/


   

endmodule

