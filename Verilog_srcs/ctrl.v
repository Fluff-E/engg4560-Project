module ctrl(
	input wire        pll_clk,
	input wire [9:0]  sw,
	input wire [3:0]  key,
	input wire [31:0] fpga_instruction,
	input wire [31:0] fpga_status,
	input wire [31:0] data_to_fpga,
	input wire [31:0] data_from_fpga,
	output reg [23:0] hex_value,
	output wire [9:0] led
);

// meta feeds into sync to prevent instability.
// takes 2 cycles
reg [3:0] key_meta;
reg [3:0] key_sync;

reg [31:0] fpga_instruction_meta;
reg [31:0] fpga_instruction_sync;
reg [31:0] fpga_status_meta;
reg [31:0] fpga_status_sync;

reg [31:0] data_to_fpga_reg;
reg [31:0] data_from_fpga_reg;

wire reset_n;

assign reset_n = key_sync[0];

always @(posedge pll_clk) begin
	key_meta <= key;
	key_sync <= key_meta;
end

always @(posedge pll_clk) begin
	fpga_instruction_meta <= fpga_instruction;
	fpga_instruction_sync <= fpga_instruction_meta;
	fpga_status_meta <= fpga_status;
	fpga_status_sync <= fpga_status_meta;
end

always @(posedge pll_clk) begin
	if (!reset_n) begin
		data_to_fpga_reg <= 32'h0000_0000;
		data_from_fpga_reg <= 32'h0000_0000;
	end else begin
		data_to_fpga_reg <= data_to_fpga;
		data_from_fpga_reg <= data_from_fpga;
	end
end

always @(*) begin
	if (sw[1] == 0 && sw[0] == 0)
		hex_value = fpga_status_sync[23:0];
	else if (sw[1] == 0 && sw[0] == 1)
		hex_value = fpga_instruction_sync[23:0];
	else if (sw[1] == 1 && sw[0] == 0)
		hex_value = data_from_fpga_reg[23:0];
	else
		hex_value = data_to_fpga_reg[23:0];
end

assign led[9:6] = fpga_instruction_sync[3:0];
assign led[3:0] = fpga_status_sync[3:0];
//assign led[1] = fpga_status_sync[1]; // ready
//assign led[0] = fpga_status_sync[0]; // done

endmodule

/*
-- ctrl ----------------------------
   reset (KEY[0])
   
   does synchronization of the fpga_instruction and fpga_status signals
   SWs controls mux for the 7-segment display hex_value output
      - shows fpga_instruction when SW[0] is on
      - shows fpga_status when SW[0] is off  
      - shows data_to_fpga when SW[1] is on
      - shows data_from_fpga when SW[1] is off


   // Need to implement handshake template in C
   LED [9:6] fpga_instruction[4:0]
   LED [5:2] fpga_status[4:0]

   LED [1] ready
   LED [0] done
*/