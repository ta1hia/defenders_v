module invSlowBullet_collision (clock, bulletData, xInvader, collisionFlag, watchCoords, collisionCoords);
	/* Checks for collision of a slow invader and a bullet */
	input [118:0] bulletData;

	input clock;
	input [7:0]xInvader;
	output reg collisionFlag;
	output reg [7:0]watchCoords;	
	output reg [7:0]collisionCoords;	
	reg [118:0]k;

	reg [22:0]delayCount;
	reg ready;

	always @ (posedge clock)		
	begin
		if (delayCount==23'd500000000) begin		//(shootdelayCount==23'd125000000)
			ready <= 1;	
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	always @ (posedge clock)				
	begin
		if (!collisionFlag) begin
			if (k < 117) begin
				if (bulletData[k]==1) begin
					if ((k+43)==(xInvader+2)) begin
						collisionFlag <= 1;
						watchCoords <= k-1;
						collisionCoords <= xInvader;
						end
					end
					k <= k + 1;
				end
			if (k == 117) k <= 0;
		end
		else if (collisionFlag) begin
			if (ready) watchCoords <= watchCoords +2;
			if (watchCoords==159) begin
				watchCoords <= 0;
				collisionFlag<= 0;
			end
		end
	end
		
endmodule

module invFastBullet_collision (clock, bulletData, xInvader, collisionFlag, watchCoords, collisionCoords);
	/* Checks for collision of a fast invader and a bullet */

	input [118:0] bulletData;

	input clock;
	input [7:0]xInvader;
	output reg collisionFlag;
	output reg [7:0]watchCoords;	
	output reg [7:0]collisionCoords;	
	reg [118:0]k;

	reg [22:0]delayCount;
	reg ready;

	always @ (posedge clock)
	begin
		if (delayCount==23'd500000000) begin		//(shootdelayCount==23'd125000000)
			ready <= 1;	
			delayCount <= 1;
			end
		else begin
			delayCount <= delayCount + 23'd1;
			ready <= 0;
		end
	end	
	
	always @ (posedge clock)				
	begin
		if (!collisionFlag) begin
			if (k < 117) begin
				if (bulletData[k]==1) begin
					if (((xInvader+2)-(k+43))<2) begin		//k+43)==
						collisionFlag <= 1;
						watchCoords <= k-1;
						collisionCoords <= xInvader;
						end
					end
					k <= k + 1;
				end
			if (k == 117) k <= 0;
		end
		else if (collisionFlag) begin
			if (ready) watchCoords <= watchCoords +2;
			if (watchCoords==159) begin
				watchCoords <= 0;
				collisionFlag<= 0;
			end
		end
	end
		
endmodule



