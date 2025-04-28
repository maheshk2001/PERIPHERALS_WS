module UART_Rx(DataOut,SerialInputData,CLK_Baudin,RstRx,Flag_Rx); // Module of UART Receiver.

	parameter IDLE = 1'b0, RECEIVE = 1'b1; //Coding the states for easy access.
	parameter size = 32; //No of Data Bits;
	
	input SerialInputData; // Data that comes as a input to the block.
	input CLK_Baudin,RstRx; // Baudclk and Reset inputs to the block.
	
	output reg [size-1:0] DataOut; // The accumilated data that is size bits long is the output.
	output reg DoneRx; // A Register that will be asserted when receiving is successful.
	output reg Flag_Rx;//A Flag Value to trigger resending the data.
	
	reg STATE; //Register to hold current state values.
	reg [$clog2(size)+1:0]counter; // Counter to keep track of no of bits.
	reg Paritygen_rstR; 
	// Pin which holds value to reset the parity generation block.
	
	wire Parity_Rx;
	
	paritygen parity2 (.ip(DataOut[size-1]),
						.clk(CLK_Baudin),
						.rst_p(Paritygen_rstR),
						.parity(Parity_Rx)); // Instantiating the parity generator module for parity bit generation. 
	
	always @(posedge CLK_Baudin or posedge RstRx)
	begin
		if (RstRx) // If reset is asserted we set the entire system to default state.
		begin
			DataOut <= {size{1'b0}};
		end
		
		else // We will enter the FSM for further steps.
		begin
		
			case (STATE)
			IDLE : begin // IDLE state defnition is similar to reset. We remain in IDLE until we detect the start bit(1'b0).
				DataOut <= {size{1'b0}};
				if(SerialInputData == 1'b0)
				begin //If start bit is found then we go to RECEIVE state.
					DataOut <={size{1'b0}};
					STATE <= RECEIVE;
					counter <= counter+1;
				end
				else begin
					DataOut <={size{1'b0}};
					STATE <= IDLE;
				end
			end
			
			RECEIVE :begin // Receiving the Data because we found the start bit.
				if(counter <= size) begin
					counter <= counter + 1;
					Dataout[size-1] <= SerialInputData;
					Dataout <= DataOut >>1;
				end
				
				else if(counter == size+1)begin
					if(Parity_Rx != SerialInputData) begin
						STATE <= IDLE ;
					end
					
					else if 
					
				end
			
			end
			
			endcase
		end
	end
	
endmodule