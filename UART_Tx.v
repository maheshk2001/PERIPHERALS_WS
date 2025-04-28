module UART_Tx(TransmittedSerialData,DoneTx,DataIn,CLK_Baudin,RstTx,NewData,Flag_in); // Module of UART Transmitter.
	
	parameter IDLE = 2'b00, TRANSFER = 2'b01, PARITY = 2'b10;// Coding the States for easy access.
	parameter size = 32; // No of Data Bits.
	
	input [size-1:0]DataIn; // Data that comes as a input to the block is stored here.
	input CLK_Baudin,RstTx,NewData; // NewData,Baudclk and Reset inputs to block.
  	input Flag_in;//Flag from receiver.
	
	output reg TransmittedSerialData; // The serial Data Transmitted as output of the block.
	output reg DoneTx; //A register that will be asserted when the transmission is successful.
	
	reg [size-1:0]shift; // A register to store intermidiate values and used for shift operation.
	reg [$clog2(size)+1:0]counter; // Counter to keep track of no of Bits.
	reg [1:0]STATE; // A register to hold current state values.
	reg Paritygen_rst; // Pin which holds value to reset the parity generation block.
	
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
			STATE <= IDLE ;
			DoneTx <= 1'b0;
			Paritygen_rst <= 1'b1;
		end
		else // We will enter the FSM for futher steps.
		begin
			case(STATE)
			IDLE : begin // IDLE State defnition is similar to reset. We remain in IDLE until NewData is asserted.
				TransmittedSerialData <= 1'b1;
				counter <= 0;
				Paritygen_rst <= 1'b1;
				shift <= {size{1'b0}};
				if (NewData) // If there is NewData then we shift the DataIn into a Reg named shift.
				begin
					Paritygen_rst<=1'b1;
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
				end
				
				else if (counter != 0 & counter <= size) begin // Transmitting DataIn serially into TransmittedSerialData.
					TransmittedSerialData <= shift[0];
					shift <= shift >> 1;
					counter <= counter + 1;
					STATE <= TRANSFER;
				end
				
				else if (counter == size+1) begin // Transmitting the Parity bit.
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
				end
				
				else begin //Returning to IDLE to Resend Data.
					STATE <= TRANSFER ;
					DoneTx <= 1'b0;
					Paritygen_rst <= 1'b0;
					counter <= 1;
				end
			end
			
			default : begin // Default STATE value is to set the FSM to IDLE.
				STATE <= IDLE;
				Paritygen_rst<=1'b1;
			end
			endcase
		end
	end
endmodule
