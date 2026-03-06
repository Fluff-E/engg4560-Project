module test_status(
	input wire [2:0] sel,
	output reg [31:0] value
);

//always @(*) begin
//if (value != 32'h0000_0009 && sel != 3'b000) begin	
//	case (sel)
//		3'b000: value = 32'h0000_0000;
//		3'b001: value = 32'h0000_0003;
//		3'b010: value = 32'h0000_0005;
//		3'b011: value = 32'h0000_0009;
//		3'b100: value = 32'h0000_000F;
//		default: value = 32'h0000_0000;
//	endcase
//	end
//	else begin
//		value = 32'h0000_0002;
//	end
//end
//endmodule

always @(*) begin
	if (value == 32'h0000_0009 && sel == 3'b011) begin	
		value = 32'h0000_000F;
	end
	else begin	
		case (sel)
		3'b000: value = 32'h0000_0000;
		3'b001: value = 32'h0000_0003;
		3'b010: value = 32'h0000_0005;
		3'b011: value = 32'h0000_0009;
		3'b100: value = 32'h0000_000F;
		default: value = 32'h0000_0000;
		endcase
	end
end
endmodule