module UART_Rx(DataOut, DoneRx, SerialInputData, CLK_Baudin, RstRx, Flag_Rx, DoneTx); // Module of UART Receiver.

	parameter IDLE = 2'b00, RECEIVE = 2'b01, STOP = 2'b10; // Coding the states for easy access.
	parameter size = 32; // No of Data Bits;
	
	input SerialInputData; // Data that comes as a input to the block.
	input CLK_Baudin, RstRx; // Baudclk and Reset inputs to the block.
	input DoneTx; // Added DoneTx input
	
	output reg [size-1:0] DataOut; // The accumulated data that is size bits long is the output.
	output reg DoneRx; // A Register that will be asserted when receiving is successful.
	output reg Flag_Rx; // A Flag Value to trigger resending the data.
	
	reg [1:0] STATE; // Register to hold current state values.
	reg [$clog2(size)+1:0] counter; // Counter to keep track of no of bits.
	reg Paritygen_rstR; // Pin which holds value to reset the parity generation block.
	reg [size-1:0] shift_reg; // Shift register to store incoming data
	
	wire Parity_Rx;
	
  paritygen parity2 (.ip(SerialInputData),
						.clk(CLK_Baudin),
						.rst_p(Paritygen_rstR),
						.parity(Parity_Rx)); // Instantiating the parity generator module for parity bit generation. 
	
	always @(posedge CLK_Baudin or posedge RstRx)
	begin
		if (RstRx) // If reset is asserted we set the entire system to default state.
		begin
			DataOut <= {size{1'b0}};
			shift_reg <= {size{1'b0}};
			counter <= 0;
			STATE <= IDLE;
			DoneRx <= 1'b0;
			Flag_Rx <= 1'b0;
			Paritygen_rstR <= 1'b1;
		end
		
		else // We will enter the FSM for further steps.
		begin
			case (STATE)
			IDLE : begin // IDLE state definition is similar to reset. We remain in IDLE until we detect the start bit(1'b0).
				
				shift_reg <= {size{1'b0}};
				DataOut <= shift_reg; // Do not clear DataOut in IDLE
				counter <= 1'b0;
				Flag_Rx <= 1'b0;
				Paritygen_rstR <= 1'b1;
                DoneRx <=1'b0;
                
				
				if(SerialInputData == 1'b0) // If start bit is found
                  begin
					STATE <= RECEIVE;
					Paritygen_rstR <= 1'b0;
					DoneRx <= 1'b0; // Clear DoneRx on new reception
					counter <= 1'b1;
                    Flag_Rx <= 1'b0;
				end
				else begin
					STATE <= IDLE;
					counter <= 1'b0;
				end
			end
			
			RECEIVE : begin // Receiving the Data because we found the start bit.
              if(counter <= size) begin
                shift_reg <= {SerialInputData, shift_reg[size-1:1]};
                //shift_reg[counter-1] <= SerialInputData;
				counter <= counter + 1;
				//STATE <= RECEIVE;
                //DoneRx <= 1'b0;
                //Flag_Rx <= 1'b0;
                //Paritygen_rstR <= 1'b0;
                   
				end
			  else if(counter == size+1) begin
                    $display("[RX] Checking parity: calculated=%b, received=%b at time %0t", Parity_Rx, SerialInputData, $time);
                   if(Parity_Rx != SerialInputData) begin
						Flag_Rx <= 1'b1; // Request for retransmission
						shift_reg <={size{1'b0}}; //flushing the reg if there is a mismatch
                        DataOut <= shift_reg;
						STATE <= IDLE;
                        DoneRx <=0;
                        counter <= 1'b0;
				    end
				   else begin
						Flag_Rx <= 1'b0;
						DataOut <= shift_reg;
						STATE <= STOP;
                        counter <= counter +1;
                        //Paritygen_rstR <= 1'b0;
                        //DoneRx <= 1'b0;
                    end
				end
			end
			
			
			STOP: begin
              if(counter == size +2) begin
                STATE <= IDLE;
                //DataOut <= shift_reg;
				DoneRx <= 1'b1; // Latch DoneRx when data is received
				//counter <= counter+1;
                Flag_Rx <= 1'b0;
                    //$display("[RX] Stop bit detected, DoneRx set HIGH at time %0t\", $time);
			  end 
              else begin
                counter <= counter+1;
                  
              end
			end
			default : begin
				STATE <= IDLE;
			end
			endcase
        end
    end
			
			// Clear Flag_Rx only when TX acknowledges retransmission
          always @(posedge CLK_Baudin) begin
          	if (Flag_Rx && DoneTx) begin
				Flag_Rx <= 1'b0;
            end
		  end
		
	
endmodule
