module paritygen(ip,clk,rst_p,parity);

	input ip,rst_p,clk; // input, reset and clock input signals.
	output reg parity; // output parity value.
	
	reg [5:0]counter;
	
	always @(posedge clk or posedge rst_p)
	begin
		if (rst_p or counter == 32) // When reset is asserted or 32 bits counted we set the reg to default values.
		begin
			parity <= 1'b0;
			counter <= 0;
		end
		else begin // When reset is not asserted then we bring in data for calcultion.  
		    parity <= ^{ip,parity};
			counter <= counter + 1;
		end
	end
	
endmodule



