`timescale 1ns / 1ps
module vect2bits_9(
    input [159:0] din,
    output dout0,
    output dout1,
    output dout2,
    output dout3,
	output dout4,
	output dout5,
	output dout6,
	output dout7,
	output dout8
    );

	assign dout0 = din[0];
	assign dout1 = din[1];
	assign dout2 = din[2];
	assign dout3 = din[3];
	assign dout4 = din[4];
	assign dout5 = din[5];
	assign dout6 = din[6];
	assign dout7 = din[7];
	assign dout8 = din[8];
endmodule
