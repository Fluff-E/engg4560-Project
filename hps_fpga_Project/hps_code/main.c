#include <stdio.h> 
#include <unistd.h> 
#include <fcntl.h> 
#include <sys/mman.h> 
#include "hwlib.h" 
#include "socal/socal.h" 
#include "socal/hps.h" 
#include "socal/alt_gpio.h" 
#include "hps_0.h" 
 
#define HW_REGS_BASE ( ALT_STM_OFST ) 
#define HW_REGS_SPAN ( 0x04000000 ) 
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 ) 

// Defintions of pio_fpga_inst and pio_fpga_status functions
#define INST_RESET 0x00000000
#define INST_SIGNAL_LOAD_KEY 0x00000001
#define INST_LOADING_KEY 0x00000003
#define INST_LOADING_DATA 0x00000005
#define INST_START_ENCRYPTION 0x00000009

#define STATUS_RESET 0X00000000
#define STATUS_LOAD_KEY 0x00000003
#define STATUS_LOAD_DATA 0x00000005
#define STATUS_ENCRYPTING 0x00000009
#define STATUS_DONE 0x0000000F
 
int main() { 
    void *virtual_base; 
    int fd; 
	void *pio_fpga_inst;
	void *pio_fpga_status;
	void *h2p_lw_coproc_addr_memory;

    int mem_data, mm_reg, j, ii; 
    int most_sig_bit, least_sig_bit;
    int aes_key[4];
    int aes_data[4];
     
    // map the address space for the LED registers into user space so we can interact with them. 
    // we'll map in the entire CSR span of the HPS since we want to access various registers within that span 
    printf("Calling fopen\n"); 
    if((fd = open( "/dev/mem", ( O_RDWR | O_SYNC))) == -1) { 
        printf("ERROR: could not open \"/dev/mem\"...\n"); 
        return(1); 
    } 
 
    printf("Creating mmap\n"); 
    virtual_base = mmap(NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE); 
    if(virtual_base == MAP_FAILED) { 
        printf("ERROR: mmap() failed...\n"); 
        close(fd); 
        return(1); 
    } 
  
	pio_fpga_inst = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_FPGA_INST_BASE) & 
        (unsigned long)(HW_REGS_MASK)); 
		
	pio_fpga_status = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + PIO_FPGA_STATUS_BASE) & 
        (unsigned long)(HW_REGS_MASK));
	
	h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE) & 
        (unsigned long)(HW_REGS_MASK));

    //Main loop
    while(1){
        // set instruction to reset, wait acknowledge
        *(uint32_t *)pio_fpga_inst = INST_RESET;
        while(*(uint32_t *)pio_fpga_status != STATUS_RESET);
        printf("Coprocessor is in reset state\n");

        // set instruction to signal load aes key, wait acknowledge
        *(uint32_t *)pio_fpga_inst = INST_SIGNAL_LOAD_KEY;
        while(*(uint32_t *)pio_fpga_status != STATUS_LOAD_KEY);
        printf("Coprocessor is ready to load key\n");

        for (ii = 0,most_sig_bit = 31, least_sig_bit = 0; ii < 16; ii = ii + 4, most_sig_bit += 32, least_sig_bit += 32){          
            printf("Enter aes key[%d:%d] in hexadecimal, to write in location = %x\n", most_sig_bit, least_sig_bit, ii);
            mm_reg = ii;
            scanf("%x", &mem_data);
            h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE + mm_reg) &
                (unsigned long)(HW_REGS_MASK));
            printf("Writing coprocessor memory address = %p\n", h2p_lw_coproc_addr_memory);
            *(uint32_t *)h2p_lw_coproc_addr_memory = mem_data;
        }

        // set instruction to load data, wait acknowledge
        *(uint32_t *)pio_fpga_inst = INST_LOADING_DATA;
        // This is where the hardware needs to store the bus data in a buffer
        while(*(uint32_t *)pio_fpga_status != STATUS_LOAD_DATA);
        printf("Coprocessor is ready to load data\n");

        for (ii = 0,most_sig_bit = 31, least_sig_bit = 0; ii < 16; ii = ii + 4, most_sig_bit += 32, least_sig_bit += 32){          
            printf("Enter aes data[%d:%d] in hexadecimal, to write in location = %x\n", most_sig_bit, least_sig_bit, ii);
            mm_reg = ii;
            scanf("%x", &mem_data);
            h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE + mm_reg) &
                (unsigned long)(HW_REGS_MASK));
            printf("Writing coprocessor memory address = %p\n", h2p_lw_coproc_addr_memory);
            *(uint32_t *)h2p_lw_coproc_addr_memory = mem_data;
        }

        // set instruction to start encryption, wait acknowledge
        *(uint32_t *)pio_fpga_inst = INST_START_ENCRYPTION;
        while(*(uint32_t *)pio_fpga_status != STATUS_ENCRYPTING);
        printf("Coprocessor has started encryption\n");
        while(*(uint32_t *)pio_fpga_status != STATUS_DONE);
        printf("Coprocessor has completed encryption\n");

        printf("Reading memory locations\n");
        for (j=0,ii = 0; ii < 16; ii = ii + 4, j++){
            mm_reg = ii;
            h2p_lw_coproc_addr_memory = virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + MY_AES_IP_0_BASE + mm_reg) &
                (unsigned long)(HW_REGS_MASK));
            printf("Reading coprocessor memory address = %p\n", h2p_lw_coproc_addr_memory);
            mem_data = *(uint32_t *)h2p_lw_coproc_addr_memory;
            aes_data[j] = mem_data;
            printf("Memory data read: %x\n", mem_data);
        }

        // add printout of 128 bit encrypted data, which is stored in the first 4 memory locations of the coprocessor
        printf("Encrypted data is:\n");
        for (j=3; j >= 0; j--){
            printf("%08x ", aes_data[j]);
        }
        printf("\n\n");
    }

    // clean up our memory mapping and exit 
        if( munmap(virtual_base, HW_REGS_SPAN) != 0) { 
        printf("ERROR: munmap() failed...\n"); 
        close(fd); 
        return(1); 
    } 
    close(fd); 
    return(0); 
} 