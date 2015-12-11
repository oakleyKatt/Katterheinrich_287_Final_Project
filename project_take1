module project_take1(clk, VGA_R,VGA_B,VGA_G,VGA_BLANK_N, VGA_SYNC_N , VGA_HS, VGA_VS, rst, VGA_CLK, Button3, Button2, Button1, Button0, restart, sbLEDA, sbLEDB, player_pause, player_new_game, win_led, lose_led);
	output [7:0] VGA_R, VGA_B, VGA_G;
   output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_CLK, VGA_SYNC_N;
	output[6:0] sbLEDA, sbLEDB;	//scoreboard 7-seg LED: sbLEDA - left-side, sbLEDB - right-side
	output win_led, lose_led;
   input clk, rst;
	input Button0, Button1, Button2, Button3;
	input restart;		//player input to restart game (SW16 on FPGA)
	input player_pause;		//player input to pause game (SW15 on FPGA)
	input player_new_game;		//player input to create a new game when they win/lose (SW14 on FPGA)
	wire WireButton0, WireButton1, WireButton2, WireButton3;
	reg player_lost, player_won;		//0= false, 1= true
	reg new_game;					//signals that the player wants a new game (via logic, not input)
	
	//game is restarted whenever a player input's a restart(SW16) or the player wins/loses and input's for a new game
	assign restartGame = (restart || ((player_lost||player_won)&&player_new_game));
	
	//pauses game when *read variable names*
	//user input decides where it goes from there
	//(the possibilities are endless, dream big champ)
	assign pause = ((player_lost)||(player_won)||player_pause);
	
   wire CLK108;
	wire [30:0]X, Y;
	wire [7:0]countRef;
	wire [31:0]countSample;
	reg [31:0] barX, barY;	//character coordinates
	reg [31:0] ballX, ballY;	//ball coordinates
	reg [31:0] ballX_Speed=32'd1,
				  ballY_Speed=32'd1;		//ball coordinate incriments
	
	reg[30:0] barCount;	//counts how many times the ball hits the player bar
	reg[30:0] countThreshold = 31'd100000;
	
	assign WireButton0=Button0;		//right 
	assign WireButton1=Button1;		//left
	assign WireButton2=Button2;		//down
	assign WireButton3=Button3;	 	//up

	//states whether the brick has been hit/'killed': 0=not, 1=kill
	//row 0
	reg b00_is_kill=1'b0,b01_is_kill=1'b0,b02_is_kill=1'b0,b03_is_kill=1'b0;
	//row 1
	reg b10_is_kill=1'b0,b11_is_kill=1'b0,b12_is_kill=1'b0,b13_is_kill=1'b0;
	//row 2
	reg b20_is_kill=1'b0,b21_is_kill=1'b0,b22_is_kill=1'b0,b23_is_kill=1'b0;
	
	//I'm like 99% sure I don't use these but my code works and i'm too afraid to delete it
	//brick coordinates AB: A-row, B-column
	reg[31:0] brick00X, brick00Y;	
	reg[31:0] brick01X, brick01Y;	
	reg[31:0] brick02X, brick02Y;	
	reg[31:0] brick03X, brick03Y;	
	
	//RGB values assigned in sequential block (color for pixel based on localparam's of in-game objects)
	reg[7:0] red;
	reg[7:0] blue;
	reg[7:0] green;
	
	parameter	BAR_WIDTH = 31'd200,
					BAR_HEIGHT = 31'd25,
					BAR_Y = 31'd950,
					BALL_WIDTH = 31'd25,
					BALL_HEIGHT = 31'd25,
					RIGHT = 1'b1,
					LEFT = 1'b0,
					UP = 1'b1,
					DOWN = 1'b0,
					BRICK_WIDTH = 32'd290,
					BRICK_HEIGHT = 32'd50,
					ROW0_Y = 32'd0,
					B00X = 32'd100,
					B01X = 32'd395,
					B02X = 32'd690,
					B03X = 32'd985,
					ROW1_Y = 32'd65,
					B10X = 32'd100,
					B11X = 32'd395,
					B12X = 32'd690,
					B13X = 32'd985,
					ROW2_Y = 32'd130,
					B20X = 32'd100,
					B21X = 32'd395,
					B22X = 32'd690,
					B23X = 32'd985,
					MAP_L = 31'd100,
					MAP_R = 31'd1275,
					MAP_T = 31'd5,
					MAP_B = 31'd1010;
					
	//the excess screen not used is filled with black
	assign Border = (X>MAP_R);
	
	//decides if current pixel(X,Y) is used for character
	localparam Bar_L = 31'd0;
	localparam Bar_R = Bar_L+BAR_WIDTH;
	localparam Bar_T = 31'd950;
	localparam Bar_B = Bar_T+BAR_HEIGHT;
	assign Bar = ((X>=(Bar_L + barX))&&(X<=(Bar_R + barX))&&(Y>=Bar_T)&&(Y<=Bar_B));
	
	//decides if current pixel(X,Y) is used for ball
	localparam Ball_L= 31'd0;
	localparam Ball_R= Ball_L+BALL_WIDTH;
	localparam Ball_T= 31'd0;
	localparam Ball_B=Ball_T+BALL_HEIGHT;
	assign Ball=((X>=Ball_L + ballX)&&(X<=Ball_R + ballX)&&(Y>=Ball_T+ ballY)&&(Y<=Ball_B+ ballY));
	
	assign GoLeft = (ballX>=MAP_R&&ballDirectionX==RIGHT);
	assign GoRight = (ballX<=MAP_L&&ballDirectionX==LEFT);
	assign GoDown = (ballY<=MAP_T&&ballDirectionY==UP);
	assign GoUp = (ballY>=MAP_B&&ballDirectionY==DOWN);	//=1 -> player loses
	//assign BarLeft = (((ballX>=barX)&&(ballX<(barX+(BAR_WIDTH/2))))&&ballDirectionY==DOWN);
	//assign BarRight = (((ballX>=barX+(BAR_WIDTH/2))&&(ballX<=barX+BAR_WIDTH))&&ballDirectionY==DOWN);

	assign BarLeft = ((((ballX>=barX)&&ballX<barX+(BAR_WIDTH/2))||((ballX+BALL_WIDTH>=barX)&&ballX+BALL_WIDTH<barX+(BAR_WIDTH/2))) && (((ballY<=Bar_T)&&(ballY>=Bar_T))||(((ballY+BALL_HEIGHT<=Bar_T)&&(ballY+BALL_HEIGHT>=Bar_T))))&&(ballDirectionY==DOWN));
	assign BarRight = (((ballX>=barX+(BAR_WIDTH/2))&&(ballX<=(barX+BAR_WIDTH)))&&((ballY<=Bar_T)&&(ballY>=Bar_T))&&(ballDirectionY==DOWN));	
//	assign BarLeft = (((ballX>=barX)&&ballX<barX+(BAR_WIDTH/2))&&((ballY<=Bar_T)&&(ballY>=Bar_T))&&ballDirectionY==DOWN);
//	assign BarRight = (((ballX>=barX+(BAR_WIDTH/2))&&(ballX<=(barX+BAR_WIDTH)))&&((ballY<=Bar_T)&&(ballY>=Bar_T))&&ballDirectionY==DOWN);

//	//(ballY>=31'd1000 && (barX<=ballX) &&(barX+31'd100)>=(ballX+31'd10)
	//ball direction
	reg ballDirectionX;	//0=left, 1=right
	reg ballDirectionY;	//0=down, 1=up
	
//ROW 0 BRICK DISPLAY/////////////////////////////////////////////////////////////////////////////////////
	//decides if current pixel(X,Y) is used for a brick
	localparam Brick00_L = B00X;
	localparam Brick00_R = Brick00_L+BRICK_WIDTH;
	localparam Brick01_L = B01X;
	localparam Brick01_R = Brick01_L+BRICK_WIDTH;
	localparam Brick02_L = B02X;
	localparam Brick02_R = Brick02_L+BRICK_WIDTH;
	localparam Brick03_L = B03X;
	localparam Brick03_R = Brick03_L+BRICK_WIDTH;
	localparam Brick0_T = ROW0_Y;
	localparam Brick0_B = Brick0_T+BRICK_HEIGHT;
	assign Brick00 = (((X>=Brick00_L)&&(X<=Brick00_R)&&(Y>=Brick0_T)&&(Y<=Brick0_B)));
	assign Brick01 = (((X>=Brick01_L)&&(X<=Brick01_R)&&(Y>=Brick0_T)&&(Y<=Brick0_B)));
	assign Brick02 = (((X>=Brick02_L)&&(X<=Brick02_R)&&(Y>=Brick0_T)&&(Y<=Brick0_B)));
	assign Brick03 = (((X>=Brick03_L)&&(X<=Brick03_R)&&(Y>=Brick0_T)&&(Y<=Brick0_B)));
//checks bottom of brick
	//					(checks ball (x,y) corner)		||		(checks ball (x+width,y) corner (other top corner))
	assign B00B = (((ballX>=Brick00_L&&ballX<=Brick00_R)||(ballX+BALL_WIDTH>=Brick00_L&&ballX+BALL_WIDTH<=Brick00_R))&&((ballY>=Brick0_B)&&(ballY<=Brick0_B)) && (b00_is_kill==1'b0));
	assign B01B = (((ballX>=Brick01_L&&ballX<=Brick01_R)||(ballX+BALL_WIDTH>=Brick01_L&&ballX+BALL_WIDTH<=Brick01_R))&&((ballY>=Brick0_B)&&(ballY<=Brick0_B)) && (b01_is_kill==1'b0));
	assign B02B = (((ballX>=Brick02_L&&ballX<=Brick02_R)||(ballX+BALL_WIDTH>=Brick02_L&&ballX+BALL_WIDTH<=Brick02_R))&&((ballY>=Brick0_B)&&(ballY<=Brick0_B)) && (b02_is_kill==1'b0));
	assign B03B = (((ballX>=Brick03_L&&ballX<=Brick03_R)||(ballX+BALL_WIDTH>=Brick03_L&&ballX+BALL_WIDTH<=Brick03_R))&&((ballY>=Brick0_B)&&(ballY<=Brick0_B)) && (b03_is_kill==1'b0));
//checks left side of brick 
	assign B00L = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX>=Brick00_L)&&(ballX<=Brick00_L))&&(b00_is_kill==1'b0));
	assign B01L = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX>=Brick01_L)&&(ballX<=Brick01_L))&&(b01_is_kill==1'b0));
	assign B02L = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX>=Brick02_L)&&(ballX<=Brick02_L))&&(b02_is_kill==1'b0));
	assign B03L = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX>=Brick03_L)&&(ballX<=Brick03_L))&&(b03_is_kill==1'b0));
//checks right side of brick
	assign B00R = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX+BALL_WIDTH>=Brick00_R)&&(ballX+BALL_WIDTH<=Brick00_R))&&(b00_is_kill==1'b0));
	assign B01R = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX+BALL_WIDTH>=Brick01_R)&&(ballX+BALL_WIDTH<=Brick01_R))&&(b01_is_kill==1'b0));
	assign B02R = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX+BALL_WIDTH>=Brick02_R)&&(ballX+BALL_WIDTH<=Brick02_R))&&(b02_is_kill==1'b0));
	assign B03R = (((ballY>=Brick0_B&&ballY<=Brick0_T)||(ballY+BALL_HEIGHT>=Brick0_B&&ballY+BALL_HEIGHT<=Brick0_T))&&((ballX+BALL_WIDTH>=Brick03_R)&&(ballX+BALL_WIDTH<=Brick03_R))&&(b03_is_kill==1'b0));
//General 'sensor' for brick being hit (on any side)
	assign B00 = (B00B||B00L||B00R);
	assign B01 = (B01B||B01L||B01R);
	assign B02 = (B02B||B02L||B02R);
	assign B03 = (B03B||B03L||B03R);

//checks top of brick
//^^^^^DON'T NEED, leaving comment for reminder in case I try to be a dumbass (which will most likely happen)

//ROW 1 BRICK DISPLAY/////////////////////////////////////////////////////////////////////////////////////
//decides if current pixel(X,Y) is used for a brick
	localparam Brick10_L = B10X;
	localparam Brick10_R = Brick10_L+BRICK_WIDTH;
	localparam Brick11_L = B11X;
	localparam Brick11_R = Brick11_L+BRICK_WIDTH;
	localparam Brick12_L = B12X;
	localparam Brick12_R = Brick12_L+BRICK_WIDTH;
	localparam Brick13_L = B13X;
	localparam Brick13_R = Brick13_L+BRICK_WIDTH;
	localparam Brick1_T = ROW1_Y;
	localparam Brick1_B = Brick1_T+BRICK_HEIGHT;
	assign Brick10 = (((X>=Brick10_L)&&(X<=Brick10_R)&&(Y>=Brick1_T)&&(Y<=Brick1_B)));
	assign Brick11 = (((X>=Brick11_L)&&(X<=Brick11_R)&&(Y>=Brick1_T)&&(Y<=Brick1_B)));
	assign Brick12 = (((X>=Brick12_L)&&(X<=Brick12_R)&&(Y>=Brick1_T)&&(Y<=Brick1_B)));
	assign Brick13 = (((X>=Brick13_L)&&(X<=Brick13_R)&&(Y>=Brick1_T)&&(Y<=Brick1_B)));
//checks bottom of brick
	assign B10B = (((ballX>=Brick10_L&&ballX<=Brick10_R)||(ballX+BALL_WIDTH>=Brick10_L&&ballX+BALL_WIDTH<=Brick10_R))&&((ballY>=Brick1_B)&&(ballY<=Brick1_B)) && (b10_is_kill==1'b0));
	assign B11B = (((ballX>=Brick11_L&&ballX<=Brick10_R)||(ballX+BALL_WIDTH>=Brick11_L&&ballX+BALL_WIDTH<=Brick11_R))&&((ballY>=Brick1_B)&&(ballY<=Brick1_B)) && (b11_is_kill==1'b0));
	assign B12B = (((ballX>=Brick12_L&&ballX<=Brick10_R)||(ballX+BALL_WIDTH>=Brick12_L&&ballX+BALL_WIDTH<=Brick12_R))&&((ballY>=Brick1_B)&&(ballY<=Brick1_B)) && (b12_is_kill==1'b0));
	assign B13B = (((ballX>=Brick13_L&&ballX<=Brick10_R)||(ballX+BALL_WIDTH>=Brick13_L&&ballX+BALL_WIDTH<=Brick13_R))&&((ballY>=Brick1_B)&&(ballY<=Brick1_B)) && (b13_is_kill==1'b0));
//checks left side of brick 
	assign B10L = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX>=Brick10_L)&&(ballX<=Brick10_L))&&(b10_is_kill==1'b0));
	assign B11L = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX>=Brick11_L)&&(ballX<=Brick11_L))&&(b11_is_kill==1'b0));
	assign B12L = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX>=Brick12_L)&&(ballX<=Brick12_L))&&(b12_is_kill==1'b0));
	assign B13L = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX>=Brick13_L)&&(ballX<=Brick13_L))&&(b13_is_kill==1'b0));
//checks right side of brick
	assign B10R = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX+BALL_WIDTH>=Brick10_R)&&(ballX+BALL_WIDTH<=Brick10_R))&&(b10_is_kill==1'b0));
	assign B11R = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX+BALL_WIDTH>=Brick11_R)&&(ballX+BALL_WIDTH<=Brick11_R))&&(b11_is_kill==1'b0));
	assign B12R = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX+BALL_WIDTH>=Brick12_R)&&(ballX+BALL_WIDTH<=Brick12_R))&&(b12_is_kill==1'b0));
	assign B13R = (((ballY>=Brick1_B&&ballY<=Brick1_T)||(ballY+BALL_HEIGHT>=Brick1_B&&ballY+BALL_HEIGHT<=Brick1_T))&&((ballX+BALL_WIDTH>=Brick13_R)&&(ballX+BALL_WIDTH<=Brick13_R))&&(b13_is_kill==1'b0));
//checks top of brick
	assign B10T = (((ballX>=Brick10_L&&ballX<=Brick10_R)||(ballX+BALL_WIDTH>=Brick10_L&&ballX+BALL_WIDTH<=Brick10_R))&&((ballY>=Brick1_T)&&(ballY<=Brick1_T))&&(b10_is_kill==1'b0));
	assign B11T = (((ballX>=Brick11_L&&ballX<=Brick11_R)||(ballX+BALL_WIDTH>=Brick11_L&&ballX+BALL_WIDTH<=Brick11_R))&&((ballY>=Brick1_T)&&(ballY<=Brick1_T))&&(b11_is_kill==1'b0));
	assign B12T = (((ballX>=Brick12_L&&ballX<=Brick12_R)||(ballX+BALL_WIDTH>=Brick12_L&&ballX+BALL_WIDTH<=Brick12_R))&&((ballY>=Brick1_T)&&(ballY<=Brick1_T))&&(b12_is_kill==1'b0));
	assign B13T = (((ballX>=Brick13_L&&ballX<=Brick13_R)||(ballX+BALL_WIDTH>=Brick13_L&&ballX+BALL_WIDTH<=Brick13_R))&&((ballY>=Brick1_T)&&(ballY<=Brick1_T))&&(b13_is_kill==1'b0));
//General 'sensor' for brick being hit (on any side)
	assign B10 = (B10B||B10L||B10R||B10T);
	assign B11 = (B11B||B11L||B11R||B11T);
	assign B12 = (B12B||B12L||B12R||B12T);
	assign B13 = (B13B||B13L||B13R||B13T);
	
//ROW 2 BRICK DISPLAY/////////////////////////////////////////////////////////////////////////////////////
//decides if current pixel(X,Y) is used for a brick
	localparam Brick20_L = B20X;
	localparam Brick20_R = Brick20_L+BRICK_WIDTH;
	localparam Brick21_L = B21X;
	localparam Brick21_R = Brick21_L+BRICK_WIDTH;
	localparam Brick22_L = B22X;
	localparam Brick22_R = Brick22_L+BRICK_WIDTH;
	localparam Brick23_L = B23X;
	localparam Brick23_R = Brick23_L+BRICK_WIDTH;
	localparam Brick2_T = ROW2_Y;
	localparam Brick2_B = Brick2_T+BRICK_HEIGHT;
	assign Brick20 = (((X>=Brick20_L)&&(X<=Brick20_R)&&(Y>=Brick2_T)&&(Y<=Brick2_B)));
	assign Brick21 = (((X>=Brick21_L)&&(X<=Brick21_R)&&(Y>=Brick2_T)&&(Y<=Brick2_B)));
	assign Brick22 = (((X>=Brick22_L)&&(X<=Brick22_R)&&(Y>=Brick2_T)&&(Y<=Brick2_B)));
	assign Brick23 = (((X>=Brick23_L)&&(X<=Brick23_R)&&(Y>=Brick2_T)&&(Y<=Brick2_B)));
//checks bottom of brick
	assign B20B = (((ballX>=Brick20_L&&ballX<=Brick20_R)||(ballX+BALL_WIDTH>=Brick20_L&&ballX+BALL_WIDTH<=Brick20_R))&&((ballY>=Brick2_B)&&(ballY<=Brick2_B)) && (b20_is_kill==1'b0));
	assign B21B = (((ballX>=Brick21_L&&ballX<=Brick21_R)||(ballX+BALL_WIDTH>=Brick21_L&&ballX+BALL_WIDTH<=Brick21_R))&&((ballY>=Brick2_B)&&(ballY<=Brick2_B)) && (b21_is_kill==1'b0));
	assign B22B = (((ballX>=Brick22_L&&ballX<=Brick22_R)||(ballX+BALL_WIDTH>=Brick22_L&&ballX+BALL_WIDTH<=Brick22_R))&&((ballY>=Brick2_B)&&(ballY<=Brick2_B)) && (b22_is_kill==1'b0));
	assign B23B = (((ballX>=Brick23_L&&ballX<=Brick23_R)||(ballX+BALL_WIDTH>=Brick23_L&&ballX+BALL_WIDTH<=Brick23_R))&&((ballY>=Brick2_B)&&(ballY<=Brick2_B)) && (b23_is_kill==1'b0));
//checks left side of brick 
	assign B20L = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX>=Brick20_L)&&(ballX<=Brick20_L))&&(b20_is_kill==1'b0));
	assign B21L = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX>=Brick21_L)&&(ballX<=Brick21_L))&&(b21_is_kill==1'b0));
	assign B22L = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX>=Brick22_L)&&(ballX<=Brick22_L))&&(b22_is_kill==1'b0));
	assign B23L = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX>=Brick23_L)&&(ballX<=Brick23_L))&&(b23_is_kill==1'b0));
//checks right side of brick
	assign B20R = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX+BALL_WIDTH>=Brick20_R)&&(ballX+BALL_WIDTH<=Brick20_R))&&(b20_is_kill==1'b0));
	assign B21R = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX+BALL_WIDTH>=Brick21_R)&&(ballX+BALL_WIDTH<=Brick21_R))&&(b21_is_kill==1'b0));
	assign B22R = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX+BALL_WIDTH>=Brick22_R)&&(ballX+BALL_WIDTH<=Brick22_R))&&(b22_is_kill==1'b0));
	assign B23R = (((ballY>=Brick2_B&&ballY<=Brick2_T)||(ballY+BALL_HEIGHT>=Brick2_B&&ballY+BALL_HEIGHT<=Brick2_T))&&((ballX+BALL_WIDTH>=Brick23_R)&&(ballX+BALL_WIDTH<=Brick23_R))&&(b23_is_kill==1'b0));
//checks top of brick
	assign B20T = (((ballX>=Brick20_L&&ballX<=Brick20_R)||(ballX+BALL_WIDTH>=Brick20_L&&ballX+BALL_WIDTH<=Brick20_R))&&((ballY>=Brick2_T)&&(ballY<=Brick2_T))&&(b20_is_kill==1'b0));
	assign B21T = (((ballX>=Brick21_L&&ballX<=Brick21_R)||(ballX+BALL_WIDTH>=Brick21_L&&ballX+BALL_WIDTH<=Brick21_R))&&((ballY>=Brick2_T)&&(ballY<=Brick2_T))&&(b21_is_kill==1'b0));
	assign B22T = (((ballX>=Brick22_L&&ballX<=Brick22_R)||(ballX+BALL_WIDTH>=Brick22_L&&ballX+BALL_WIDTH<=Brick22_R))&&((ballY>=Brick2_T)&&(ballY<=Brick2_T))&&(b22_is_kill==1'b0));
	assign B23T = (((ballX>=Brick23_L&&ballX<=Brick23_R)||(ballX+BALL_WIDTH>=Brick23_L&&ballX+BALL_WIDTH<=Brick23_R))&&((ballY>=Brick2_T)&&(ballY<=Brick2_T))&&(b23_is_kill==1'b0));
//General 'sensor' for brick being hit (on any side)
	assign B20 = (B20B||B20L||B20R||B20T);
	assign B21 = (B21B||B21L||B21R||B21T);
	assign B22 = (B22B||B22L||B22R||B22T);
	assign B23 = (B23B||B23L||B23R||B23T);
//////////////////////////////////////////////////////////////////////////////////////	
	//calling counter (~?)
	//countRef if(X&Y = 0) countRef++
	//			else if(countRef = 7'd11) countRef = 0
	//			else	countRef = countRef
	countingRefresh(X,Y, clk ,countRef);
	
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////ROW REGISTERS - HOLD EACH BRICK'S 'KILL' STATUS (WHETHER BRICK IS DISPLAYED OR NOT)/////////
//ROW 0 REGISTER/////////////////////////////////////////////////////////////////////////////////////
	assign Write_en0 = (B00||B01||B02||B03);	//if any brick+ball contact -> write enabled (=1)
	//Address: 00- blank, 01- row0, 10- row1, 11- row2
	reg[1:0] WrAddr0 = 2'b01;
	reg[1:0] RdAddr0 = 2'b01;
	//0(left) -> 3(right) Brick in row... I think...? Just don't mess with it.
	wire[3:0] WrData0;
	assign WrData0 = {B00, B01, B02, B03};
	wire[3:0] RdData0;

//ROW 1 REGISTER/////////////////////////////////////////////////////////////////////////////////////
	assign Write_en1 = (B10||B11||B12||B13);	//if any brick+ball contact -> write enabled (=1)
	//00- blank, 01- row0, 10- row1, 11- row2
	reg[1:0] WrAddr1 = 2'b10;
	reg[1:0] RdAddr1 = 2'b10;
	//0(left) -> 3(right) Brick in row
	wire[3:0] WrData1;
	assign WrData1 = {B10, B11, B12, B13};
	wire[3:0] RdData1;
	
//ROW 2 REGISTER/////////////////////////////////////////////////////////////////////////////////////
	assign Write_en2 = (B20||B21||B22||B23);	//if any brick+ball contact -> write enabled (=1)
	//00- blank, 01- row0, 10- row1, 11- row2
	reg[1:0] WrAddr2 = 2'b11;
	reg[1:0] RdAddr2 = 2'b11;
	//0(left) -> 3(right) Brick in row
	wire[3:0] WrData2;
	assign WrData2 = {B20, B21, B22, B23};
	wire[3:0] RdData2;
	

	//input clock, write, input [1:0] WrAddrA, RdAddrA, input [3:0] WrDataA, output [3:0] RdDataA
	Register bricks_row0(clk, restartGame, Write_en0, WrAddr0, RdAddr0, WrData0, RdData0);
	Register bricks_row1(clk, restartGame, Write_en1, WrAddr1, RdAddr1, WrData1, RdData1);
	Register bricks_row2(clk, restartGame, Write_en2, WrAddr2, RdAddr2, WrData2, RdData2);
	
/////////////////////////////////////////////////////////////////////////////////////////////////////
	
	
	//let the clock do it's thing
   clock108(rst, clk, CLK_108, locked);
	
	wire hblank, vblank, clkLine, blank;
	
	//output VGA_HS, hblank, clkLine, X
   H_SYNC(CLK_108, VGA_HS, hblank, clkLine, X);
	 
	//output VGA_VS, vblank, Y
   V_SYNC(clkLine, VGA_VS, vblank, Y);
	
	//assigns current pixel with color according to localparam (above)
	always@(*)
	begin
		//bar- black
		if(Bar)
		begin
			red = 8'd0;
			green = 8'd0;
			blue = 8'd0;
			//game_over = 1'b0;
		end
		else if(Ball)
		begin
			red = 8'd0;
			green = 8'd0;
			blue = 8'd0;
			//game_over = 1'b0;
		end
/////////Bricks: Row 0 - Red//////////////
		else if(Brick00 && RdData0[3]==1'b0)
		begin
			red = 31'd255;
			green = 31'd0;
			blue = 31'd0;
		end
		else if(Brick01 && RdData0[2]==1'b0)
		begin
			red = 31'd255;
			green = 31'd0;
			blue = 31'd0;
		end
		else if(Brick02 && RdData0[1]==1'b0)
		begin
			red = 31'd255;
			green = 31'd0;
			blue = 31'd0;
		end
		else if(Brick03 && RdData0[0]==1'b0)
		begin
			red = 31'd255;
			green = 31'd0;
			blue = 31'd0;
		end
/////////Bricks: Row 1 - Green////////////
		else if(Brick10 && RdData1[3]==1'b0)
		begin
			red = 31'd0;
			green = 31'd255;
			blue = 31'd0;
		end
		else if(Brick11 && RdData1[2]==1'b0)
		begin
			red = 31'd0;
			green = 31'd255;
			blue = 31'd0;
		end
		else if(Brick12 && RdData1[1]==1'b0)
		begin
			red = 31'd0;
			green = 31'd255;
			blue = 31'd0;
		end
		else if(Brick13 && RdData1[0]==1'b0)
		begin
			red = 31'd0;
			green = 31'd255;
			blue = 31'd0;
		end
//////////Bricks: Row 2 - Blue////////////
		else if(Brick20 && RdData2[3]==1'b0)
		begin
			red = 31'd0;
			green = 31'd0;
			blue = 31'd255;
		end
		else if(Brick21 && RdData2[2]==1'b0)
		begin
			red = 31'd0;
			green = 31'd0;
			blue = 31'd255;
		end
		else if(Brick22 && RdData2[1]==1'b0)
		begin
			red = 31'd0;
			green = 31'd0;
			blue = 31'd255;
		end
		else if(Brick23 && RdData2[0]==1'b0)
		begin
			red = 31'd0;
			green = 31'd0;
			blue = 31'd255;
		end
/////BORDER FILL - BLACK/////
		else if(Border)
		begin
			red = 31'd0;
			green = 31'd0;
			blue = 31'd0;
		end
/////WHITE BACKGROUND/////
		else
		begin
			red = 8'd255;
			green = 8'd255;
			blue = 8'd255;
		end

/////Determines whether the player has won/lost
		if(RdData0==4'b1111 && RdData1==4'b1111 && RdData2==4'b1111)
		begin
			player_won = 1'b1;
		end
		else
		begin
			player_won = 1'b0;
		end
	end
	
	reg temp;
	reg [31:0]count;
	
	//user input - move character
	always@(posedge clk)	
	begin
		if(count>=countThreshold+31'd10)
		begin
			count<=0;
		end
		else
		begin
			count<=count+1;
		end
		
		//resets ball, bar, and brick values to default
		if(restartGame)
		begin
			barX <= MAP_R/2;
			ballX <= MAP_L;
			ballY <= MAP_B/2;
			ballDirectionX <= RIGHT;
			ballDirectionY <= DOWN;
			//row 0
			b00_is_kill<=1'b0;
			b01_is_kill<=1'b0;
			b02_is_kill<=1'b0;
			b03_is_kill<=1'b0;
			//row 1
			b10_is_kill<=1'b0;
			b11_is_kill<=1'b0;
			b12_is_kill<=1'b0;
			b13_is_kill<=1'b0;
			//row 2
			b20_is_kill<=1'b0;
			b21_is_kill<=1'b0;
			b22_is_kill<=1'b0;
			b23_is_kill<=1'b0;
			
			player_lost<=1'b0;
			new_game<=1'b0;
		end
		else
			temp<=temp;
		
		//game is currently running, so player hasn't won/lost or paused (via player input)
		//tried: (pause==1'b0), (pause)...----(pause==1'b1) works
		if(pause == 1'b1)
		begin
		//move right
		if(WireButton0==1'b0 && count == countThreshold)
			barX <= barX + 31'd1;
		else
			temp<=temp;
			
		//move left
		if(WireButton1==1'b0 && count == countThreshold)
			barX <= barX - 31'd1;
		else
			temp<=temp;
		
///////PLAYER BAR VERTICAL MOVEMENT////////
		//move up
//		if(WireButton2==1'b0 && count == 31'd100000)
//			barY <= barY + 31'd1;
//		else
//			temp<=temp;
			
		//move down
//		if(WireButton3==1'b0 && count == 31'd100000)
//			barY <= barY - 31'd1;
//		else
//			temp<=temp;
		
		//change directionX
//		if(GoRight||BarRight)
//			ballDirectionX<=RIGHT;
//		else if(GoLeft||BarLeft)	
//			ballDirectionX<=LEFT;
//		else
//			temp<=temp;
////////////////////////////////////////////

//CHANGE BALL HORIZONTAL DIRECTION//
		if(BarRight)
			ballDirectionX<=RIGHT;
		else if(BarLeft)
			ballDirectionX<=LEFT;
		else if(GoRight)	
			ballDirectionX<=RIGHT; 
		else if(GoLeft)	
			ballDirectionX<=LEFT;
		else if(B00R)
			ballDirectionX<=RIGHT;
		else if(B00L)
			ballDirectionX<=LEFT;
		else if(B01R)
			ballDirectionX<=RIGHT;
		else if(B01L)
			ballDirectionX<=LEFT;
		else if(B02R)
			ballDirectionX<=RIGHT;
		else if(B02L)
			ballDirectionX<=LEFT;
		else if(B03R)
			ballDirectionX<=RIGHT;
		else if(B03L)
			ballDirectionX<=LEFT;
		else if(B10R)
			ballDirectionX<=RIGHT;
		else if(B10L)
			ballDirectionX<=LEFT;
		else if(B11R)
			ballDirectionX<=RIGHT;
		else if(B11L)
			ballDirectionX<=LEFT;
		else if(B12R)
			ballDirectionX<=RIGHT;
		else if(B12L)
			ballDirectionX<=LEFT;
		else if(B13R)
			ballDirectionX<=RIGHT;
		else if(B13L)
			ballDirectionX<=LEFT;
		else if(B20R)
			ballDirectionX<=RIGHT;
		else if(B20L)
			ballDirectionX<=LEFT;
		else if(B21R)
			ballDirectionX<=RIGHT;
		else if(B21L)
			ballDirectionX<=LEFT;
		else if(B22R)
			ballDirectionX<=RIGHT;
		else if(B22L)
			ballDirectionX<=LEFT;
		else if(B23R)
			ballDirectionX<=RIGHT;
		else if(B23L)
			ballDirectionX<=LEFT;
		else
			temp<=temp;

//CHANGE BALL VERTICAL DIRECTION//
		if(BarRight)
			ballDirectionY<=UP;
		else if(BarLeft)
			ballDirectionY<=UP;
		else if(GoDown)
			ballDirectionY<=DOWN;
		else if(B00B)
			ballDirectionY<=DOWN;
		else if(B01B)
			ballDirectionY<=DOWN;
		else if(B02B)
			ballDirectionY<=DOWN;
		else if(B03B)
			ballDirectionY<=DOWN;
		else if(B10B)
			ballDirectionY<=DOWN;
		else if(B10T)
			ballDirectionY<=UP;
		else if(B11B)
			ballDirectionY<=DOWN;
		else if(B11T)
			ballDirectionY<=UP;
		else if(B12B)
			ballDirectionY<=DOWN;
		else if(B12T)
			ballDirectionY<=UP;
		else if(B13B)
			ballDirectionY<=DOWN;
		else if(B13T)
			ballDirectionY<=UP;
		else if(B20B)
			ballDirectionY<=DOWN;
		else if(B20T)
			ballDirectionY<=UP;
		else if(B21B)
			ballDirectionY<=DOWN;
		else if(B21T)
			ballDirectionY<=UP;
		else if(B22B)
			ballDirectionY<=DOWN;
		else if(B22T)
			ballDirectionY<=UP;
		else if(B23B)
			ballDirectionY<=DOWN;
		else if(B23T)
			ballDirectionY<=UP;
		else
			temp<=temp;
		
//SET BRICK_IS_KILL SO IT ISN'T DISPLAYED// 
		if(B00B)
			b00_is_kill<=1'b1;
		else if(B00L)
			b00_is_kill<=1'b1;
		else if(B00R)
			b00_is_kill<=1'b1;
		else if(B01B)
			b01_is_kill<=1'b1;
		else if(B01L)
			b01_is_kill<=1'b1;
		else if(B01R)
			b01_is_kill<=1'b1;
		else if(B02B)
			b02_is_kill<=1'b1;
		else if(B02L)
			b02_is_kill<=1'b1;
		else if(B02R)
			b02_is_kill<=1'b1;
		else if(B03B)
			b03_is_kill<=1'b1;
		else if(B03L)
			b03_is_kill<=1'b1;
		else if(B03R)
			b03_is_kill<=1'b1;
		//B10
		else if(B10B)
			b10_is_kill<=1'b1;
		else if(B10L)
			b10_is_kill<=1'b1;
		else if(B10R)
			b10_is_kill<=1'b1;
		else if(B10T)
			b10_is_kill<=1'b1;
		//B11
		else if(B11B)
			b11_is_kill<=1'b1;
		else if(B11L)
			b11_is_kill<=1'b1;
		else if(B11R)
			b11_is_kill<=1'b1;
		else if(B11T)
			b11_is_kill<=1'b1;
		//B12
		else if(B12B)
			b12_is_kill<=1'b1;
		else if(B12L)
			b12_is_kill<=1'b1;
		else if(B12R)
			b12_is_kill<=1'b1;
		else if(B12T)
			b12_is_kill<=1'b1;
		//B13
		else if(B13B)
			b13_is_kill<=1'b1;
		else if(B13L)
			b13_is_kill<=1'b1;
		else if(B13R)
			b13_is_kill<=1'b1;
		else if(B13T)
			b13_is_kill<=1'b1;
		//B20
		else if(B20B)
			b20_is_kill<=1'b1;
		else if(B20L)
			b20_is_kill<=1'b1;
		else if(B20R)
			b20_is_kill<=1'b1;
		else if(B20T)
			b20_is_kill<=1'b1;
		//B21
		else if(B21B)
			b21_is_kill<=1'b1;
		else if(B21L)
			b21_is_kill<=1'b1;
		else if(B21R)
			b21_is_kill<=1'b1;
		else if(B21T)
			b21_is_kill<=1'b1;
		//B22
		else if(B22B)
			b22_is_kill<=1'b1;
		else if(B22L)
			b22_is_kill<=1'b1;
		else if(B22R)
			b22_is_kill<=1'b1;
		else if(B22T)
			b22_is_kill<=1'b1;
		//B23
		else if(B23B)
			b23_is_kill<=1'b1;
		else if(B23L)
			b23_is_kill<=1'b1;
		else if(B23R)
			b23_is_kill<=1'b1;
		else if(B23T)
			b23_is_kill<=1'b1;
	
//PLAYER LOSE DECLARATION
		if(GoUp)
			player_lost<=1'b1;
		else
			player_lost<=1'b0;
		
//BALL SPEED STUFF THAT I FAILED FANTASTICALLY AT IMPLEMENTING//
		if(BarRight&&count==31'd100000&&ballX_Speed<=32'd6)
		begin
			ballX_Speed<=ballX_Speed+32'd1;
			ballY_Speed<=ballY_Speed+32'd1;
		end
		if(BarLeft&&count==31'd100000&&ballX_Speed<=32'd6)
		begin
			ballX_Speed<=ballX_Speed+32'd1;
			ballY_Speed<=ballY_Speed+32'd1;
		end

//ACTUAL BALL MOVEMENT - X,Y COORDINATES BEING INCRIMENTED BASED ON BALLX/YDIRECTION//
		if(count==countThreshold)
		begin
//			if(restartGame)
//			begin
//				ballX<=MAP_R/2;
//				ballY<=MAP_B/2;
//			end
//			else
//				temp<=temp;
			
			if(ballDirectionX==RIGHT)
				ballX<=ballX+ballX_Speed;
			else if(ballDirectionX==LEFT)
				ballX<=ballX-ballX_Speed;
			else
				temp<=temp;
				
			if(ballDirectionY==UP)
			begin
				//countThreshold<=countThreshold-31'd50;
				ballY<=ballY-ballY_Speed;
			end
			else if(ballDirectionY==DOWN)
				ballY<=ballY+ballY_Speed;
			else
				temp<=temp;
		end
	end
	else
		temp<=temp;
	end
	
	////////SCOREBOARD REGISTER//////////////
	wire[4:0] RdScore;
	wire[4:0] score;
	assign score = (Write_en0+Write_en0+Write_en0+Write_en1+Write_en1+Write_en2);
	assign Score_en = 1'b1;
	assign Score_Addr = 1'b1;	//address always '1'
	
	//adds to current score if any brick registers get a write_enable
	//									reset score    =1                          //output
	RegisterII scoreboard(clk, restartGame, Score_en, Score_Addr, score, RdScore);
	
	//display score onto FPGA 7-seg display
	decode_7seg(RdScore, sbLEDA, sbLEDB);
	
	//set color for current pixel
	color(clk,VGA_R,VGA_B,VGA_G,red,green,blue);
	
    assign VGA_CLK = CLK_108;
   
	assign VGA_BLANK_N = VGA_VS&VGA_HS;

	assign VGA_SYNC_N = 1'b0;
	 
endmodule

module decode_7seg(num, digitA, digitB);
	input[4:0] num;
	output[6:0] digitA, digitB;
	reg[6:0] digitA, digitB;
	reg[4:0] digit1, digit2;	//digits used to separate possible 2-digit number input
	always @(*)
	begin
		if(num<5'd10)
		begin
			digit1 = 5'd0;
			digit2 = num;
		end
		else if(num>=5'd10&&num<5'd20)
		begin
			digit1 = 5'd1;
			digit2 = num-5'd10;
		end
		else
		begin
			digit1 = 5'd2;
			digit2 = num-5'd20;
		end
		//left-side number
		case (digit1)
		  5'd0 : digitA = ~7'b0111111;	//0
		  5'd1 : digitA = ~7'b0000110;	//1
		  5'd2 : digitA = ~7'b1011011;	//2
		  5'd3 : digitA = ~7'b1001111;	//3
		  5'd4 : digitA = ~7'b1100110;	//4
		  5'd5 : digitA = ~7'b1101101;	//5
		  5'd6 : digitA = ~7'b1111101;	//6
		  5'd7 : digitA = ~7'b0000111;	//7
		  5'd8 : digitA = ~7'b1111111;	//8
		  5'd9 : digitA = ~7'b1100111;	//9
		  5'd10 : digitA = ~7'b1111001;	//10
		  5'd11 : digitA = 7'b1100000; // Value set to display r for an error message
		  default : digitA = 7'b1111111;
		endcase
		//right-side number
		case (digit2)
		  5'd0 : digitB = ~7'b0111111;	//0
		  5'd1 : digitB = ~7'b0000110;	//1
		  5'd2 : digitB = ~7'b1011011;	//2
		  5'd3 : digitB = ~7'b1001111;	//3
		  5'd4 : digitB = ~7'b1100110;	//4
		  5'd5 : digitB = ~7'b1101101;	//5
		  5'd6 : digitB = ~7'b1111101;	//6
		  5'd7 : digitB = ~7'b0000111;	//7
		  5'd8 : digitB = ~7'b1111111;	//8
		  5'd9 : digitB = ~7'b1100111;	//9
		  5'd10 : digitB = ~7'b1111001;	//10
		  5'd11 : digitB = 7'b1100000; // Value set to display r for an error message
		  default : digitB = 7'b1111111;
		endcase
	end
	
endmodule

module color(clk, vga_red, vga_blue, vga_green, red,green,blue);

     input clk;
	 input[7:0] red,green,blue;
	  //input new_game;
    output [7:0] vga_red, vga_blue, vga_green;
	 reg[7:0] vga_red, vga_blue, vga_green;
	always@(*)
	begin
		 vga_red = red;
		 vga_green = green;
		 vga_blue = blue;
	end
	 
endmodule

module countingRefresh(X, Y, clk, count);
input [31:0]X, Y;
input clk;
output [7:0]count;
reg[7:0]count;
always@(posedge clk)
begin
	if(X==0 &&Y==0)
		count<=count+1;
	else if(count==7'd11)
		count<=0;
	else
		count<=count;
end

endmodule


module H_SYNC(clk, hout, bout, newLine, Xcount);

    input clk;
    output hout, bout, newLine;
	 output [31:0] Xcount;
	 
	
    reg [31:0] count = 32'd0;
    reg hsync, blank, new1;
	 
	 //resets count at end of horizontal line
    always @(posedge clk) begin
        if (count <  1688)
            count <= Xcount + 1;
        else 
            count <= 0;
    end 
	 
	 //clkLine
	 always @(*) begin
        if (count == 0)
            new1 = 1;
        else
            new1 = 0;
    end 

	 //hblank
    always @(*) begin
        if (count > 1279) 
            blank = 1;
        else 
            blank = 0;
    end

	 //VGA_HS
    always @(*) begin
        if (count < 1328)
            hsync = 1;
        else if (count > 1327 && count < 1440)
            hsync = 0;
        else    
            hsync = 1;
    end
		  
    assign Xcount=count;		//X (coordinate)
    assign hout = hsync;		//VGA_HS
    assign bout = blank;		//hblank
    assign newLine = new1;		//clkLine

endmodule

module V_SYNC(clk, vout, bout, Ycount);

    input clk;
    output vout, bout;
    output [31:0]Ycount; 
	  
    reg [31:0] count = 32'd0;
    reg vsync, blank;

    always @(posedge clk) begin
        if (count <  1066)
            count <= Ycount + 1;
        else 
            count <= 0;
    end 

    always @(*) begin
        if (count < 1024) 
            blank = 1;
        else 
            blank = 0;
    end

    always @(*) begin
        if (count < 1025)
            vsync = 1;
        else if (count > 1024 && count < 1028)
            vsync = 0;
        else    
            vsync = 1;
        end
    assign Ycount=count;
    assign vout = vsync;
    assign bout = blank;

endmodule

 //synopsys translate_off
`timescale 1 ps / 1 ps
 //synopsys translate_on
module clock108 (areset, inclk0, c0, locked);

    input     areset;
    input     inclk0;
    output    c0;
    output    locked;

`ifndef ALTERA_RESERVED_QIS
 //synopsys translate_off
`endif

tri0      areset;

`ifndef ALTERA_RESERVED_QIS
 //synopsys translate_on
`endif

    wire [0:0] sub_wire2 = 1'h0;
    wire [4:0] sub_wire3;
    wire  sub_wire5;
    wire  sub_wire0 = inclk0;
    wire [1:0] sub_wire1 = {sub_wire2, sub_wire0};
    wire [0:0] sub_wire4 = sub_wire3[0:0];
    wire  c0 = sub_wire4;
    wire  locked = sub_wire5;

	 
	 
altpll  altpll_component (
            .areset (areset),
            .inclk (sub_wire1),
            .clk (sub_wire3),
            .locked (sub_wire5),
            .activeclock (),
            .clkbad (),
            .clkena ({6{1'b1}}),
            .clkloss (),
            .clkswitch (1'b0),
            .configupdate (1'b0),
            .enable0 (),
            .enable1 (),
            .extclk (),
            .extclkena ({4{1'b1}}),
            .fbin (1'b1),
            .fbmimicbidir (),
            .fbout (),
            .fref (),
            .icdrclk (),
            .pfdena (1'b1),
            .phasecounterselect ({4{1'b1}}),
            .phasedone (),
            .phasestep (1'b1),
            .phaseupdown (1'b1),
            .pllena (1'b1),
            .scanaclr (1'b0),
            .scanclk (1'b0),
            .scanclkena (1'b1),
            .scandata (1'b0),
            .scandataout (),
            .scandone (),
            .scanread (1'b0),
            .scanwrite (1'b0),
            .sclkout0 (),
            .sclkout1 (),
            .vcooverrange (),
            .vcounderrange ());
defparam
    altpll_component.bandwidth_type = "AUTO",
    altpll_component.clk0_divide_by = 25,
    altpll_component.clk0_duty_cycle = 50,
    altpll_component.clk0_multiply_by = 54,
    altpll_component.clk0_phase_shift = "0",
    altpll_component.compensate_clock = "CLK0",
    altpll_component.inclk0_input_frequency = 20000,
    altpll_component.intended_device_family = "Cyclone IV E",
    altpll_component.lpm_hint = "CBX_MODULE_PREFIX=clock108",
    altpll_component.lpm_type = "altpll",
    altpll_component.operation_mode = "NORMAL",
    altpll_component.pll_type = "AUTO",
    altpll_component.port_activeclock = "PORT_UNUSED",
    altpll_component.port_areset = "PORT_USED",
    altpll_component.port_clkbad0 = "PORT_UNUSED",
    altpll_component.port_clkbad1 = "PORT_UNUSED",
    altpll_component.port_clkloss = "PORT_UNUSED",
    altpll_component.port_clkswitch = "PORT_UNUSED",
    altpll_component.port_configupdate = "PORT_UNUSED",
    altpll_component.port_fbin = "PORT_UNUSED",
    altpll_component.port_inclk0 = "PORT_USED",
    altpll_component.port_inclk1 = "PORT_UNUSED",
    altpll_component.port_locked = "PORT_USED",
    altpll_component.port_pfdena = "PORT_UNUSED",
    altpll_component.port_phasecounterselect = "PORT_UNUSED",
    altpll_component.port_phasedone = "PORT_UNUSED",
    altpll_component.port_phasestep = "PORT_UNUSED",
    altpll_component.port_phaseupdown = "PORT_UNUSED",
    altpll_component.port_pllena = "PORT_UNUSED",
    altpll_component.port_scanaclr = "PORT_UNUSED",
    altpll_component.port_scanclk = "PORT_UNUSED",
    altpll_component.port_scanclkena = "PORT_UNUSED",
    altpll_component.port_scandata = "PORT_UNUSED",
    altpll_component.port_scandataout = "PORT_UNUSED",
    altpll_component.port_scandone = "PORT_UNUSED",
    altpll_component.port_scanread = "PORT_UNUSED",
    altpll_component.port_scanwrite = "PORT_UNUSED",
    altpll_component.port_clk0 = "PORT_USED",
    altpll_component.port_clk1 = "PORT_UNUSED",
    altpll_component.port_clk2 = "PORT_UNUSED",
    altpll_component.port_clk3 = "PORT_UNUSED",
    altpll_component.port_clk4 = "PORT_UNUSED",
    altpll_component.port_clk5 = "PORT_UNUSED",
    altpll_component.port_clkena0 = "PORT_UNUSED",
    altpll_component.port_clkena1 = "PORT_UNUSED",
    altpll_component.port_clkena2 = "PORT_UNUSED",
    altpll_component.port_clkena3 = "PORT_UNUSED",
    altpll_component.port_clkena4 = "PORT_UNUSED",
    altpll_component.port_clkena5 = "PORT_UNUSED",
    altpll_component.port_extclk0 = "PORT_UNUSED",
    altpll_component.port_extclk1 = "PORT_UNUSED",
    altpll_component.port_extclk2 = "PORT_UNUSED",
    altpll_component.port_extclk3 = "PORT_UNUSED",
    altpll_component.self_reset_on_loss_lock = "OFF",
    altpll_component.width_clock = 5;


endmodule
