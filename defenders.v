 // Defenders

module defenders
	(
		SW,
		CLOCK_50,						//	On Board 50 MHz
		KEY,							//	Push Button[3:0]
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		HEX6,
		HEX7,
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	
	input 	[17:0]SW;
	input				CLOCK_50;				//	50 MHz
	input		[3:0]	KEY;					//	Button[3:0]
	output 	[6:0]			HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;				//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = SW[0];
	

	// VGA controller instance
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "start.mif";
				
	
	// VGA Adapter Input  
	reg [2:0] colour;
	reg [7:0] x, x_cat;
	reg [6:0] y, y_cat;
	wire [7:0] x_health;
	wire [6:0] y_health;
	wire [7:0] x_invader [7:0];
	wire [7:0] y_invader [7:0];
	reg writeEn;
	
	// User Input
	wire up, down;
	assign up = ~KEY[1];
	assign down = ~KEY[0];
	
	// Drawing signals
	wire [9:0]catAddress;
	wire [14:0]bgAddress, gameoverAddress, winnerAddress;
	wire [4:0] y_catspr, x_catspr;
	wire [7:0] x_backspr, x_gameover, x_winner;
	wire [6:0] y_backspr, y_gameover, y_winner;
	wire [2:0] colourCAT, colourBACK, colourGameOver, colourWinner;
	wire catDone, backDone, healthDone, gameoverDone, winnerDone;
	reg invDone;
	
	
	//FSM Control signals
	reg [4:0] current_Draw, next_Draw;
	reg add_sub_Y, enable_Y;
	reg catEn, backEn, baddieEn, deadEn, healthEn, gameoverEn, winnerEn, chillDelay;
	reg [30:0]count;
	
	parameter RESET=4'b0000, CHILL=4'b0001;
	parameter DISPLAY_BACK=4'b0010, DISPLAY_CAT=4'b0011, DISPLAY_BULLET=4'b1001, DISPLAY_INVADER=4'b1010, DISPLAY_DEAD = 4'b1011, DISPLAY_INVASION = 4'b1100;
	parameter DISPLAY_HEALTHBAR= 4'b1101, DISPLAY_START = 4'b1110, GAMEOVER = 4'b1111, WINNER= 4'b0111;
	
	
	//Memory instantiation
	backgroundROMS backgroundROMS_inst (bgAddress, CLOCK_50, colourBACK);
	catROMS	catROMS_inst (catAddress, CLOCK_50, colourCAT);
	invaderROMS invaderROMS_inst (invAddress, CLOCK_50, colourINV);
	dead_invaderROMS	dead_invaderROMS_inst (deadInvAddress,  CLOCK_50, colourDeadInv);
	gameoverROM	gameoverROM_inst (gameoverAddress, CLOCK_50, colourGameOver);
	winnerROM	winnerROM_inst (winnerAddress, CLOCK_50, colourWinner);


	// Drawing modules
	drawCAT	cat_xy (CLOCK_50, catEn, x_catspr, y_catspr, catAddress, catDone);
	drawBACK bg (CLOCK_50, backEn, x_backspr, y_backspr, bgAddress, backDone);
	drawBACK go (CLOCK_50, gameoverEn, x_gameover, y_gameover, gameoverAddress, gameoverDone);
	drawBACK win (CLOCK_50, winnerEn, x_winner, y_winner, winnerAddress, winnerDone);
	healthBar bar(CLOCK_50, healthEn, earthHealth, x_health, y_health, healthDone);

	
	//Game Control
	reg [6:0]earthHealth;
	reg gameOver;
	reg omgwinner;	
	
	initial begin
	y_cat <= 35;
	gameOver <= 0;
	end

	
// ************************************************************
//  
//	 Major FSM - controls drawing of all major objects
//  
// ************************************************************
	
	always @ (*)
	begin
	case (current_Draw)
		RESET:	begin
							next_Draw <=DISPLAY_START;
					end
		DISPLAY_START:		if (on) next_Draw <= DISPLAY_BACK;
								else next_Draw <= DISPLAY_START;
		CHILL:	begin
						if (gameover) next_Draw <= GAMEOVER;
						else if (omgwinner) next_Draw <= WINNER;
						else if (chillDelay) begin 
							next_Draw <= DISPLAY_BACK;
							end
						else next_Draw <= CHILL;
					end

		DISPLAY_BACK:	begin
						 if (backEn) begin
							if (backDone) begin
								next_Draw <= DISPLAY_HEALTHBAR;
							end
							else next_Draw <= DISPLAY_BACK;
							end
						end
		DISPLAY_HEALTHBAR: begin
						if (healthEn) begin
							if (healthDone) begin
								next_Draw <= DISPLAY_CAT;
							end
						else next_Draw <= DISPLAY_HEALTHBAR;
						end
					end
		DISPLAY_CAT:		begin
						if (catEn) begin
							if (catDone) begin
								next_Draw <= DISPLAY_DEAD;
								end
							else next_Draw <= DISPLAY_CAT;
							end
						end

		DISPLAY_BULLET:	begin
						if (bulletEn) begin
							if (bulletDone) begin
								next_Draw <= DISPLAY_INVADER;
								end
							else next_Draw <= DISPLAY_BULLET;
							end
						end
		DISPLAY_INVADER:	begin
						if (baddieEn) begin
							if (invDone) begin
								next_Draw <= CHILL;
								end
							else next_Draw <= DISPLAY_INVADER;
							end
						end
		DISPLAY_DEAD:	begin
					if (deadEn) begin
						if (redOn) begin
							if (deadDone) next_Draw <= DISPLAY_BULLET;
							else  next_Draw <= DISPLAY_DEAD;
							end
						else next_Draw <= DISPLAY_BULLET;
						end
					end
		GAMEOVER:	begin
						if (gameoverEn) begin
							if (gameoverDone) begin
								next_Draw <= GAMEOVER;
								end
							else next_Draw <= GAMEOVER;
							end
						end
		WINNER:	begin
						if (winnerEn) begin
							if (winnerDone) begin
								next_Draw <= WINNER;
								end
							else next_Draw <= WINNER;
							end
						end

	endcase
	end
	


	// Control of all ENABLE signals for FSM states
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_BACK) begin
			backEn <= 1;
			end
		else backEn <= 0;
	end	
	
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_CAT) begin
			catEn <= 1;
			end
		else catEn <= 0;
	end

	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==GAMEOVER) begin
			gameoverEn <= 1;
			end
		else gameoverEn <= 0;
	end
	
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==WINNER) begin
			winnerEn <= 1;
			end
		else winnerEn <= 0;
	end
	
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_BULLET) begin
			bulletEn <= 1;
			end
		else bulletEn <= 0;
	end
	
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_INVADER) begin
			baddieEn <= 1;
			end
		else baddieEn <= 0;
	end
		
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_DEAD) begin
			deadEn <= 1;
			end
		else deadEn <= 0;
	end
	
	always @ (posedge CLOCK_50)
	begin
		if (current_Draw==DISPLAY_HEALTHBAR) begin
			healthEn <= 1;
			end
		else healthEn <= 0;
	end
	// End of ENABLE signal control blocks


	// Sets delay during CHILL state after all objects have been drawn to VGA
	// in one cycle of the FSM.
	always @ (posedge CLOCK_50)	
	begin
	if (current_Draw==CHILL) begin
		if (count==30'd1000000) begin
			count <= 1;
			chillDelay <= 1;
			end
		else begin 
			count <= count + 23'd1;
			end
		end
	else  chillDelay <= 0;
	end
	
	always @ (posedge CLOCK_50 or negedge resetn)		// Shifting states
	begin
		if (resetn==0) 
			current_Draw <= RESET;
		else 
			current_Draw <= next_Draw;
	end

	
// ************************************************************
// 
//	VGA Writes
// 
// ************************************************************
	
	always @ (posedge CLOCK_50)				
	begin
		if (current_Draw == DISPLAY_BACK) begin
			if (backEn) begin
				x <= x_backspr;
				y <= y_backspr;
				colour <= colourBACK;
				writeEn <= backEn;
			end
			end
		else if (current_Draw == GAMEOVER) begin
			if (gameoverEn) begin
				x <= x_gameover;
				y <= y_gameover;
				colour <= colourGameOver;
				writeEn <= gameoverEn;
				end
			end
		else if (current_Draw == WINNER) begin
			if (winnerEn) begin
				x <= x_winner;
				y <= y_winner;
				colour <= colourWinner;
				writeEn <= winnerEn;
				end
			end
		else if (current_Draw == DISPLAY_CAT) begin
			if (catEn) begin
				x <= x_cat + x_catspr;
				y <= y_cat + y_catspr;
				colour <= colourCAT;
				writeEn <= catEn;
				end
			end
		else if (current_Draw == DISPLAY_HEALTHBAR) begin
			if (healthEn) begin
				x <= 49 + x_health;
				y <= 114 + y_health;
				colour <= 3'b100;
				writeEn <= healthEn;
				end
			end
		else if (current_Draw == DISPLAY_BULLET) begin
			if (bulletEn) begin
				if (bulletRowEn[0]) begin 
					x <= x_bullet[0] +  42; 
					y <= 7'd11; 
					// If a collision is detected on a particular bullet, it will disappear (i.e. drawn black on the screen)
					if ((collisionBulletFlag[0])&(x_bullet[0]>=(watchCoords[0]))) colour <= 3'b000;
					else colour <= colourBULLETS[0]; 
					end	
				// If a bullet (i.e., "1") is detected in the shift register output corresponding to the appropriate y-coordinate, 
				// a white pixel (representing a bullet) will be drawn to the screen.
				else if (bulletRowEn[1]) begin x <= x_bullet[1] +  42; y <= 7'd17; colour <= colourBULLETS[1]; end
				else if (bulletRowEn[2]) begin x <= x_bullet[2] +  42; y <= 7'd22; colour <= colourBULLETS[2]; end
				else if (bulletRowEn[3]) begin x <= x_bullet[3] +  42; y <= 7'd26; colour <= colourBULLETS[3]; end
				else if (bulletRowEn[4]) begin x <= x_bullet[4] +  42; y <= 7'd30; colour <= colourBULLETS[4]; end
				else if (bulletRowEn[5]) begin x <= x_bullet[5] +  42; y <= 7'd34; colour <= colourBULLETS[5]; end
				else if (bulletRowEn[6]) begin x <= x_bullet[6] +  42; y <= 7'd38; colour <= colourBULLETS[6]; end
				else if (bulletRowEn[7]) begin x <= x_bullet[7] +  42; y <= 7'd42; colour <= colourBULLETS[7]; end
				else if (bulletRowEn[8]) begin x <= x_bullet[8] +  42; y <= 7'd46; colour <= colourBULLETS[8]; end
				else if (bulletRowEn[9]) begin x <= x_bullet[9] +  42; y <= 7'd50; colour <= colourBULLETS[9]; end
				else if (bulletRowEn[10]) begin x <= x_bullet[10] +  42; y <= 7'd54; colour <= colourBULLETS[10]; end
				else if (bulletRowEn[11]) begin x <= x_bullet[11] +  42; y <= 7'd58; colour <= colourBULLETS[11]; end
				else if (bulletRowEn[12]) begin x <= x_bullet[12] +  42; y <= 7'd62; colour <= colourBULLETS[12]; end
				else if (bulletRowEn[13]) begin x <= x_bullet[13] +  42; y <= 7'd66; colour <= colourBULLETS[13]; end
				else if (bulletRowEn[14]) begin x <= x_bullet[14] +  42; y <= 7'd70; colour <= colourBULLETS[14]; end
				else if (bulletRowEn[15]) begin x <= x_bullet[15] +  42; y <= 7'd74; colour <= colourBULLETS[15]; end
				else if (bulletRowEn[16]) begin x <= x_bullet[16] +  42; y <= 7'd79; colour <= colourBULLETS[16]; end
				else if (bulletRowEn[17]) begin x <= x_bullet[17] +  42; y <= 7'd83; colour <= colourBULLETS[17]; end
				else if (bulletRowEn[18]) begin x <= x_bullet[18] +  42; y <= 7'd87; colour <= colourBULLETS[18]; end
				else if (bulletRowEn[19]) begin x <= x_bullet[19] +  42; y <= 7'd91; colour <= colourBULLETS[19]; end
				else if (bulletRowEn[20]) begin x <= x_bullet[20] +  42; y <= 7'd95; colour <= colourBULLETS[20]; end
				else if (bulletRowEn[21]) begin x <= x_bullet[21] +  42; y <= 7'd99; colour <= colourBULLETS[21]; end
				else if (bulletRowEn[22]) begin x <= x_bullet[22] +  42; y <= 7'd103; colour <= colourBULLETS[22]; end
				else if (bulletRowEn[23]) begin x <= x_bullet[23] +  42; y <= 7'd107; colour <= colourBULLETS[23]; end
				else if (bulletRowEn[24]) begin x <= x_bullet[24] +  42; y <= 7'd111; colour <= colourBULLETS[24]; end
			
				writeEn <= 1'b1;
				end
			end
		else if (current_Draw == DISPLAY_INVADER) begin
			if (baddieEn) begin
			
			// Draws 7 green invaders to the screen as each advances along the x-axis
			if (baddieRowEn[0]) begin
				if (disappearInv[0]) begin x <= x_invader[0] + x_invspr; y <= 5 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[0] + x_invspr; y <= 5 + y_invspr; colour <= colourINV; end
			end	
			
			else if (baddieRowEn[1]) begin
				if (disappearInv[1]) begin x <= x_invader[1] + x_invspr + 5; y <= 18 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[1] + x_invspr + 5; y <= 18 + y_invspr; colour <= colourINV; end 
			end	
			
			else if (baddieRowEn[2]) begin
				if (disappearInv[2]) begin x <= x_invader[2] + x_invspr + 5; y <= 32 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[2] + x_invspr + 5; y <= 32 + y_invspr; colour <= colourINV; end 
			end	
			
			else if (baddieRowEn[3]) begin
				if (disappearInv[3]) begin x <= x_invader[3] + x_invspr + 6; y <= 45 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[3] + x_invspr + 6; y <= 45 + y_invspr; colour <= colourINV; end 
			end	
			
			else if (baddieRowEn[4]) begin
				if (disappearInv[4]) begin x <= x_invader[4] + x_invspr + 10; y <= 58 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[4] + x_invspr + 10; y <= 58 + y_invspr; colour <= colourINV; end 
			end	
			
			else if (baddieRowEn[5]) begin
				if (disappearInv[5]) begin x <= x_invader[5] + x_invspr + 8; y <= 71 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[5] + x_invspr + 8; y <= 71 + y_invspr; colour <= colourINV; end 
			end
			
			else if (baddieRowEn[6]) begin
				if (disappearInv[6]) begin x <= x_invader[6] + x_invspr + 7; y <= 84 + y_invspr; colour <= 3'b000; end
				else begin x <= x_invader[6] + x_invspr + 7; y <= 84 + y_invspr; colour <= colourINV; end 
			end
			
				writeEn <= baddieEn;
				end
			end
		else if (current_Draw == DISPLAY_DEAD) begin
			if (deadEn) begin
				
				// If a collision flag is detected on a specific row, a "dead" invader will be drawn to the screen
				// at the (x,y) position where the collision occurred for a portion of a second.
				// After the dead invader has been drawn to the screen for a portion of a second, it will be drawn over
				// with black. This check occurs for each invader.
				if ((deadRowEn[0])&(collisionBulletFlag[0])) begin
					x <=  collisionCoords_B[0]+ x_deadinvader;
					y <= 7'd5 + y_deadinvader;
					if (eraseDeadOn[0]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				else if ((deadRowEn[1])&(collisionBulletFlag[1])) begin
					x <=  collisionCoords_B[1]+ x_deadinvader + 5; 
					y <= 7'd18 + y_deadinvader; 
					if (eraseDeadOn[1]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end		
		
				else if ((deadRowEn[2])&(collisionBulletFlag[2])) begin
					x <=  collisionCoords_B[2]+ x_deadinvader + 5; 
					y <= 7'd18 + y_deadinvader; 
					if (eraseDeadOn[2]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end	

				else if ((deadRowEn[3])&(collisionBulletFlag[3])) begin
					x <=  collisionCoords_B[3]+ x_deadinvader + 5; 
					y <= 7'd32 + y_deadinvader; 
					if (eraseDeadOn[3]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end	

				else if ((deadRowEn[4])&(collisionBulletFlag[4])) begin
					x <=  collisionCoords_B[4]+ x_deadinvader + 5; 
					y <= 7'd32 + y_deadinvader; 
					if (eraseDeadOn[4]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end		
			
				else if ((deadRowEn[5])&(collisionBulletFlag[5])) begin
					x <=  collisionCoords_B[5]+ x_deadinvader + 5; 
					y <= 7'd32 + y_deadinvader; 
					if (eraseDeadOn[5]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
	
				else if ((deadRowEn[6])&(collisionBulletFlag[6])) begin
					x <=  collisionCoords_B[6]+ x_deadinvader + 6; 
					y <= 7'd45 + y_deadinvader; 
					if (eraseDeadOn[6]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end	
				
				else if ((deadRowEn[7])&(collisionBulletFlag[7])) begin
					x <=  collisionCoords_B[7]+ x_deadinvader + 6; 
					y <= 7'd45 + y_deadinvader; 
					if (eraseDeadOn[7]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end		
				
				else if ((deadRowEn[8])&(collisionBulletFlag[8])) begin
					x <=  collisionCoords_B[8]+ x_deadinvader + 6; 
					y <= 7'd45 + y_deadinvader; 
					if (eraseDeadOn[8]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end	
				
				else if ((deadRowEn[9])&(collisionBulletFlag[9])) begin
					x <=  collisionCoords_B[9]+ x_deadinvader + 10; 
					y <= 7'd58 + y_deadinvader; 
					if (eraseDeadOn[9]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end

				else if ((deadRowEn[10])&(collisionBulletFlag[10])) begin
					x <=  collisionCoords_B[10]+ x_deadinvader + 10; 
					y <= 7'd58 + y_deadinvader; 
					if (eraseDeadOn[10]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				else if ((deadRowEn[11])&(collisionBulletFlag[11])) begin
					x <=  collisionCoords_B[11]+ x_deadinvader + 8; 
					y <= 7'd71 + y_deadinvader; 
					if (eraseDeadOn[11]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				else if ((deadRowEn[12])&(collisionBulletFlag[12])) begin
					x <=  collisionCoords_B[12]+ x_deadinvader + 8; 
					y <= 7'd71 + y_deadinvader; 
					if (eraseDeadOn[12]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				else if ((deadRowEn[13])&(collisionBulletFlag[13])) begin
					x <=  collisionCoords_B[13]+ x_deadinvader + 7; 
					y <= 7'd84 + y_deadinvader; 
					if (eraseDeadOn[13]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				else if ((deadRowEn[14])&(collisionBulletFlag[14])) begin
					x <=  collisionCoords_B[14]+ x_deadinvader + 7; 
					y <= 7'd84 + y_deadinvader; 
					if (eraseDeadOn[14]) colour <= 3'b000;
					else colour <= colourDeadInv;
				end
				
				writeEn <= deadEn;
				end
			end
		else writeEn <=0;
	end
	

// ************************************************************
// 
//	Game Flow Control	(points; earth health bar)
// 
// ************************************************************
	
	reg gameover;
	wire on;
	assign on = SW[17];
	
	reg barFlag;
	
	always @ (posedge CLOCK_50)		// Subtraction from earth health only occurs once per invader collision
	begin 
	if (on) begin
	if (!barFlag) begin
		if ((x_invader[0] == 40)|(x_invader[1] == 40)|(x_invader[2] == 40)|
		(x_invader[3] == 40)|(x_invader[4] == 40)|(x_invader[5] == 40)|
		(x_invader[6] == 40))  begin 
			earthHealth <= earthHealth + 8; 
			barFlag <= 1; 
			end
		end
	else if ((x_invader[0] != 40)&(x_invader[1] != 40)&(x_invader[2] != 40)
	&(x_invader[3] != 40)&(x_invader[4] != 40)&(x_invader[5] != 40)&(x_invader[6] != 40)) 
	barFlag <= 0;
		end
	end
	
	
	always @ (posedge CLOCK_50)
	begin
	if (earthHealth >= 80) gameover <= 1;
	else gameover <= 0;
	end

	always @ (posedge CLOCK_50)
	begin
	if (POINTSLOL >= 255) omgwinner <= 1;
	else omgwinner <= 0;
	end
	
	

	
	
	reg [8:0]POINTSLOL;
	
	reg [6:0] pointsFlag;
	
	// Points system
	always @ (posedge CLOCK_50)
	begin
		if (!pointsFlag[0]) begin
			if (collisionBulletFlag[0]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[0] <= 1;
				end
			end
		else if (!collisionBulletFlag[0]) pointsFlag[0] <= 0;
	
		if (!pointsFlag[1]) begin
			if (collisionBulletFlag[1]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[1] <= 1;
				end
			end
		else if (!collisionBulletFlag[1]) pointsFlag[1] <= 0;
		
		if (!pointsFlag[2]) begin
			if (collisionBulletFlag[2]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[2] <= 1;
				end
			end
		else if (!collisionBulletFlag[2]) pointsFlag[2] <= 0;
		
		if (!pointsFlag[3]) begin
			if (collisionBulletFlag[3]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[3] <= 1;
				end
			end
		else if (!collisionBulletFlag[3]) pointsFlag[3] <= 0;
		
		if (!pointsFlag[4]) begin
			if (collisionBulletFlag[4]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[4] <= 1;
				end
			end
		else if (!collisionBulletFlag[4]) pointsFlag[4] <= 0;
	
		if (!pointsFlag[5]) begin
			if (collisionBulletFlag[5]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[5] <= 1;
				end
			end
		else if (!collisionBulletFlag[5]) pointsFlag[5] <= 0;

		if (!pointsFlag[6]) begin
			if (collisionBulletFlag[6]) begin 
				POINTSLOL <= POINTSLOL + 15;
				pointsFlag[6] <= 1;
				end
			end
		else if (!collisionBulletFlag[6]) pointsFlag[6] <= 0;
	end

	hex_4bit	H0(POINTSLOL[3:0], HEX0[6:0]);
	hex_4bit	H1(POINTSLOL[7:4], HEX1[6:0]);
	hex_4bit	H2({4'bxxxx}, HEX2[6:0]);
	hex_4bit	H3({4'bxxxx}, HEX3[6:0]);
	hex_4bit	H4({4'bxxxx}, HEX4[6:0]);
	hex_4bit	H5({4'bxxxx}, HEX5[6:0]);
	hex_4bit	H6({4'bxxxx}, HEX6[6:0]);
	hex_4bit	H7({4'bxxxx}, HEX7[6:0]);
	// End Points system
		

	

// ************************************************************
// 
//	Defender (Cat) Datapath and Display Control
// 
// ************************************************************

	reg [22:0]moveCount;

	always @ (posedge CLOCK_50)		// Datapath to update coordinates of cat	
	begin
		if (resetn==0)begin
			y_cat <= 0;
			x_cat <= 0;
			end
		else if (moveCount==23'd125000000) begin
			if ((up && !down)|(!up && down)) begin
				if ((up)&(y_cat>=2)) y_cat <= y_cat - 2;
				else if ((down)&(y_cat<=96)) y_cat <= y_cat + 2;
			end	
			moveCount <= 1;
			end
		else moveCount <= moveCount + 23'd1;
	end	
	

// ************************************************************
// 
//	Bullet Datapath and Display Control
// 
// ************************************************************
	
	reg bulletEn;
	reg bulletDone;	// for shifting of DISPLAY_BULLET state in FSM
	
	wire shoot;
	assign shoot = ~KEY[3];
	wire [117:0] bulletInfo [0:24];		// Register array: for 24 rows of shift registers that will hold bullet data
	reg [2:0]current_Shoot, next_Shoot;
	
	// to track start and end of loading to "SerialIn" in each bullet shift register
	reg [24:0]shootUpdate; 
	wire [24:0]shootPassed;
	
	// Create 25 instances of bullet shift registers
	genvar i; 
	
	generate 
		for (i = 0; i < 25; i = i +1)
		begin: SR
				bullet_SR (CLOCK_50, shootUpdate[i], shoot, bulletInfo[i], shootPassed[i]);
		end
	endgenerate
			
	
	
	wire [7:0] x_bullet [0:24];	// x_positions of 25 bullets
	reg [6:0] y_bullet [0:24]; // y position of 25 bullets
	
	// Timing control of bullets -- prevents user from shooting multiple bullets by pressing down "shoot" button
	// must release first in order to shoot another bullet.
	reg [24:0] shootdelayCount;
	reg releaseFlag;

	always @ (posedge CLOCK_50) 
	begin 
	if (shoot) begin
		if (shootUpdate)releaseFlag <= 1;
		end
	else if (~shoot) releaseFlag <= 0;
	end // End timing control of bullets		
	
	// Send bullet to appropriate bullet shift register
	always @ (posedge CLOCK_50)		
	begin
	// Delays 1 second before checking for another bullet. 
	// Prevents many bullets from appearing on the screen at once.
	
	// Bullet will appear in the appropriate bullet shift register based on the 
	// cat's (x,y) coordinate.
		if (shootdelayCount==23'd500000000) begin				
			if ((shoot)&(~releaseFlag)) begin
				if ((y_cat >=0)&(y_cat<=4))shootUpdate[0] <= 1;	
				else if ((y_cat >=4)&(y_cat<=8)) shootUpdate[1] <= 1;	
				else if ((y_cat >=9)&(y_cat<=12)) shootUpdate[2] <= 1;	
				else if ((y_cat >=13)&(y_cat<=16)) shootUpdate[3] <= 1;	
				else if ((y_cat >=17)&(y_cat<=20)) shootUpdate[4] <= 1;	
				else if ((y_cat >=21)&(y_cat<=24)) shootUpdate[5] <= 1;	
				else if ((y_cat >=25)&(y_cat<=28)) shootUpdate[6] <= 1;	
				else if ((y_cat >=29)&(y_cat<=32)) shootUpdate[7] <= 1;	
				else if ((y_cat >=33)&(y_cat<=36)) shootUpdate[8] <= 1;	
				else if ((y_cat >=37)&(y_cat<=40)) shootUpdate[9] <= 1;	
				else if ((y_cat >=41)&(y_cat<=44)) shootUpdate[10] <= 1;	
				else if ((y_cat >=45)&(y_cat<=48)) shootUpdate[11] <= 1;	
				else if ((y_cat >=49)&(y_cat<=52)) shootUpdate[12] <= 1;	
				else if ((y_cat >=53)&(y_cat<=56)) shootUpdate[13] <= 1;	
				else if ((y_cat >=57)&(y_cat<=60)) shootUpdate[14] <= 1;	
				else if ((y_cat >=61)&(y_cat<=64)) shootUpdate[15] <= 1;	
				else if ((y_cat >=65)&(y_cat<=68)) shootUpdate[16] <= 1;	
				else if ((y_cat >=69)&(y_cat<=72)) shootUpdate[17] <= 1;	
				else if ((y_cat >=73)&(y_cat<=76)) shootUpdate[18] <= 1;	
				else if ((y_cat >=77)&(y_cat<=80)) shootUpdate[19] <= 1;	
				else if ((y_cat >=81)&(y_cat<=84)) shootUpdate[20] <= 1;	
				else if ((y_cat >=85)&(y_cat<=88)) shootUpdate[21] <= 1;	
				else if ((y_cat >=89)&(y_cat<=92)) shootUpdate[22] <= 1;	
				else if ((y_cat >=93)&(y_cat<=96)) shootUpdate[23] <= 1;	
				else if ((y_cat >=97)&(y_cat<=100)) shootUpdate[24] <= 1;
			end
			shootdelayCount <= 1;
			end
		else begin
			shootdelayCount <= shootdelayCount + 23'd1;
			shootUpdate <= 24'd0;
		end
	end	

	
	// Enable control within DISPLAY_BULLET state to control drawing bullets within each bullet shift register row
	reg [24:0]bulletRowEn;
	wire [24:0] bulletRowDone;
	reg [24:0]p;

	always @ (posedge CLOCK_50) 
	begin
	if (bulletEn) begin
		if (p==0) begin
			bulletRowEn[0] <= 1;
			if (bulletRowDone[0]) begin
				p <= p + 1;
				bulletRowEn[1] <=1;
				bulletRowEn[0] <= 0;
				end
			end
		else if (p==1) begin
			bulletRowEn[1] <= 1;
			if (bulletRowDone[1]) begin
				p <= p + 1;
				bulletRowEn[2] <=1;
				bulletRowEn[1] <= 0;
				end
			end
		else if (p==2) begin
			bulletRowEn[2] <= 1;
			if (bulletRowDone[2]) begin
				p <= p + 1;
				bulletRowEn[3] <=1;
				bulletRowEn[2] <= 0;
				end
			end
		else if (p==3) begin
			bulletRowEn[3] <= 1;
			if (bulletRowDone[3]) begin
				p <= p + 1;
				bulletRowEn[4] <=1;
				bulletRowEn[3] <= 0;
				end
			end
		else if (p==4) begin
			bulletRowEn[4] <= 1;
			if (bulletRowDone[4]) begin
				p <= p + 1;
				bulletRowEn[5] <=1;
				bulletRowEn[4] <= 0;
				end
			end
		else if (p==5) begin
			bulletRowEn[5] <= 1;
			if (bulletRowDone[5]) begin
				p <= p + 1;
				bulletRowEn[6] <=1;
				bulletRowEn[5] <= 0;
				end
			end
		else if (p==6) begin
			bulletRowEn[6] <= 1;
			if (bulletRowDone[6]) begin
				p <= p + 1;
				bulletRowEn[7] <=1;
				bulletRowEn[6] <= 0;
				end
			end
		else if (p==7) begin
			bulletRowEn[7] <= 1;
			if (bulletRowDone[7]) begin
				p <= p + 1;
				bulletRowEn[8] <=1;
				bulletRowEn[7] <= 0;
				end
			end
		else if (p==8) begin
			bulletRowEn[8] <= 1;
			if (bulletRowDone[8]) begin
				p <= p + 1;
				bulletRowEn[9] <=1;
				bulletRowEn[8] <= 0;
				end
			end
		else if (p==9) begin
			bulletRowEn[9] <= 1;
			if (bulletRowDone[9]) begin
				p <= p + 1;
				bulletRowEn[10] <=1;
				bulletRowEn[9] <= 0;
				end
			end
		else if (p==10) begin
			bulletRowEn[10] <= 1;
			if (bulletRowDone[10]) begin
				p <= p + 1;
				bulletRowEn[11] <=1;
				bulletRowEn[10] <= 0;
				end
			end
		else if (p==11) begin
			bulletRowEn[11] <= 1;
			if (bulletRowDone[11]) begin
				p <= p + 1;
				bulletRowEn[12] <=1;
				bulletRowEn[11] <= 0;
				end
			end
		else if (p==12) begin
			bulletRowEn[12] <= 1;
			if (bulletRowDone[12]) begin
				p <= p + 1;
				bulletRowEn[13] <=1;
				bulletRowEn[12] <= 0;
				end
			end
		else if (p==13) begin
			bulletRowEn[13] <= 1;
			if (bulletRowDone[13]) begin
				p <= p + 1;
				bulletRowEn[14] <=1;
				bulletRowEn[13] <= 0;
				end
			end
		else if (p==14) begin
			bulletRowEn[14] <= 1;
			if (bulletRowDone[14]) begin
				p <= p + 1;
				bulletRowEn[15] <=1;
				bulletRowEn[14] <= 0;
				end
			end
		else if (p==15) begin
			bulletRowEn[15] <= 1;
			if (bulletRowDone[15]) begin
				p <= p + 1;
				bulletRowEn[16] <=1;
				bulletRowEn[15] <= 0;
				end
			end 
		else if (p==16) begin
			bulletRowEn[16] <= 1;
			if (bulletRowDone[16]) begin
				p <= p + 1;
				bulletRowEn[17] <=1;
				bulletRowEn[16] <= 0;
				end
			end
		else if (p==17) begin
			bulletRowEn[17] <= 1;
			if (bulletRowDone[17]) begin
				p <= p + 1;
				bulletRowEn[18] <=1;
				bulletRowEn[17] <= 0;
				end
			end
		else if (p==18) begin
			bulletRowEn[18] <= 1;
			if (bulletRowDone[18]) begin
				p <= p + 1;
				bulletRowEn[19] <=1;
				bulletRowEn[18] <= 0;
				end
			end
		else if (p==19) begin
			bulletRowEn[19] <= 1;
			if (bulletRowDone[19]) begin
				p <= p + 1;
				bulletRowEn[20] <=1;
				bulletRowEn[19] <= 0;
				end
			end
		else if (p==20) begin
			bulletRowEn[20] <= 1;
			if (bulletRowDone[20]) begin
				p <= p + 1;
				bulletRowEn[21] <=1;
				bulletRowEn[20] <= 0;
				end
			end
		else if (p==21) begin
			bulletRowEn[21] <= 1;
			if (bulletRowDone[21]) begin
				p <= p + 1;
				bulletRowEn[22] <=1;
				bulletRowEn[21] <= 0;
				end
			end
		else if (p==22) begin
			bulletRowEn[22] <= 1;
			if (bulletRowDone[22]) begin
				p <= p + 1;
				bulletRowEn[23] <=1;
				bulletRowEn[22] <= 0;
				end
			end
		else if (p==23) begin
			bulletRowEn[23] <= 1;
			if (bulletRowDone[23]) begin
				p <= p + 1;
				bulletRowEn[24] <=1;
				bulletRowEn[23] <= 0;
				end
			end
		else if (p==24) begin
			bulletRowEn[24] <= 1;
			if (bulletRowDone[24]) begin
				p <= p + 1;
				bulletDone <=1;
				bulletRowEn[24] <= 0;
				end
			end
		end
	else begin bulletDone <= 0; p <= 0; end
	end
	
	// Draw bullets to screen based on row information generated from bullet shift register
	wire [2:0] colourBULLETS [24:0];  
	
	genvar j; 
	
	generate 
		for (j = 0; j < 25; j = j +1)
		begin: drawBullet_sprite
				drawBULLET (CLOCK_50, bulletRowEn[j], bulletInfo[j], colourBULLETS[j], x_bullet[j], bulletRowDone[j]);
		end
	endgenerate	// end drawing control
	
// ************************************************************
// 
//	Invader Datapath and Display Control
// 
// ************************************************************
	
	
	//************************************************************
	//		Datapath and display control for green (alive) invaders
	//************************************************************


	reg [24:0]baddieRowEn;
	wire [24:0] baddieRowDone;
	reg [24:0] q;
	
	// Enable control within DISPLAY_INVADER state to control drawing of individal Invader sprites
	always @ (posedge CLOCK_50) 
	begin
		if (baddieEn) begin
			if (q==0) begin
				baddieRowEn[0] <= 1;
				if (baddieRowDone[0]) begin
					q <= q + 1;
					baddieRowEn[1] <= 1;
					baddieRowEn[0] <= 0;
					end
				end
			else if (q==1) begin
				baddieRowEn[1] <= 1;
				if (baddieRowDone[1]) begin
					q <= q + 1;
					baddieRowEn[2] <= 1;
					baddieRowEn[1] <= 0;
					end
				end
			else if (q==2) begin
				baddieRowEn[2] <= 1;
				if (baddieRowDone[2]) begin
					q <= q + 1;
					baddieRowEn[3] <= 1;
					baddieRowEn[2] <= 0;
					end
				end
			else if (q==3) begin
				baddieRowEn[3] <= 1;
				if (baddieRowDone[3]) begin
					q <= q + 1;
					baddieRowEn[4] <=1;
					baddieRowEn[3] <= 0;
					end
				end
			else if (q==4) begin
				baddieRowEn[4] <= 1;
				if (baddieRowDone[4]) begin
					q <= q + 1;
					baddieRowEn[5] <=1;
					baddieRowEn[4] <= 0;
					end
				end
			else if (q==5) begin
				baddieRowEn[5] <= 1;
				if (baddieRowDone[5]) begin
					q <= q + 1;
					baddieRowEn[6] <=1;
					baddieRowEn[5] <= 0;
					end
				end
			else if (q==6) begin
				baddieRowEn[6] <= 1;
				if (baddieRowDone[6]) begin
					q <= q + 1;
					invDone <=1;
					baddieRowEn[6] <= 0;
					end
				end
			end
		else begin invDone <= 0; q <= 0; end
	end 
	
	

	wire [4:0] x_invstmp [7:0];
	wire [4:0] y_invstmp [7:0];
	reg [4:0] x_invspr, y_invspr;
	wire [7:0] invAddresstemp [7:0];
	reg [7:0] invAddress;
	wire [2:0] colourINV;
	
	// Enable control within DISPLAY_INVADER -- passes (x,y) and colour information of each invader to main invader VGA signal
	// to allow for drawing/VGA writes
	always @ (posedge CLOCK_50)
	begin
	
		if (baddieRowEn[0]) begin
			invAddress <= invAddresstemp[0];
			x_invspr <= x_invstmp[0];
			y_invspr <= y_invstmp[0];
			end
		else if (baddieRowEn[1]) begin
			invAddress <= invAddresstemp[1];
			x_invspr <= x_invstmp[1];
			y_invspr <= y_invstmp[1];
			end
		else if (baddieRowEn[2]) begin
			invAddress <= invAddresstemp[2];
			x_invspr <= x_invstmp[2];
			y_invspr <= y_invstmp[2];
			end
		else if (baddieRowEn[3]) begin
			invAddress <= invAddresstemp[3];
			x_invspr <= x_invstmp[3];
			y_invspr <= y_invstmp[3];
			end
		else if (baddieRowEn[4]) begin
			invAddress <= invAddresstemp[4];
			x_invspr <= x_invstmp[4];
			y_invspr <= y_invstmp[4];
			end
		else if (baddieRowEn[5]) begin
			invAddress <= invAddresstemp[5];
			x_invspr <= x_invstmp[5];
			y_invspr <= y_invstmp[5];
			end
		else if (baddieRowEn[6]) begin
			invAddress <= invAddresstemp[6];
			x_invspr <= x_invstmp[6];
			y_invspr <= y_invstmp[6];
			end
	end
	
	
	
	
	genvar m; // Create 7 instances of green Invader sprite 
	generate 
		for (m = 0; m < 7; m = m +1)
		begin: INV
				drawINVADER (CLOCK_50, baddieRowEn[m], x_invstmp[m], y_invstmp[m], invAddresstemp[m], baddieRowDone[m]);
		end
	endgenerate
	
	
	//*********************************************************
	//		Datapath and display settings for red (dead) invaders
	//*********************************************************

	// Datapath to generate movement (x,y-coordinates) of each advancing Invader
	invSlow1_counter invader0(CLOCK_50, collisionBulletFlag[0], x_invader[0], on);	
	invFast1_counter invader1(CLOCK_50, {collisionBulletFlag[1], collisionBulletFlag[2]}, x_invader[1], on);
	invSlow2_counter invader2(CLOCK_50, {collisionBulletFlag[3], collisionBulletFlag[4], collisionBulletFlag[5]}, x_invader[2], on);	
	invSlow1_counter invader3(CLOCK_50, {collisionBulletFlag[6], collisionBulletFlag[7], collisionBulletFlag[8]}, x_invader[3], on);	
	invFast1_counter invader4(CLOCK_50, {collisionBulletFlag[9], collisionBulletFlag[10]}, x_invader[4], on);	
	invFast1_counter invader5(CLOCK_50, {collisionBulletFlag[11], collisionBulletFlag[12]}, x_invader[5], on);	
	invSlow1_counter invader6(CLOCK_50, {collisionBulletFlag[13], collisionBulletFlag[14]}, x_invader[6], on);
	
	reg 	[24:0]		deadRowEn;
	wire 	[24:0]		deadRowDone;
	reg 	[24:0]		r;
	
	// Enable control within DISPLAY_DEAD state to control drawing of individal dead Invader sprites
	always @ (posedge CLOCK_50) 
	begin
		if (deadEn) begin
			if (r==0) begin
				deadRowEn[0] <= 1;
				if (deadRowDone[0]) begin
					r <= r + 1;
					deadRowEn[1] <= 1;
					deadRowEn[0] <= 0;
					end
				end
			else if (r==1) begin
				deadRowEn[1] <= 1;
				if (deadRowDone[1]) begin
					r <= r + 1;
					deadRowEn[2] <=1;
					deadRowEn[1] <= 0;
					end
				end
			else if (r==2) begin
				deadRowEn[2] <= 1;
				if (deadRowDone[2]) begin
					r <= r + 1;
					deadRowEn[3] <=1;
					deadRowEn[2] <= 0;
					end
				end
			else if (r==3) begin
				deadRowEn[3] <= 1;
				if (deadRowDone[3]) begin
					r <= r + 1;
					deadRowEn[4] <=1;
					deadRowEn[3] <= 0;
					end
				end
			else if (r==4) begin
				deadRowEn[4] <= 1;
				if (deadRowDone[4]) begin
					r <= r + 1;
					deadRowEn[5] <=1;
					deadRowEn[4] <= 0;
					end
				end
			else if (r==5) begin
				deadRowEn[5] <= 1;
				if (deadRowDone[5]) begin
					r <= r + 1;
					deadRowEn[6] <=1;
					deadRowEn[5] <= 0;
					end
				end
			else if (r==6) begin
				deadRowEn[6] <= 1;
				if (deadRowDone[6]) begin
					r <= r + 1;
					deadRowEn[7] <=1;
					deadRowEn[6] <= 0;
					end
				end
			else if (r==7) begin
				deadRowEn[7] <= 1;
				if (deadRowDone[7]) begin
					r <= r + 1;
					deadRowEn[8] <=1;
					deadRowEn[7] <= 0;
					end
				end
			else if (r==8) begin
				deadRowEn[8] <= 1;
				if (deadRowDone[8]) begin
					r <= r + 1;
					deadRowEn[9] <=1;
					deadRowEn[8] <= 0;
					end
				end
			else if (r==9) begin
				deadRowEn[9] <= 1;
				if (deadRowDone[9]) begin
					r <= r + 1;
					deadRowEn[10] <=1;
					deadRowEn[9] <= 0;
					end
				end
			else if (r==10) begin
				deadRowEn[10] <= 1;
				if (deadRowDone[10]) begin
					r <= r + 1;
					deadRowEn[11] <=1;
					deadRowEn[10] <= 0;
					end
				end
			else if (r==11) begin
				deadRowEn[11] <= 1;
				if (deadRowDone[11]) begin
					r <= r + 1;
					deadRowEn[12] <=1;
					deadRowEn[11] <= 0;
					end
				end
			else if (r==12) begin
				deadRowEn[12] <= 1;
				if (deadRowDone[12]) begin
					r <= r + 1;
					deadRowEn[13] <=1;
					deadRowEn[12] <= 0;
					end
				end
			else if (r==13) begin
				deadRowEn[13] <= 1;
				if (deadRowDone[13]) begin
					r <= r + 1;
					deadRowEn[14] <=1;
					deadRowEn[13] <= 0;
					end
				end
			else if (r==14) begin
				deadRowEn[14] <= 1;
				if (deadRowDone[14]) begin
					r <= r + 1;
					deadDone <=1;
					deadRowEn[14] <= 0;
					end
				end
			end
		else begin deadDone <= 0; r <= 0; end
	end 
	
	
	
	
	wire [4:0] x_deadtemp [24:0];
	wire [4:0] y_deadtemp [24:0];
	wire [7:0] deadInvAddresstmp[24:0];
	wire [2:0] colourDeadInv;
	
	// Enable control within DISPLAY_DEAD -- passes (x,y) and colour information of each dead invader to main invader VGA signal
	// to allow for drawing/VGA writes
	always @ (posedge CLOCK_50)
	begin
		if (deadRowEn[0]) begin
			deadInvAddress <= deadInvAddresstmp[0];
			x_deadinvader <= x_deadtemp[0];
			y_deadinvader <= y_deadtemp[0];
			end
		else if (deadRowEn[1]) begin
			deadInvAddress <= deadInvAddresstmp[1];
			x_deadinvader <= x_deadtemp[1];
			y_deadinvader <= y_deadtemp[1];
			end
		else if (deadRowEn[2]) begin
			deadInvAddress <= deadInvAddresstmp[2];
			x_deadinvader <= x_deadtemp[2];
			y_deadinvader <= y_deadtemp[2];
			end
		else if (deadRowEn[3]) begin
			deadInvAddress <= deadInvAddresstmp[3];
			x_deadinvader <= x_deadtemp[3];
			y_deadinvader <= y_deadtemp[3];
			end
		else if (deadRowEn[4]) begin
			deadInvAddress <= deadInvAddresstmp[4];
			x_deadinvader <= x_deadtemp[4];
			y_deadinvader <= y_deadtemp[4];
			end
		else if (deadRowEn[5]) begin
			deadInvAddress <= deadInvAddresstmp[5];
			x_deadinvader <= x_deadtemp[5];
			y_deadinvader <= y_deadtemp[5];
			end
		else if (deadRowEn[6]) begin
			deadInvAddress <= deadInvAddresstmp[6];
			x_deadinvader <= x_deadtemp[6];
			y_deadinvader <= y_deadtemp[6];
			end
		else if (deadRowEn[7]) begin
			deadInvAddress <= deadInvAddresstmp[7];
			x_deadinvader <= x_deadtemp[7];
			y_deadinvader <= y_deadtemp[7];
			end
		else if (deadRowEn[8]) begin
			deadInvAddress <= deadInvAddresstmp[8];
			x_deadinvader <= x_deadtemp[8];
			y_deadinvader <= y_deadtemp[8];
			end
		else if (deadRowEn[9]) begin
			deadInvAddress <= deadInvAddresstmp[9];
			x_deadinvader <= x_deadtemp[9];
			y_deadinvader <= y_deadtemp[9];
			end
		else if (deadRowEn[10]) begin
			deadInvAddress <= deadInvAddresstmp[10];
			x_deadinvader <= x_deadtemp[10];
			y_deadinvader <= y_deadtemp[10];
			end
		else if (deadRowEn[11]) begin
			deadInvAddress <= deadInvAddresstmp[11];
			x_deadinvader <= x_deadtemp[11];
			y_deadinvader <= y_deadtemp[11];
			end
		else if (deadRowEn[12]) begin
			deadInvAddress <= deadInvAddresstmp[12];
			x_deadinvader <= x_deadtemp[12];
			y_deadinvader <= y_deadtemp[12];
			end
		else if (deadRowEn[13]) begin
			deadInvAddress <= deadInvAddresstmp[13];
			x_deadinvader <= x_deadtemp[13];
			y_deadinvader <= y_deadtemp[13];
			end
		else if (deadRowEn[14]) begin
			deadInvAddress <= deadInvAddresstmp[14];
			x_deadinvader <= x_deadtemp[14];
			y_deadinvader <= y_deadtemp[14];
			end
	end
	
	reg [4:0] x_deadinvader, y_deadinvader;
	reg [7:0] deadInvAddress;
	reg deadDone;
	
	genvar k; 	// Create 15 instances of red Dead Invader sprite (one for each possible bullet collision)
	generate 
		for (k = 0; k < 15; k = k +1)
		begin: deadINV
				drawDEADINVADER (CLOCK_50, deadRowEn[k], x_deadtemp[k], y_deadtemp[k], deadInvAddresstmp[k], deadRowDone[k]);
		end
	endgenerate
	
	
// ************************************************************
// 
//	Collision Control
// 
// ************************************************************

	wire [24:0] collisionBulletFlag;
	wire [7:0] collisionEarthFlag;
	wire [7:0] watchCoords [24:0];
	wire [7:0] collisionCoords_B [24:0];
	wire [7:0] collisionCoords_E [24:0];
	
	// Collision check - Invader + Bullet
	invSlowBullet_collision checkBullet0 (CLOCK_50, bulletInfo[0],  x_invader[0], collisionBulletFlag[0], watchCoords[0], collisionCoords_B[0]);	// Bullet 0 collision on Invader 0
	invFastBullet_collision checkBullet2 (CLOCK_50, bulletInfo[2],  x_invader[1], collisionBulletFlag[1], watchCoords[1], collisionCoords_B[1]);  // Bullet 2 collision on Invader 1
	invFastBullet_collision checkBullet3 (CLOCK_50, bulletInfo[3],  x_invader[1], collisionBulletFlag[2], watchCoords[2], collisionCoords_B[2]);  // Bullet 3 collision on Invader 1
	invSlowBullet_collision checkBullet5 (CLOCK_50, bulletInfo[5],  x_invader[2], collisionBulletFlag[3], watchCoords[3], collisionCoords_B[3]);  // Bullet 5 collision on Invader 2
	invSlowBullet_collision checkBullet6 (CLOCK_50, bulletInfo[6],  x_invader[2], collisionBulletFlag[4], watchCoords[4], collisionCoords_B[4]);  // Bullet 6 collision on Invader 2
	invSlowBullet_collision checkBullet7 (CLOCK_50, bulletInfo[7],  x_invader[2], collisionBulletFlag[5], watchCoords[5], collisionCoords_B[5]);  // Bullet 7 collision on Invader 2
	invSlowBullet_collision checkBullet8 (CLOCK_50, bulletInfo[8],  x_invader[3], collisionBulletFlag[6], watchCoords[6], collisionCoords_B[6]);  // Bullet 8 collision on Invader 3
	invSlowBullet_collision checkBullet9 (CLOCK_50, bulletInfo[9],  x_invader[3], collisionBulletFlag[7], watchCoords[7], collisionCoords_B[7]);  // Bullet 9 collision on Invader 3
	invSlowBullet_collision checkBullet10 (CLOCK_50, bulletInfo[10],  x_invader[3], collisionBulletFlag[8], watchCoords[8], collisionCoords_B[8]);  // Bullet 9 collision on Invader 3
	invFastBullet_collision checkBullet12 (CLOCK_50, bulletInfo[12],  x_invader[4], collisionBulletFlag[9], watchCoords[9], collisionCoords_B[9]);  // Bullet 12 collision on Invader 4
	invFastBullet_collision checkBullet13 (CLOCK_50, bulletInfo[13],  x_invader[4], collisionBulletFlag[10], watchCoords[10], collisionCoords_B[10]);  // Bullet 13 collision on Invader 4
	invFastBullet_collision checkBullet15 (CLOCK_50, bulletInfo[15],  x_invader[5], collisionBulletFlag[11], watchCoords[11], collisionCoords_B[11]);  // Bullet 15 collision on Invader 5
	invFastBullet_collision checkBullet16 (CLOCK_50, bulletInfo[16],  x_invader[5], collisionBulletFlag[12], watchCoords[12], collisionCoords_B[12]);  // Bullet 16 collision on Invader 5
	invSlowBullet_collision checkBullet18 (CLOCK_50, bulletInfo[18],  x_invader[6], collisionBulletFlag[13], watchCoords[13], collisionCoords_B[13]); 	// Bullet 18 collision on Invader 6
	invSlowBullet_collision checkBullet19 (CLOCK_50, bulletInfo[19],  x_invader[6], collisionBulletFlag[14], watchCoords[14], collisionCoords_B[14]); 	// Bullet 19 collision on Invader 6
	

	// Death animation flag -- if a collision occurs, raise flag for death animation at the appropriate invader
	always @ (posedge CLOCK_50)
	begin
	
		if (collisionBulletFlag[0]) redOn[0]<=1;
		else redOn[0] <= 0;
		
		if (collisionBulletFlag[1]) redOn[1]<=1;
		else redOn[1] <= 0;
		
		if (collisionBulletFlag[2]) redOn[2]<=1;
		else redOn[2] <= 0;
		
		if (collisionBulletFlag[3]) redOn[3]<=1;
		else redOn[3] <= 0;

		if (collisionBulletFlag[4]) redOn[4]<=1;
		else redOn[4] <= 0;
		
		if (collisionBulletFlag[5]) redOn[5]<=1;
		else redOn[5] <= 0;
		
		if (collisionBulletFlag[6]) redOn[6]<=1;
		else redOn[6] <= 0;
		
		if (collisionBulletFlag[7]) redOn[7]<=1;
		else redOn[7] <= 0;
		
		if (collisionBulletFlag[8]) redOn[8]<=1;
		else redOn[8] <= 0;
		
		if (collisionBulletFlag[9]) redOn[9]<=1;
		else redOn[9] <= 0;
		
		if (collisionBulletFlag[10]) redOn[10]<=1;
		else redOn[10] <= 0;
		
		if (collisionBulletFlag[11]) redOn[11]<=1;
		else redOn[11] <= 0;
		
		if (collisionBulletFlag[12]) redOn[12]<=1;
		else redOn[12] <= 0;
		
		if (collisionBulletFlag[13]) redOn[13]<=1;
		else redOn[13] <= 0;
		
		if (collisionBulletFlag[14]) redOn[14]<=1;
		else redOn[14] <= 0;
	end
	
	
	
	
	// Counter to hold death animation for approx. 0.5 of a second;
	// 15 instances of this flag are generated, one for each possible occurance of a death animation
	reg [24:0]redOn;
	wire [24:0]eraseDeadOn;
	genvar l;	
	
	generate 
		for (l = 0; l < 15; l = l +1)
		begin: redErase
				redErase_counter (CLOCK_50, redOn[l], eraseDeadOn[l]);
		end
	endgenerate

	// Point after which invader will "disappear" after collision with earth
	reg [7:0]disappearInv;

	always @ (posedge CLOCK_50)
	begin
		if (x_invader[0] == 36) disappearInv[0] <= 1;
		else disappearInv[0] <= 0;
		
		if (x_invader[1] < 37) disappearInv[1] <= 1;
		else disappearInv[1] <= 0;
		
		if (x_invader[2] < 40) disappearInv[2] <= 1;
		else disappearInv[2] <= 0;
		
		if (x_invader[3] < 40) disappearInv[3] <= 1;
		else disappearInv[3] <= 0;
		
		if (x_invader[4] < 38) disappearInv[4] <= 1;
		else disappearInv[4] <= 0;
		
		if (x_invader[5] < 38) disappearInv[5] <= 1;
		else disappearInv[5] <= 0;
		
		if (x_invader[6] < 37) disappearInv[6] <= 1;
		else disappearInv[6] <= 0;
	end

endmodule





	

	