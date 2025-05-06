`timescale 1ns/1ps

module UART_Tx_tb;

    reg CLK_Baudin;
    reg RstTx;
    reg NewData;
    reg Flag_in;
    reg [31:0] DataIn;
    wire TransmittedSerialData;
    wire DoneTx;

    // For reconstructing received data
    reg [31:0] received_data;
  reg [5:0] bit_count,bit_count1;
    reg receiving;
  	reg loop;

    // Instantiate your UART_Tx
    UART_Tx uut (
        .TransmittedSerialData(TransmittedSerialData),
        .DoneTx(DoneTx),
        .DataIn(DataIn),
        .CLK_Baudin(CLK_Baudin),
        .RstTx(RstTx),
        .NewData(NewData),
        .Flag_in(Flag_in)
    );

    // Clock Generation (Baud clock)
    initial begin
        CLK_Baudin = 0;
        forever #50 CLK_Baudin = ~CLK_Baudin; // 100ns clock period
    end

    // Test sequence
    initial begin
        $dumpfile("UART_Tx_tb.vcd");
        $dumpvars(0, UART_Tx_tb);

        // Initialize inputs
        RstTx = 1;
        NewData = 0;
        Flag_in = 0;
        DataIn = 32'h0;
        received_data = 32'h0;
        bit_count = 0;
      	bit_count1 = 0;
        receiving = 0;
		loop = 0;
      
        #200;
        RstTx = 0; // Release reset

        #100;
        DataIn = 32'hA5A5F0F0; // Example 1
        start_transmission();
        wait (DoneTx == 1);
        #200;
 
      	DataIn = 32'hDEADBEEE; // Example 2
        start_transmission();
		wait (DoneTx == 1);
      	#200;
      
        DataIn = 32'hAEADBEEE; // Example 2
        start_transmission();
		wait (DoneTx == 1);
        

      	
        

        #7000;
        $finish;
    end

    // Task to start transmission
    task start_transmission;
    begin
        NewData = 1;
        #100;
        NewData = 0;
        receiving = 0;
        received_data = 0;
        bit_count = 0;
    end
    endtask

parameter TOTAL_BITS = 34;

always @(posedge CLK_Baudin) begin
    if (TransmittedSerialData == 0 && receiving == 0) begin
        // Detect start bit
        receiving <= 1;
        bit_count <= 0;
        received_data <= 0;
    end else if (receiving) begin
        if (bit_count < 32) begin
            received_data <= {TransmittedSerialData, received_data[31:1]};
            bit_count <= bit_count + 1;
        end else if (bit_count < TOTAL_BITS) begin
            // Counting parity and stop bits
            bit_count <= bit_count + 1;
        end else begin
            // Done receiving entire frame
            receiving <= 0;
            bit_count <= 0;
        end
    end
end
  
  always@(posedge CLK_Baudin) begin
    if (TransmittedSerialData == 0 && receiving == 0) begin
        // Detect start bit
        
        bit_count1 <= 0;
        
    end else if (receiving) begin
      if (bit_count1 < 32) begin
        		
            bit_count1 <= bit_count1 + 1;
      end else if (bit_count1 < TOTAL_BITS) begin
            // Counting parity and stop bits
            if(loop == 0) begin
					Flag_in<=1;
              		loop <= loop+1;
				end
				else begin
					Flag_in<=0;
				end
        	bit_count1 <= bit_count1 + 1;
        end else begin
            // Done receiving entire frame
            
            bit_count1 <= 0;
            
        end
    end
  end


    // Monitor transmission (optional for debug)
    always @(posedge CLK_Baudin) begin
        $display("Time %0t: Tx = %b, DoneTx = %b", $time, TransmittedSerialData, DoneTx);
    end

endmodule
