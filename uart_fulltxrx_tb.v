`timescale 1ns/1ps

module uart_full_tb;
    parameter size = 32;
    reg CLK_Baudin;
    reg RstTx, RstRx;
    reg NewData;
    reg [size-1:0] DataIn;
    wire [size-1:0] DataOut;
    wire TransmittedSerialData;
    wire DoneTx, DoneRx;
    wire Flag_Rx; // Only driven by RX module

    // For reconstructing received data
    reg [size-1:0] received_data;
    reg [5:0] bit_count, bit_count1;
    reg receiving;
    reg loop;

    reg force_parity_error;

    // Instantiate UART_Tx
    UART_Tx uut_tx (
        .TransmittedSerialData(TransmittedSerialData),
        .DoneTx(DoneTx),
        .DataIn(DataIn),
        .CLK_Baudin(CLK_Baudin),
        .RstTx(RstTx),
        .NewData(NewData),
        .Flag_in(Flag_Rx),
        .force_parity_error(force_parity_error)
    );

    // Instantiate UART_Rx
    UART_Rx uut_rx (
        .DataOut(DataOut),
        .DoneRx(DoneRx),
        .SerialInputData(TransmittedSerialData),
        .CLK_Baudin(CLK_Baudin),
        .RstRx(RstRx),
        .Flag_Rx(Flag_Rx),
        .DoneTx(DoneTx)
    );

    // Clock generation
    initial begin
        CLK_Baudin = 0;
        forever #50 CLK_Baudin = ~CLK_Baudin; // 100ns period
    end

    // Test sequence
    initial begin
        $dumpfile("uart_full_tb.vcd");
        $dumpvars(0, uart_full_tb);
        RstTx = 1;
        RstRx = 1;
        NewData = 0;
        DataIn = 0;
        received_data = 0;
        bit_count = 0;
        bit_count1 = 0;
        receiving = 0;
        loop = 0;
        force_parity_error = 1; // Inject parity error for first frame
        #200;
        RstTx = 0;
        RstRx = 0;
        #100;
        DataIn = 32'hA5A5F0F0;
        start_transmission();
        wait (DoneRx == 1);
        force_parity_error = 0; // Normal for next frame
        #200;
        $display("[TB] DataOut = %h, Flag_Rx = %b, DoneRx = %b", DataOut, Flag_Rx, DoneRx);
        #1000;
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
        bit_count1 = 0;
        loop = 0;
    end
    endtask

    parameter TOTAL_BITS = 34;

    // Monitor received data and inject parity error flag
    always @(posedge CLK_Baudin) begin
        if (TransmittedSerialData == 0 && receiving == 0) begin
            // Detect start bit
            receiving <= 1;
            bit_count <= 0;
            received_data <= 0;
            bit_count1 <= 0;
        end else if (receiving) begin
            if (bit_count < 32) begin
                received_data <= {TransmittedSerialData, received_data[31:1]};
                bit_count <= bit_count + 1;
                bit_count1 <= bit_count1 + 1;
            end else if (bit_count < TOTAL_BITS) begin
                // Counting parity and stop bits
                bit_count <= bit_count + 1;
                bit_count1 <= bit_count1 + 1;
                // Inject parity error flag during parity/stop bit
                if(loop == 0 && bit_count1 == 32) begin
                    loop <= loop + 1;
                end
            end else begin
                // Done receiving entire frame
                receiving <= 0;
                bit_count <= 0;
                bit_count1 <= 0;
            end
        end
    end

    // Monitor transmission
    always @(posedge CLK_Baudin) begin
        $display("Time %0t: Tx = %b, DoneTx = %b, DoneRx = %b, Flag_Rx = %b, DataOut = %h", $time, TransmittedSerialData, DoneTx, DoneRx, Flag_Rx, DataOut);
    end
endmodule 