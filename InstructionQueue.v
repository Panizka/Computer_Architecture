module instruction_queue(
input wire clock,
input wire issue_error,
input wire adder_available,
input wire [5:0] adder_RS_available,
input wire [5:0] RS_issued,
input wire [5:0] RS_executing_adder,
input wire adder_rts,
input wire [5:0] RS_finished,
output reg [5:0] operation,
output reg [2:0] execution_unit,
output reg [4:0] Dest_address, 
output reg [4:0] A_address, 
output reg [4:0] B_address,
output reg issue
);

parameter TRUE =1'b1;
parameter FALSE =1'b0;
parameter LAST_INSTRUCTION_ELEMENT = 1023;
parameter INSTRUCTION_ADDRESS_BITS = 10;
parameter LAST_QUEUE_ELEMENT = 7;
parameter QUEUE_ADDRESS_BITS = 3;
parameter CLEAR =0;
parameter OPCODE_HIGH      = 31;
parameter OPCODE_LOW       = 26;
parameter EXEC_UNIT_HIGH      = 31;
parameter EXEC_UNIT_LOW       = 29;
parameter SOURCE1_HIGH     = 25;
parameter SOURCE1_LOW      = 21;
parameter SOURCE2_HIGH     = 20;
parameter SOURCE2_LOW      = 16;
parameter DESTINATION_HIGH = 15;
parameter DESTINATION_LOW  = 11;
parameter BUSY_MASK = 4'b0001;
parameter ISSUE_MASK = 4'b0010;
parameter EXECUTE_MASK = 4'b0100;
parameter WRITE_BACK_MASK = 4'b1000;
parameter ADDER= 3'b000;
parameter alu_add = 3'b000;
parameter alu_sub = 3'b001;
parameter alu_or  = 3'b100;
parameter alu_and = 3'b101;
parameter alu_not = 3'b110;
parameter alu_xor = 3'b111;
parameter FETCHED = 4'b0001;
parameter ISSUED = 4'b0011;
parameter EXECUTED = 4'b0111;
parameter CLEARED = 4'b1111;
parameter FULL = 3'b111;


integer i,j;

reg issued_this_clock = 0;
reg [31:0] Instruction_Memory [LAST_INSTRUCTION_ELEMENT:0];
reg [INSTRUCTION_ADDRESS_BITS:0] PC=0;
reg next_queue_location;
reg [31:0] Instruction [LAST_QUEUE_ELEMENT:0];
reg [5:0] RS_Holding [LAST_QUEUE_ELEMENT:0];
reg [3:0] Status [LAST_QUEUE_ELEMENT:0];
reg [QUEUE_ADDRESS_BITS-1:0] Queue_End = CLEAR;


reg [QUEUE_ADDRESS_BITS-1:0] issue_index;
reg [QUEUE_ADDRESS_BITS-1:0] execute_index;
reg [QUEUE_ADDRESS_BITS-1:0] write_back_index;
reg [QUEUE_ADDRESS_BITS-1:0] cleanup_index;


initial
begin
    issue<=FALSE;
    for(i=0;i<=LAST_QUEUE_ELEMENT;i=i+1)
    begin
        Instruction[i] <= CLEAR;
        RS_Holding[i] <= CLEAR;
        Status[i] <= CLEAR;
    end
    for(i=0;i<=32;i=i+1)
    begin
        Instruction_Memory[i] <= {ADDER, alu_add, 
		  5'b00001,  5'b00011, 5'b00111, 11'b0};
    end
end

// fetch
always@(posedge clock)
begin
   if(Status[7] != FETCHED) begin
      Instruction[Queue_End]<=Instruction_Memory[PC];
      Status[Queue_End]<=BUSY_MASK;
      PC<=PC+1;
      Queue_End<=Queue_End+1;
   end
end

// issue
always@(posedge clock)
begin
   if (adder_available) begin
      operation<=Instruction[issue_index][OPCODE_HIGH:OPCODE_LOW];
      execution_unit<=Instruction[issue_index][EXEC_UNIT_HIGH:EXEC_UNIT_LOW];
      Dest_address<=Instruction[issue_index][DESTINATION_HIGH:DESTINATION_LOW];
      A_address<=Instruction[issue_index][SOURCE1_HIGH:SOURCE1_LOW];
      B_address<=Instruction[issue_index][SOURCE2_HIGH:SOURCE2_LOW];
      issue<=TRUE;
      issued_this_clock<=TRUE;
      RS_Holding[issue_index]<=adder_RS_available;
      Status[issue_index]<=Status[issue_index] + ISSUE_MASK;
  end
end

// generating issue negation pulses
always@(posedge issue)
begin
   #1;
   issue<=FALSE;
   issued_this_clock<=FALSE;
end

// update
always@(posedge clock)
begin
   if (RS_executing_adder != CLEAR)
      Status[execute_index] <= Status[execute_index] + EXECUTE_MASK;
end

// write
always@(posedge clock)
begin
   if (RS_finished != CLEAR) begin
      Status[write_back_index] <= Status[write_back_index] + WRITE_BACK_MASK;
      cleanup_index <= write_back_index;
   end
end

// cleanup
always@(negedge clock)
begin
   for(i = 0 ; i < LAST_QUEUE_ELEMENT; i = i+1) begin
      if(Status[i] == FETCHED) 
         issue_index<=i; 
      if(Status[i] == ISSUED)
        execute_index<=i;
	   if(Status[i] == EXECUTED)
        write_back_index<=i;
	   if(Status[i] == CLEARED) begin
         for(j = i; j < LAST_QUEUE_ELEMENT; j = j + 1) begin
            Instruction[j] <= Instruction[j + 1];
            RS_Holding[j] <= RS_Holding[j + 1];
            Status[j] <= Status[j + 1];
         end
         Instruction[LAST_QUEUE_ELEMENT]<=CLEAR;
         RS_Holding[LAST_QUEUE_ELEMENT]<=CLEAR;
         Status[LAST_QUEUE_ELEMENT]<=CLEAR;
         Queue_End<=Queue_End - 1;
         issue_index<=i;
         i=LAST_QUEUE_ELEMENT;
      end
   end
end

endmodule
