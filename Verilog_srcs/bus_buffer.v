module bus_buffer(
	input wire         pll_clk,
	input wire         reset_n,
	input wire         key_load_mode,
	input wire         data_load_mode,
	input wire         write_en,
	input wire [3:0]   word_addr,
	input wire [31:0]  write_data,
	output reg [127:0] aes_key,
	output reg [127:0] aes_data
);

always @(posedge pll_clk or negedge reset_n) begin
	if (!reset_n) begin
		aes_key  <= 128'h0;
		aes_data <= 128'h0;
	end else if (write_en) begin
		if (key_load_mode) begin
			case (word_addr)
				4'h0: aes_key[31:0]    <= write_data;
				4'h4: aes_key[63:32]   <= write_data;
				4'h8: aes_key[95:64]   <= write_data;
				4'hC: aes_key[127:96]  <= write_data;
				default: aes_key        <= aes_key;
			endcase
		end else if (data_load_mode) begin
			case (word_addr)
				4'h0: aes_data[31:0]   <= write_data;
				4'h4: aes_data[63:32]  <= write_data;
				4'h8: aes_data[95:64]  <= write_data;
				4'hC: aes_data[127:96] <= write_data;
				default: aes_data       <= aes_data;
			endcase
		end
	end
end

endmodule
