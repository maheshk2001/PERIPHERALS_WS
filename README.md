**# PERIPHERALS_WS
Peripherals Repository for Western Semiconductor.**
*********************************************************************************************************************************************************************************************************************************
**32 bit Full Duplex Asyunchronous Point to Point Serial UART Communication(16550A).**
*********************************************************************************************************************************************************************************************************************************

*********************************************************************************************************************************************************************************************************************************
**UART Transmitter**
*********************************************************************************************************************************************************************************************************************************
**Module PINS:** </br>
**UART Transmitter(UART_Tx) Inputs:** 32 bit Data Input (DataIn), A Baud Clock (CLK_Baudin), Reset Transmitter (RstTx) and New Data (NewData) as inputs to the block. </br>
**UART Transmitter (UART_Tx) Outputs:** Transmitted Data (TransmittedSerialData) and Done Transmission (DoneTx) as output from the block. </br>

**Pin Description:**  </br>
**DataIn** - The 32 bit binary input data that needs to be transmitted. </br>
**CLK_Baudin** - The clock signal at baud rate. </br>
**RstTx** - The signal used to reset the Transmitter Module. </br>
**NewData** - The signal indicating there is new data to transmit. </br>
**TransmittedSerialData** - The serial 1 bit data that will be sent to receiver. </br>
**DoneTx** - The signal indicating the transmission is Done at transmitter. </br>

**Description:**  </br>
We have to process the data before we transmit at the output.
By Default we have the TransmittedSerialData set to 1'b1 (HIGH).
When there is no new data we set the NewData to High. For the transmitter to start we send NewData and DataIn to the block. 
We need to append Start, Parity and Stop bits to the given DataIn. It makes our 32 bit data 35 bit long after appending the bits.
Then we transmit the complete 35 bit data in a serial format with LSB first.
The Start bit is 1'b0(LOW) for 1 CLK_Baudin cycle and then the Data gets transmitted 1 bit at a time. After the data is transmitted we calculate the parity bit. We transmit the value LOW or HIGH based on Even or Odd Parity respectively. We check the parity in receiver.
If the parity bit matches we go ahead with transmitting the Stop bit, but if the parity bit dosen't match then we resend the data again.


*********************************************************************************************************************************************************************************************************************************
**Parity Generator**
*********************************************************************************************************************************************************************************************************************************
**Module PINS:**  </br>
**Parity bit generator(paritygen) Inputs:** 1 bit Data input (ip), A Clock (clk), Reset parity block (rst_p) as inputs to the block. </br>
**Parity bit generator(paritygen) Output:** Parity output of accumilated data (parity) as output from the block. </br>

**Pin Description:**  </br>
**ip** - The 1 bit binary input data that needs to be XOR to parity. </br>
**clk**- The clock input signal. </br>
**rst_p** - The signal used to reset the paritygen Module. </br>
**NewData** - The signal indicating parity of accumilated bits. </br>

**Description:** </br>
We keep getting 1 bit data as input to the block. 
If reset is not asserted or 32 bits have not been counted we keep accumilating the parity bit with the previous data parity bit. This parity bit will be the output of the block.
This value being 1'b0 means we have a Even Parity. 
If the value is 1'b1 then we have Odd Parity.
This module uses an 2 bit XOR gate to calculte the parity bit instead of using an 32 bit XOR. This reduces the complexity and Size of Hardware when synthesizing. 
*********************************************************************************************************************************************************************************************************************************
**UART Receiver**
*********************************************************************************************************************************************************************************************************************************



