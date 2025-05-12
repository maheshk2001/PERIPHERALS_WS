module UART_Tx(TransmittedSerialData,DoneTx,DataIn,CLK_Baudin,RstTx,NewData,Flag_in,force_parity_error); // Module of UART Transmitter.
	
	parameter IDLE = 2'b00, TRANSFER = 2'b01, PARITY = 2'b10;// Coding the States for easy access.
	parameter size = 32; // No of Data Bits.
	
	input [size-1:0]DataIn; // Data that comes as a input to the block is stored here.
	input CLK_Baudin,RstTx,NewData; // NewData,Baudclk and Reset inputs to block.
  	input Flag_in;//Flag from receiver.
    input force_parity_error;
	
	output reg TransmittedSerialData; // The serial Data Transmitted as output of the block.
	output reg DoneTx; //A register that will be asserted when the transmission is successful.
	
	reg [size-1:0]shift; // A register to store intermidiate values and used for shift operation.
  	reg [size-1:0]DataBuffer; // A Buffer to hold the data.
	reg [$clog2(size)+1:0]counter; // Counter to keep track of no of Bits.
	reg [1:0]STATE; // A register to hold current state values.
	reg Paritygen_rst; // Pin which holds value to reset the parity generation block.
	reg ReTransmit; // signal to retransmit the signal.
  
	wire Parity;//A register to hold Parity value.

	paritygen parity1(  .ip(shift[0]), 
						.clk(CLK_Baudin),
						.rst_p(Paritygen_rst), 
						.parity(Parity));// Instantiating the parity generator module for parity bit generation.
	
	always @(posedge CLK_Baudin or posedge RstTx)
	begin
		if (RstTx)// If reset is triggered we need to sent the pins to default values. We also make sure the STATE is initialized to IDLE to trigger FSM.
		begin
			TransmittedSerialData <= 1'b1;
			counter <= 0;
          	DataBuffer <= {size{1'b0}};
			STATE <= IDLE ;
			DoneTx <= 1'b0;
			Paritygen_rst <= 1'b1;
          	ReTransmit <= 1'b0;
		end
		else // We will enter the FSM for futher steps.
		begin
			case(STATE)
			
			IDLE : begin // IDLE State defnition is similar to reset. We remain in IDLE until NewData is asserted.
				TransmittedSerialData <= 1'b1;
				counter <= 0;
				Paritygen_rst <= 1'b1;
				shift <= {size{1'b0}};
				
              if (ReTransmit) begin // If flag we retransmit the data we saved in buffer.
                	Paritygen_rst<=1'b1;
                	shift <= DataBuffer;
                	STATE <= TRANSFER;
                	
              	end
              
              	else if (NewData) // If there is NewData then we shift the DataIn into a Reg named shift.
				begin
					Paritygen_rst<=1'b1;
                  	DataBuffer <= DataIn;
					shift <= DataIn;
					STATE <= TRANSFER;
				end
              
				else begin // Until NewData is asserted we wait for the data in IDLE state.
					STATE <= IDLE;
				end
			end
			
			TRANSFER : begin // Transmitting the start bit. 
				if (counter == 0) begin
					TransmittedSerialData <= 1'b0;
					counter <= counter + 1;
					STATE <= TRANSFER;
					DoneTx <= 1'b0;
					Paritygen_rst <= 1'b0;
                  	ReTransmit <= 1'b0;
				end
				
				else if (counter != 0 & counter <= size) begin // Transmitting DataIn serially into TransmittedSerialData.\
                    TransmittedSerialData <= shift[0];
					shift <= shift >> 1;
					counter <= counter + 1;
					STATE <= TRANSFER;
				end
				
				else if (counter == size+1) begin // Transmitting the Parity bit.
                  if(force_parity_error)
                    TransmittedSerialData <= ~Parity;
                  else
					TransmittedSerialData <= Parity;
					STATE <= PARITY;
					counter <= counter + 1 ;
				end
				
			end
			
			
			PARITY : begin
				if (Flag_in == 1'b0) begin //Transmitting the STOP bit.
					TransmittedSerialData <= 1'b1;
					STATE <= IDLE ;
					DoneTx <= 1'b1;
					Paritygen_rst <= 1'b0;
					counter <= 0;
                  	ReTransmit <=1'b0;
                  DataBuffer <= {size{1'b0}};
				end
				
				else begin //Returning to IDLE to Resend Data.
					STATE <= IDLE ;
					DoneTx <= 1'b0;
					Paritygen_rst <= 1'b1;
					counter <= 0;
                  	ReTransmit <= 1'b1;
				end
			end
			
			default : begin // Default STATE value is to set the FSM to IDLE.
				STATE <= IDLE;
				Paritygen_rst<=1'b1;
              	DoneTx <= 1'b0;
			end
			
			endcase
		end
	end
endmodule


module UART_Rx(DataOut, DoneRx, SerialInputData, CLK_Baudin, RstRx, Flag_Rx, DoneTx); // Module of UART Receiver.

	parameter IDLE = 2'b00, RECEIVE = 2'b01, PARITY = 2'b10; // Coding the states for easy access.
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
	
  paritygen parity2 (.ip(shift_reg[0]),
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
			//DoneRx <= 1'b0;
			Flag_Rx <= 1'b0;
			Paritygen_rstR <= 1'b1;
		end
		
		else // We will enter the FSM for further steps.
		begin
			case (STATE)
			IDLE : begin // IDLE state definition is similar to reset. We remain in IDLE until we detect the start bit(1'b0).
				
				shift_reg <= {size{1'b0}};
				//DataOut <= shift_reg; // Do not clear DataOut in IDLE
				counter <= 0;
				Flag_Rx <= 1'b0;
				Paritygen_rstR <= 1'b1;
				
				if(SerialInputData == 1'b0) // If start bit is found
				begin
					STATE <= RECEIVE;
					Paritygen_rstR <= 1'b0;
					DoneRx <= 1'b0; // Clear DoneRx on new reception
					counter <= counter + 1;
				end
				else begin
					STATE <= IDLE;
					counter <= 0;
				end
			end
			
			RECEIVE : begin // Receiving the Data because we found the start bit.
				if(counter !=0 & counter <= size) begin
					shift_reg <= {SerialInputData, shift_reg[size-1:1]};
					counter <= counter + 1;
					STATE <= RECEIVE;
                   
				end
				else if(counter == size+1) begin
                    if(Parity_Rx != SerialInputData) begin
						Flag_Rx <= 1'b1; // Request for retransmission
						shift_reg <={size{1'b0}}; //flushing the reg if there is a mismatch
                        DataOut <= shift_reg;
						STATE <= IDLE;
				    end
				    else begin
						Flag_Rx <= 1'b0;
						DataOut <= shift_reg;
						STATE <= PARITY;
                        //$display("T=%0t STATE=%b counter=%d shift_reg=%h DataOut=%h DoneRx=%b SerialInputData=%b Parity_Rx=%b", $time, STATE, counter, shift_reg, DataOut, DoneRx, SerialInputData, Parity_Rx);
				    end
                	DataOut <= shift_reg;
                  	STATE <= PARITY;
					
				end
			end
			
			
			PARITY: begin
				if(SerialInputData == 1'b1) begin
					STATE <= IDLE;
                    DataOut <= shift_reg;
					DoneRx <= 1'b1; // Latch DoneRx when data is received
					counter <= counter+1;
                    //$display("[RX] Stop bit detected, DoneRx set HIGH at time %0t\", $time);
				end else begin
                    DoneRx <= 0;
                end
			end
			default : begin
				STATE <= IDLE;
			end
			endcase
			
			// Clear Flag_Rx only when TX acknowledges retransmission
			if (Flag_Rx && DoneTx) begin
				Flag_Rx <= 1'b0;
			end
		end
	end
endmodule
