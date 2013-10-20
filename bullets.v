module bullet_SR (clk, load, serialIn, parallelOut, doneSig);
	/* Serial-in, parallel-out shift register for bullets along one row of the screen.
		SerialIn is "shoot" user input. ParallelOut is entire row data from the shift register. 
		1's represent bullets. */
	input clk, load, serialIn;
	output [117:0] parallelOut;
	output reg doneSig;	
	
	reg [22:0]delayCount;
	reg ready;

	always @ (posedge clk)		
	begin
		if (delayCount==23'd500000000) begin		// Delays 1 second before checking for another bullet. 
			ready <= 1;										// Prevents many bullets from appearing on the screen at once.
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	reg [1:0]firstbit;
	reg    [117:0] tmp;
	
	always @(posedge clk) 
	begin
		if (ready) begin
			if (load) firstbit <= serialIn;
			else firstbit <= 1'b0;
			tmp <= {tmp[115:0], firstbit};
		end
	end
	
	always @ (posedge clk)
	begin
		if (ready) begin
			if (firstbit == 1) doneSig <= 1;
			else doneSig <= 0;
		end
	end
	
	assign parallelOut = tmp;	// pew pew
endmodule


module drawBULLET (clock, enable, bulletData, colour, xCount, done);
	/* Taking row information from the bullet shift register, sets output colour to "white" if a bullet (i.e. "1") is detected,
		otherwise sets output colour to "black" if nothing is detected (i.e "0"). Outputs used in VGA write control block. */
	input enable, clock;
	input [118:0] bulletData;
	output reg[7:0]xCount;
	output reg[2:0] colour;
	output reg done;
	
	reg [118:0]k;
	integer j;
	
	always @ (posedge clock)				
	begin
	if (enable) begin
		if (j < 117) begin
			xCount <= k;
			if (bulletData[j]==1) begin
				colour <=3'b111;
				end
			else colour <= 3'b000;
			k <= k + 1;
			j <= j + 1;
		end
		if (j == 117) begin
			k <= 0;
			j <= 0;
			done <= 1;
		end
	end	
	else begin
		done <= 0;
		end
	end
endmodule

