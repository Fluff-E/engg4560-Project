// interfaces with eric_ip2 APB and creates top level for testing independent of HPS
module aes_top (
    input wire clk,
    input wire reset,
    input wire instruction,
    output wire status,
    input wire [127:0] key,
    input wire [127:0] ptext,
    output wire [127:0] ctext
);

// Instantiate aes_ctrl

// Instantiate AES coprocessor

endmodule