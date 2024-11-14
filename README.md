# Implementation
My implementation utilized this hardware:
- Zybo Z7-20 SoC
- PMOD I2S2

Reference Manual used:
- https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
- https://digilent.com/reference/pmod/pmodi2s2/reference-manual?srsltid=AfmBOop3qHp_o34WQPYizRe61k66GpRjQFFhaasx7XZ-JRVvNEcuCVIA

  All pins and clock divider values where derived from both of these reference manuals.

## Function of This Program:
This project implements the I2S protocol to receive audio input, processes it through various FIR filters derived from MATLAB, and then outputs the filtered audio via the same I2S protocol. Timing closure was achieved by pipelining the FIR filter stages.

## Features
- Supports stereo audio input via I2S protocol
- Configurable 64-tap FIR filter with fixed-point coefficients
- Pipelined architecture for high throughput
- Written in Verilog HDL with comprehensive testbenches

## Video of program functioning:
Still have not recorded a functioning video.

## Block Diagram:
![image](https://github.com/user-attachments/assets/67ba868f-7f1e-4362-a067-ea02bd34c124)

The process begins with building the I2S protocol for the PMOD I2S2 to recieve and transmit data as shown initially in the flowchart. Once the data is being recieved into the FPGA, we direct it to the FIR filter. This filter is also binded to a switch which allows you to specifically select which type of filter is being operated. Finally, the data is exported back to the PMOD I2S2 to play it through the line out port.

## How to setup this project:

Initially, there is two Xilinx IP's used in this project:
- Clock Wizard (For generating MCLK)
- DDS Compiler (For Testing FIR filter)

Clock Wizard was used to generate the master clock for the PMOD I2S2 peripherals. This allowed my system to operate at 22.579 MHz. The sampling rate occupied for this project was 44.1 KHz which was generated through a Clock Divider. 

The DDS compiler was used to generate a input sinusoid with a low frequency of 500 Hz and a high frequency of 5000 Hz. This allowed me to test the effect of the FIR filter on a noisy sinusoid.

## Filter Coefficients:

The filter coefficients where derived from the Matlab Filter Designer tool. Matlab allows for easy export of coefficient files for xilinx.

### Lowpass Filter:
![Screenshot from 2024-11-09 19-37-39](https://github.com/user-attachments/assets/e868e3e1-9413-4a04-a08d-4c8e129e21b5)

### Highpass Filter:
![Screenshot from 2024-11-09 19-58-54](https://github.com/user-attachments/assets/8ac22519-7b83-472b-8ee5-c20f932a6914)

### Bandpass Filter:
![Screenshot from 2024-11-09 20-06-18](https://github.com/user-attachments/assets/4a5bdaa6-bd50-49ca-a07a-e6884792e5cb)

### Bandstop Filter:
![Screenshot from 2024-11-09 20-12-33](https://github.com/user-attachments/assets/911df234-0bdd-4e7c-b636-cad770ebadcc)

## Testbench Results:

### I2S Transciever:
![Screenshot from 2024-11-13 15-19-55](https://github.com/user-attachments/assets/af0ce3a7-96dc-434e-8934-873af45f7a4f)

These results show that the I2S transciever is behaving according to the I2S protocol standard.

### FIR Filter:
![Screenshot from 2024-11-13 13-11-56](https://github.com/user-attachments/assets/e6280a9c-220b-4d35-a68b-6db42d244812)

These results show that the the output of the FIR filter changes according to the choice of filter. For example, when using the lowpass filter, you can see how we get mostly the 500Hz sound signal. The 5000Hz is mostly removed from the output. The order of the testbench is no filter, lowpass filter, highpass filter, bandpass filter, bandstop filter.

## Timing:

Prior to pipelining the accumulator, this design was not reaching timing closure. To achieve timing closure, I pipelined the accumulator and now have positive worst negative slack and no total negative slack meaning that this design has achieved timing closure!

### Timing Report:
![image](https://github.com/user-attachments/assets/f25f034e-e909-4ae5-905a-8d245839cdcc)



