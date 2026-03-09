module state_ctrl(
	input wire        pll_clk,
	input wire        reset_n,
	input wire [31:0] instruction_value,
	input wire        encrypt_done,
	output reg [31:0] status_value,
	output reg        key_load_mode,
	output reg        data_load_mode,
	output reg        encrypt_active
);

// Instruction values from main.c driver
localparam [31:0] INST_RESET            = 32'h0000_0000;
localparam [31:0] INST_SIGNAL_LOAD_KEY  = 32'h0000_0001;
localparam [31:0] INST_LOADING_KEY      = 32'h0000_0003;
localparam [31:0] INST_LOADING_DATA     = 32'h0000_0005;
localparam [31:0] INST_START_ENCRYPTION = 32'h0000_0009;

// Status values expected by main.c
localparam [31:0] STATUS_RESET      = 32'h0000_0000;
localparam [31:0] STATUS_LOAD_KEY   = 32'h0000_0003;
localparam [31:0] STATUS_LOAD_DATA  = 32'h0000_0005;
localparam [31:0] STATUS_ENCRYPTING = 32'h0000_0009;
localparam [31:0] STATUS_DONE       = 32'h0000_000F;

// State encoding
localparam [2:0] ST_RESET      = 3'd0;
localparam [2:0] ST_LOAD_KEY   = 3'd1;
localparam [2:0] ST_LOAD_DATA  = 3'd2;
localparam [2:0] ST_ENCRYPTING = 3'd3;
localparam [2:0] ST_DONE       = 3'd4;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge pll_clk or negedge reset_n) begin
	if (!reset_n)
		state <= ST_RESET;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	case (state)
		ST_RESET: begin
			if ((instruction_value == INST_SIGNAL_LOAD_KEY) ||
				(instruction_value == INST_LOADING_KEY))
				next_state = ST_LOAD_KEY;
		end

		ST_LOAD_KEY: begin
			if (instruction_value == INST_RESET)
				next_state = ST_RESET;
			else if (instruction_value == INST_LOADING_DATA)
				next_state = ST_LOAD_DATA;
		end

		ST_LOAD_DATA: begin
			if (instruction_value == INST_RESET)
				next_state = ST_RESET;
			else if (instruction_value == INST_START_ENCRYPTION)
				next_state = ST_ENCRYPTING;
		end

		ST_ENCRYPTING: begin
			if (instruction_value == INST_RESET)
				next_state = ST_RESET;
			else if (encrypt_done)
				next_state = ST_DONE;
		end

		ST_DONE: begin
			if (instruction_value == INST_RESET)
				next_state = ST_RESET;
			else if ((instruction_value == INST_SIGNAL_LOAD_KEY) ||
					 (instruction_value == INST_LOADING_KEY))
				next_state = ST_LOAD_KEY;
		end

		default: next_state = ST_RESET;
	endcase
end

always @(*) begin
	status_value   = STATUS_RESET;
	key_load_mode  = 1'b0;
	data_load_mode = 1'b0;
	encrypt_active = 1'b0;

	case (state)
		ST_RESET: begin
			status_value = STATUS_RESET;
		end

		ST_LOAD_KEY: begin
			status_value  = STATUS_LOAD_KEY;
			key_load_mode = 1'b1;
		end

		ST_LOAD_DATA: begin
			status_value   = STATUS_LOAD_DATA;
			data_load_mode = 1'b1;
		end

		ST_ENCRYPTING: begin
			status_value   = STATUS_ENCRYPTING;
			encrypt_active = 1'b1;
		end

		ST_DONE: begin
			status_value = STATUS_DONE;
		end

		default: begin
			status_value = STATUS_RESET;
		end
	endcase
end

endmodule
