module drawCAT (clk, enable, xCount, yCount, address, done);
	/* Draws out cat and sends appropriate (x,y) position of each pixel*/
	input clk;
	input enable;
	output reg done;
	output 	reg [4:0]xCount;
	output 	reg [4:0]yCount;
	output reg [9:0]address;	
	
	initial begin
	xCount = 0;
	yCount = 0;
	address = 2;
	end
	
	always @ (posedge clk)
	begin
	if (enable) begin
		if (xCount < 5'd29)
				xCount <= xCount +1;
				if (yCount == 5'd23) done<=1;
		else if (xCount==5'd29) begin
			if (yCount<5'd23) begin
				xCount<=0;
				yCount<=yCount+1;
				end
			end
		address <= address+10'b1;
		end
	else begin 
		done <= 0; 
		xCount = 0;
		yCount = 0;
		address = 2;
		end
	end
endmodule 


module drawBACK (clk, enable, xCount, yCount, address, done);
	/* Draws out background and sends appropriate (x,y) position of each pixel*/
	input clk, enable;
	output 	reg [7:0]xCount;
	output 	reg [6:0]yCount;
	output reg [14:0]address;
	output reg done;
	
	initial begin
	xCount = 0;
	yCount = 0;
	address = 2;
	end	
	
	always @ (posedge clk)
	begin
	if (enable) begin
		if (xCount < 8'd159)
				xCount <= xCount +1;
		else if (xCount==8'd159) begin
			if (yCount<7'd119) begin
				xCount<=0;
				yCount<=yCount+1;
				end
			else if (yCount==7'd119) done<=1;
			end
		address <= address+15'b1;
		end
	else begin 
		done <= 0; 
		address <= 2;
		//xCount = 0;		// Background refresh removed because of flickering issue
		//yCount = 0;		// and draw/erase method used instead
		end
	end
endmodule
		
module drawINVADER (clk, enable, xCount, yCount, address, done);
	/* Draws out invader and sends appropriate (x,y) position of each pixel*/

	input clk, enable;
	output 	reg [3:0]xCount;
	output 	reg [3:0]yCount;
	output reg [7:0]address;
	output reg done;
	
	initial begin
	xCount = 0;
	yCount = 0;
	address = 2;
	end	
	
	always @ (posedge clk)
	begin
	if (enable) begin
		if (xCount < 4'd13)
				xCount <= xCount +1;
		else if (xCount==4'd13) begin
			if (yCount<4'd11) begin
				xCount<=0;
				yCount<=yCount+1;
				end
			else if (yCount==4'd11) done<=1;
			end
		address <= address+8'b1;
		end
	else begin 
		done <= 0; 
		address <= 2;
		xCount = 0;
		yCount = 0;
		end
	end
endmodule


module drawDEADINVADER (clk, enable, xCount, yCount, address, done);
	/* Draws out invader and sends appropriate (x,y) position of each pixel */ 		// unneccessary, could reuse drawINVADER

	input clk, enable;
	output 	reg [3:0]xCount;
	output 	reg [3:0]yCount;
	output reg [7:0]address;
	output reg done;
	
	initial begin
	xCount = 0;
	yCount = 0;
	address = 1;
	end	
	
	always @ (posedge clk)
	begin
	if (enable) begin
		if (xCount < 4'd13)
				xCount <= xCount +1;
		else if (xCount==4'd13) begin
			if (yCount<4'd11) begin
				xCount<=0;
				yCount<=yCount+1;
				end
			else if (yCount==4'd11) done<=1;
			end
		address <= address+8'b1;
		end
	else begin 
		done <= 0; 
		address <= 1;
		xCount = 0;
		yCount = 0;
		end
	end
endmodule




module healthBar (clock, enable, currentHealth, xCount, yCount, done);
	/* Draws out healthbar and sends appropriate (x,y) position of each pixel*/

	input clock, enable;
	input [6:0]currentHealth;
	output reg [6:0]xCount;
	output reg [1:0]yCount;
	output reg done;
	
	initial begin
	xCount = currentHealth;
	yCount = 0;
	end
	
	always @ (posedge clock)
	begin
		if (enable) begin
		
			if (xCount >= 80) done <= 1;
			else if (xCount < currentHealth) xCount <= xCount+ 1;
			else if (xCount == currentHealth) begin
				if (yCount < 1) begin
					yCount <= yCount + 1;
					xCount <= 0;
					end
				else if (yCount==1) done <= 1;
				end
		end
		else begin
			xCount <= 0;
			yCount <= 0;
			done <= 0;
			end
	end
	
endmodule
	

module hex_4bit(in, hOut);
	/* Sets 7-segment display for hex output */

  input [3:0] in;
  output reg [6:0] hOut;
  
  always @(in)
    case (in)
      4'h0: hOut = 7'b1000000;
      4'h1: hOut = 7'b1111001;
      4'h2: hOut = 7'b0100100;
      4'h3: hOut = 7'b0110000;
      4'h4: hOut = 7'b0011001;
      4'h5: hOut = 7'b0010010;
      4'h6: hOut = 7'b0000010;
      4'h7: hOut = 7'b1111000;
      4'h8: hOut = 7'b0000000;
      4'h9: hOut = 7'b0011000;
      4'hA: hOut = 7'b0001000;
      4'hB: hOut = 7'b0000011;
      4'hC: hOut = 7'b1000110;
      4'hD: hOut = 7'b0100001;
      4'hE: hOut = 7'b0000110;
      4'hF: hOut = 7'b0001110;
      default: hOut = 7'b1111111;
    endcase
endmodule

