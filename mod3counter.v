`timescale 1ns / 1ps

module mod3counter(
	input wire [1:0] num,
	output reg [1:0] mod3num
    );
	 
	 always@*
	 begin
	 case(num)
		0: mod3num = 2'b01;
		1: mod3num = 2'b10;
		2: mod3num = 2'b00;
		default: mod3num = 2'b00;
	 endcase
	 end


endmodule
