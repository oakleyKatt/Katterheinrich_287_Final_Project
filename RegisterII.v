module RegisterII (
	input clock, rst, write,
	input Addr,
	input [4:0] WrData,
	output [4:0] RdData
	);
	reg [4:0] reg0, reg1;	//points
	
	// Set first memory block to always be zero
	initial
	begin
		reg0 <= 0;
	end
	
	// Use conditional logic to assign the value stored at the RdAddress
	// of the two read Buses		00-row0, 01-row1,...
	assign RdData = Addr == 1'b0 ? reg0 :
						 Addr == 1'b1 ? reg1 : 0;
						  

	// On clock cycles if the write bit is high, then change the register
	// at specified address to the new data value
	always @ (posedge clock)
	begin
		if(rst==1'b1)
		begin
			reg0<=4'b0000;
			reg1<=4'b0000;
		end
		else
		begin
		if (write)
		begin
			case (Addr)
//				1'b0 : begin
//					reg0 <= WrData;
//				end
				1'b1 : begin
					reg1<=reg1+WrData;
				end
			endcase
		end
		end
	end
	
endmodule
