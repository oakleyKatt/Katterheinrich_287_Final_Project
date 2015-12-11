module Register (
	input clock, rst, write,
	input [1:0] WrAddrA, RdAddrA,
	input [3:0] WrDataA,
	output [3:0] RdDataA
	);
	reg [3:0] reg0, reg1, reg2, reg3;	//0(left) -> 3(right) Brick in row
	
	// Set first memory block to always be zero
	initial
	begin
		reg0 <= 0;
	end
	
	// Use conditional logic to assign the value stored at the RdAddress
	// of the two read Buses		00-row0, 01-row1,...
	assign RdDataA = RdAddrA == 2'b00 ? reg0 :
						  RdAddrA == 2'b01 ? reg1 :
						  RdAddrA == 2'b10 ? reg2 :
						  RdAddrA == 2'b11 ? reg3 : 0;

	// On clock cycles if the write bit is high, then change the register
	// at specified address to the new data value
	always @ (posedge clock)
	begin
		if(rst==1'b1)
		begin
			reg0<=4'b0000;
			reg1<=4'b0000;
			reg2<=4'b0000;
			reg3<=4'b0000;
		end
		else
		begin
		if (write)
		begin
			case (WrAddrA)
//				2'b00 : begin
//					reg0 <= WrDataA;
//				end
				2'b01 : begin
					//reg1<=WrDataA;
					reg1<=reg1+WrDataA;
				end
				2'b10 : begin
					reg2<=reg2+WrDataA;
				end
				2'b11 : begin
					reg3<=reg3+WrDataA;
				end
			endcase
		end
		end
	end
	
endmodule
