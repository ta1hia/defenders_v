module invSlow1_counter (clk, collisionFlag, xCount, Start);
	/* Generates movement of a slow invader (starting x position 1) */
	input clk, Start;
	input [2:0]collisionFlag;
	output reg [7:0] xCount;
	
	reg [22:0]delayCount;
	reg ready;
	
	initial begin 
	xCount = 220;
	end

	always @ (posedge clk)		
	begin
		if (delayCount==23'd500000000) begin		
			ready <= 1;	
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	always @(posedge clk) 
	begin
		if (ready & Start) begin
			if ((xCount <= 36)|(collisionFlag)) xCount <= 170;
			else xCount <= xCount - 1;
		end
	end
	
endmodule
	
module invSlow2_counter (clk, collisionFlag, xCount, Start);
	/* Generates movement of a slow invader (starting x position 2) */

	input clk, Start;
	input [2:0]collisionFlag;
	output reg [7:0] xCount;
	
	reg [22:0]delayCount;
	reg ready;
	
	initial begin 
	xCount = 159;
	end

	always @ (posedge clk)		
	begin
		if (delayCount==23'd500000000) begin		
			ready <= 1;	
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	always @(posedge clk) 
	begin
		if (ready & Start) begin
			if ((xCount <= 36)|(collisionFlag)) xCount <= 220;
			else xCount <= xCount - 1;
		end
	end
	
endmodule


module invFast1_counter (clk, collisionFlag, xCount, Start);
	/* Generates movement of a fast invader (starting x position 1) */

	input clk, Start;
	input [2:0]collisionFlag;
	output reg [7:0] xCount;
	
	reg [22:0]delayCount;
	reg ready;
	
	initial begin 
	xCount = 159;
	end

	always @ (posedge clk)		
	begin
		if (delayCount==23'd500000000) begin		
			ready <= 1;	
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	always @(posedge clk) 
	begin
		if (ready & Start) begin
			if ((xCount <= 36)|(collisionFlag)) xCount <= 230;
			else xCount <= xCount - 2;
		end
	end
	
endmodule


module redErase_counter (clock, redOn, eraseOn);
	/* Counter to hold death animation for approx. 0.5 of a second */

	input redOn, clock;
	output reg eraseOn;
	
	reg [30:0] deadCount;
	
	always @ (posedge clock)
	begin
	if (redOn) begin
		if (deadCount == 30'd20000000) begin
			eraseOn <= 1;
			end
		else deadCount <= deadCount + 1;
		end
	else begin eraseOn <= 0; deadCount <=1; end
	end
endmodule



		