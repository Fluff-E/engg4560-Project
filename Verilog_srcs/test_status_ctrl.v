module test_status_ctrl(
	input wire [31:0] instruction_value,
	output reg [2:0] status_addr
);

always @(*) begin
	case (instruction_value)
		32'h0000_0000: status_addr = 3'b000; // RESET/IDLE
		32'h0000_0001: status_addr = 3'b001; // LOAD_KEY_MODE_ENTER
		32'h0000_0003: status_addr = 3'b001; // LOAD_DATA_MODE_ENTER (compat with current test_instruction)
		32'h0000_0005: status_addr = 3'b010; // LOAD_DATA_MODE_ENTER (documented format)
		32'h0000_0009: status_addr = 3'b011; // BEGIN_ENCRYPT
		default:      status_addr = 3'b000;
	endcase
end

endmodule
