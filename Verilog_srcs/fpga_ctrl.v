module fpga_ctrl(
	input wire        pll_clk,
	input wire [9:0]  sw,
	input wire [3:0]  key,
	input wire [31:0] fpga_instruction,
	input wire [31:0] data_to_fpga, // APB bus
	output wire [31:0] fpga_status,
	output wire [31:0] data_from_fpga,// APB bus
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
wire [31:0] state_status_value;
wire key_load_mode;
wire data_load_mode;
wire encrypt_active;
wire encrypt_done;

reg [3:0] encrypt_count;
reg [3:0] load_word_addr;
reg [31:0] data_to_fpga_prev;
reg load_mode_d;

wire load_mode;
wire load_mode_rise;
wire bus_write_en;

wire [127:0] aes_key_assembled;
wire [127:0] aes_data_assembled;
wire [31:0] data_from_fpga_internal;

assign reset_n = key_sync[0];
assign fpga_status = state_status_value;
assign data_from_fpga = data_from_fpga_internal;
assign load_mode = key_load_mode | data_load_mode;
assign load_mode_rise = load_mode & ~load_mode_d;
assign bus_write_en = load_mode & ((data_to_fpga_reg != data_to_fpga_prev) | load_mode_rise);
assign encrypt_done = encrypt_active & (encrypt_count == 4'd8);

// Temporary readback mapping until AES ciphertext path is connected.
assign data_from_fpga_internal = aes_data_assembled[31:0];

always @(posedge pll_clk) begin
	key_meta <= key;
	key_sync <= key_meta;
end

always @(posedge pll_clk) begin
	fpga_instruction_meta <= fpga_instruction;
	fpga_instruction_sync <= fpga_instruction_meta;
	fpga_status_meta <= state_status_value;
	fpga_status_sync <= fpga_status_meta;
end

always @(posedge pll_clk) begin
	if (!reset_n) begin
		data_to_fpga_reg <= 32'h0000_0000;
		data_from_fpga_reg <= 32'h0000_0000;
	end else begin
		data_to_fpga_reg <= data_to_fpga;
		data_from_fpga_reg <= data_from_fpga_internal;
	end
end

always @(posedge pll_clk or negedge reset_n) begin
	if (!reset_n) begin
		encrypt_count <= 4'd0;
	end else if (encrypt_active) begin
		if (encrypt_count != 4'd8)
			encrypt_count <= encrypt_count + 4'd1;
	end else begin
		encrypt_count <= 4'd0;
	end
end

always @(posedge pll_clk or negedge reset_n) begin
	if (!reset_n) begin
		load_mode_d <= 1'b0;
		load_word_addr <= 4'h0;
		data_to_fpga_prev <= 32'h0000_0000;
	end else begin
		load_mode_d <= load_mode;
		data_to_fpga_prev <= data_to_fpga_reg;

		if (load_mode_rise) begin
			load_word_addr <= 4'h0;
		end else if (bus_write_en) begin
			if (load_word_addr == 4'hC)
				load_word_addr <= 4'h0;
			else
				load_word_addr <= load_word_addr + 4'h4;
		end
	end
end

state_ctrl state_ctrl_inst (
	.pll_clk(pll_clk),
	.reset_n(reset_n),
	.instruction_value(fpga_instruction_sync),
	.encrypt_done(encrypt_done),
	.status_value(state_status_value),
	.key_load_mode(key_load_mode),
	.data_load_mode(data_load_mode),
	.encrypt_active(encrypt_active)
);

bus_buffer bus_buffer_inst (
	.pll_clk(pll_clk),
	.reset_n(reset_n),
	.key_load_mode(key_load_mode),
	.data_load_mode(data_load_mode),
	.write_en(bus_write_en),
	.word_addr(load_word_addr),
	.write_data(data_to_fpga_reg),
	.aes_key(aes_key_assembled),
	.aes_data(aes_data_assembled)
);

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

endmodule