# Function of This Program
The purpose of this program is to take in external data through the I2S protocol. Later, that data is sent to an FIR filter. Finally, the filtered data is sent back out through the same I2S protocol.

### This is done accordingly:
![image](https://github.com/user-attachments/assets/67ba868f-7f1e-4362-a067-ea02bd34c124)

The process begins with programming the PMOD I2S2 to recieve and transmit data as shown initially in the flowchart. Once the data is being recieved into the FPGA, we direct it to the FIR filter. This filter is also binded to a switch which allows you to specifically select which type of filter is being operated. Finally, the data is exported back to the PMOD I2S2 to play it through the line out port.
