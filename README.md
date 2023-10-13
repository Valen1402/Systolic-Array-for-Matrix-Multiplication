# Systolic-Array-for-Matrix-Multiplication

**TASKS DONE:**
- Implement a systolic MAC array datapath to compute matrix multiplication
- Implement memory controller for systolic MAC array
- Implement signals to control weight and input matrix fetch from memory (SRAM) to MAC array
- Implement signals to control output matrix write from MAC array to memory (SRAM)

**DATAPATH SPECIFICATION:**
- Input feature map bit-width: 16-bit
- Weight bit-width: 8-bit
- Output feature map bit-width: 32-bit
- MAC array size(physical): 16 * 16
- Data dimension
  + Input feature map matrix: 16 x 1024
  + Weight matrix: 16 x 16
  + Output feature map matrix: 16 x 1024

![image](https://github.com/Valen1402/Systolic-Array-for-Matrix-Multiplication/assets/82108029/de3ec0dc-d950-4a0a-8bce-56055f82a046)
![image](https://github.com/Valen1402/Systolic-Array-for-Matrix-Multiplication/assets/82108029/3855e82f-53da-470f-8335-26980710fe59)
![image](https://github.com/Valen1402/Systolic-Array-for-Matrix-Multiplication/assets/82108029/8d85ab4c-31f8-4f01-9a16-3b1486ee5995)

 
**MEMORY CONTROLLER SPECIFICATION:**
- Data dimension
  + Input matix: 288 x 196
  + Weight matrix: 64 x 288
  + Output matrix: 64 x 196
- Data structure in SRAM
  + Input feature map RAM bit width: 16 bit x 16 (column major ordering)
  + Weight RAM bit width: 8 bit x 16 (column major ordering)
  + Output feature map RAM bit width: 32 bit x 16 (column major ordering)
 
**BLOCK DIAGRAM**
![image](https://github.com/Valen1402/Systolic-Array-for-Matrix-Multiplication/assets/82108029/62e62e5f-0573-44c2-a59e-25a9f2063fca)
![image](https://github.com/Valen1402/Systolic-Array-for-Matrix-Multiplication/assets/82108029/f3cddbf8-820f-4a61-9cd9-607b1dc73608)