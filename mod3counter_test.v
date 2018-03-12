`timescale 1ns / 1ps

module mod3counter_test;

	// Inputs
	reg [1:0] num_in;

	// Outputs
	wire [1:0] num_out;

	// Instantiate the Unit Under Test (UUT)
	mod3counter uut (
		.num(num_in), 
		.mod3num(num_out)
	);

	initial
	begin
		num_in <=2;
		#10;
		num_in <=1;
		#10;
		num_in <=0;
		#10
		num_in <=5;
		#10;
	end
      
endmodule

