module Tomasulo;

   parameter clock_period = 10;
   parameter TRUE = 1'b1;
   parameter FALSE = 1'b0;

   reg clock;

   wire available, issue, error;

   wire [2:0] exec_unit; 
   wire [5:0] opcode;
   wire [4:0] A_address, B_address, Dest_address;
   wire signed [31:0] A, B;
   wire A_invalid, B_invalid;

   wire [5:0] RS_available;
   wire [5:0] RS_issued;
   wire [5:0] RS_executing;
   wire [5:0] RS_finished;
   
   wire CDB_rts;
   
   wire signed [31:0] CDB_data;
   wire CDB_write; 
   reg  CDB_xmit = FALSE;  
	
   always begin
      clock = 1'b0;
      #clock_period;
      clock = 1'b1;
      #clock_period;
   end

   instruction_queue instruction_queue(
   .clock(clock),
   .issue_error(error),
   .adder_available(available),
   .adder_RS_available(RS_available),
   .RS_issued(RS_issued),
   .RS_executing_adder(RS_executing),
   .adder_rts(CDB_rts),
   .RS_finished(RS_finished),
   .operation(opcode),
   .execution_unit(exec_unit),
   .Dest_address(Dest_address), 
   .A_address(A_address), 
   .B_address(B_address),
   .issue(issue)
   );

   Registers register_file(
   .clock(clock), 
   .issue(issue),
   .A_address(A_address),
   .B_address(B_address), 
   .dest(Dest_address),
   .In_data(CDB_data),
   .In_source(RS_finished), 
   .RS_calculating_value(RS_available),
   .write(CDB_write),
   .A_out(A), .B_out(B),
   .A_invalid(A_invalid),
   .B_invalid(B_invalid)
   );

   adders adder_unit(
   .clock(clock),
   .issue(issue),
   .A(A), .B(B),
   .A_invalid(A_invalid),
   .B_invalid(B_invalid),
   .opcode(opcode),
   .CDB_xmit(CDB_xmit),
   .CDB_data(CDB_data),
   .CDB_source(RS_finished),
   .CDB_write(CDB_write),
   .CDB_rts(CDB_rts),
   .available(available),
   .RS_available(RS_available),
   .issued(RS_issued),
   .RS_executing(RS_executing),
   .error(error)
   );


   always@(posedge clock)
   begin
      if (CDB_rts & ~CDB_xmit)
         CDB_xmit<=TRUE;
      else
         CDB_xmit<=FALSE;
   end

endmodule
