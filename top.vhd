library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.ALL;

entity top is
	port(
		clk: in std_logic;

		-- User Input
		reset: in std_logic;
		jump: in std_logic;

		-- VGA 
		hsync: out std_logic;
		vsync: out std_logic;
		Red: out std_logic_vector(2 downto 0);
		Green: out std_logic_vector(2 downto 0);
		Blue: out std_logic_vector(2 downto 1);

		-- 7 Seg Display
		segments : out  std_logic_vector (7 downto 0);
        anodes   : out  std_logic_vector (0 to 3)
	);
end top;



architecture Behavioral of top is
	constant PIX : integer := 16;
	constant ROWS : integer := 30;
	constant COLS : integer := 40;
	constant T_FAC : integer := 100000;
	constant RAN_WIDTH : integer :=  5;

	-- Speed
	constant cloudSpeed : integer := 60;
	constant cactusSpeed : integer := 40;
	constant pteroSpeed : integer := 30;
	constant trexSpeed : integer := 25;

	-- VGA Sigs
	signal hCount: integer := 640;
	signal vCount: integer := 480;
	signal nextHCount: integer := 641;
	signal nextVCount: integer := 480;
	
	-- T-Rex
	signal trexX: integer := 8;
	signal trexY: integer := 24;

	-- Pterodactyl
	signal pteroX: integer := COLS*3;
	signal pteroY: integer := 21;

	-- Clouds
	signal cloudX_1: integer := COLS;
	signal cloudY_1: integer := 8;
	signal cloudX_2: integer := COLS + (COLS/2);
	signal cloudY_2: integer := 18;
	
	-- Cactus
	signal resetGame : std_logic := '0';
	signal cactusX_1: integer := COLS;
	signal cactusX_2: integer := COLS + (COLS/2);
	signal cactusX_3: integer := COLS + COLS;
	signal cactusY: integer := 24;
	
	-- Game Logic
	signal gameOver : std_logic := '0';
	signal isJumping : std_logic := '0';	
	signal gameSpeed: integer := 0;
	signal rand_num : integer := 0;

	-- COMPONENT SIGNALS
	signal sclock, cleanJump : std_logic;
	signal d0, d10, d100 : std_logic_vector (3 downto 0);
	signal disp1, disp2, disp3 : std_logic_vector (6 downto 0);

	-- Sprites
	type sprite_block is array(0 to 15, 0 to 15) of integer range 0 to 1;
	constant trex_1: sprite_block:=((0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
									(0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1), -- 1 
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 2
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 3
									(0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0), -- 4
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0), -- 5
									(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
									(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
									(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
									(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
									(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
									(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
									(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
		 							(0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,0), -- 13
									(0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0), -- 14
									(0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0));-- 15

	constant trex_2: sprite_block:=((0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
									(0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1), -- 1 
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 2
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 3
									(0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0), -- 4
									(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 5
									(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
									(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
									(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
									(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
									(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
									(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
									(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
		 							(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
									(0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0), -- 14
									(0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0));-- 15

	constant trex_dead: sprite_block:=( (0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
										(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 1 
										(0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1), -- 2
										(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 3
										(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 4
										(0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0), -- 5
										(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
										(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
										(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
										(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
										(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
										(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
										(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
										(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
										(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 14
										(0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0));-- 15

	constant cactus: sprite_block :=((0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 3
									 (0,0,0,0,0,1,0,1,1,1,0,1,0,0,0,0), -- 4
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 5
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 6
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 7
									 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 8
									 (0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0), -- 9
									 (0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0));-- 15

	constant ptero_1: sprite_block:=((0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
									 (0,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0), -- 3
									 (0,0,1,1,1,0,0,1,1,1,1,1,0,0,0,0), -- 4
									 (0,1,1,1,1,0,0,1,1,1,1,1,1,0,0,0), -- 5
									 (1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 6
									 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
									 (0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 9
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	constant ptero_2: sprite_block:=((0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
									 (0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 3
									 (0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 4
									 (0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 5
									 (1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 6
									 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
									 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0), -- 9
									 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 11
									 (0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	constant cloud: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 6
									 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 7
									 (0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0), -- 8
									 (0,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1), -- 9
									 (1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1), -- 10
									 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 11
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	type color_arr is array(0 to 1) of std_logic_vector(7 downto 0);
	constant sprite_color : color_arr := ("11011111", "00000000");

	-- COMPONENTS
	-- Clock Divider
   component Debo
       port ( clk  : in  std_logic;
       		  key  : in  std_logic;
	    	  pulse : out std_logic
            );
   end component;

	-- Clock Divider
   component CDiv
       port ( Cin  : in  std_logic;
              Cout : out std_logic
            );
   end component;
	
	-- Counter
   component Counter
       port ( clk     : in  std_logic; 
              countup : in  std_logic;
              reset: in std_logic; 
              d0  : out std_logic_vector(3 downto 0);
			  d10  : out std_logic_vector(3 downto 0);
			  d100  : out std_logic_vector(3 downto 0));
   end component;
	
	--Bcd to Seg Decoder
   component BcdSegDecoder
       port(clk : in std_logic;
			bcd : in  std_logic_vector (3 downto 0);
			segment7 : out  std_logic_vector (6 downto 0));
   end component;
   
   --Segment Driver
   component SegmentDriver
       port(disp1 : in  std_logic_vector (6 downto 0);
            disp2 : in  std_logic_vector (6 downto 0);
            disp3 : in  std_logic_vector (6 downto 0);
            disp4 : in  std_logic_vector (6 downto 0);
            clk : in  std_logic;
        	display_seg : out  std_logic_vector (6 downto 0);
        	display_ena : out  std_logic_vector (3 downto 0));
   end component;

-- Behaviour Block
begin
	segments(0) <= '1';

	-- COMPONENTS
	JumpDebo: Debo port map (clk => sclock,
							 key => jump,
							 pulse => cleanJump);

	SegClock: CDiv port map (Cin => clk,
							Cout => sclock);
									
	ScoreCounter: Counter
		port map(	clk => clk,
					countup => not gameOver,
					reset => resetGame, 
					d0 => d0,
					d10 => d10,
					d100 => d100);
					--d1000 => d1000);
						
	Digit1: BcdSegDecoder 
		port map (	clk => clk,
					bcd => d0,
					segment7 => disp1);
												
	Digit2: BcdSegDecoder
		port map (	clk => clk,
					bcd => d10,
              		segment7 => disp2);
												
   Digit3: BcdSegDecoder 
		port map (	clk => clk,
					bcd => d100,
              		segment7 => disp3);
												
   Driver: SegmentDriver
		port map (	disp1 => disp1,
					disp2 => disp2,
					disp3 => disp3,
					disp4 => "1111111",
					clk => sclock,
					display_seg => segments(7 downto 1),
					display_ena => anodes);				
	

	-- PROCESSES
	vgaSignal: process(clk)
		variable sprite_x : integer := 0;
		variable sprite_y : integer := 0;
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 5000000;
		variable divide_by_2 : std_logic := '0';
		variable rgbDrawColor : std_logic_vector(7 downto 0) := (others => '0');
	begin
		
		if clk'event and clk = '1' then
			if reset = '1' then
				hsync <= '1';
				vsync <= '1';
				
				hCount <= 640;
				vCount <= 480;
				nextHCount <= 641;
				nextVCount <= 480;
				
				rgbDrawColor := (others => '0');
				
				divide_by_2 := '0';
			else
				
				-- Running at 25 Mhz (50 Mhz / 2)
				if divide_by_2 = '1' then
					if(hCount = 799) then
						hCount <= 0;
						
						if(vCount = 524) then
							vCount <= 0;
						else
							vCount <= vCount + 1;
						end if;
					else
						hCount <= hCount + 1;
					end if;
					
					
					-- horizontal rollover
					if (nextHCount = 799) then	
						nextHCount <= 0;
						
						-- vertical rollover
						if (nextVCount = 524) then	
							nextVCount <= 0;
						else
							nextVCount <= vCount + 1;
						end if;
					else
						nextHCount <= hCount + 1;
					end if;
					

					-- trigger vsync and hsync pulses
					if (vCount >= 490 and vCount < 492) then
						vsync <= '0';
					else
						vsync <= '1';
					end if;
					
					if (hCount >= 656 and hCount < 752) then
						hsync <= '0';
					else
						hsync <= '1';
					end if;
					
					
					-- in display range
					if (hCount < 640 and vCount < 480) then

						-- Default is background
						rgbDrawColor := "110" & "111" & "11";
			
						sprite_x := hCount mod PIX;
						sprite_y := vCount mod PIX;

						-- Cloud1
						if ((hCount / PIX) = cloudX_1) and ((vCount / PIX) = cloudY_1) then 
							rgbDrawColor := sprite_color(cloud(sprite_y, sprite_x));
						end if;
						-- Cloud2
						if ((hCount / PIX) = cloudX_2) and ((vCount / PIX) = cloudY_2) then 
							rgbDrawColor := sprite_color(cloud(sprite_y, sprite_x));
						end if;
						

						-- Cactus1
						if ((hCount / PIX) = cactusX_1) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(cactus(sprite_y, sprite_x));
						end if;
						-- Cactus2
						if ((hCount / PIX) = cactusX_2) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(cactus(sprite_y, sprite_x));
						end if;
						-- Cactus3
						if ((hCount / PIX) = cactusX_3) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := sprite_color(cactus(sprite_y, sprite_x));
						end if;


						-- Pterodactyl
						if ((hCount / PIX) = pteroX) and ((vCount / PIX) = pteroY) then
							if (gameOver = '1') or (prescalerCount <= prescaler) then
								rgbDrawColor := sprite_color(ptero_1(sprite_y, sprite_x));
							elsif (prescalerCount > prescaler and prescalerCount <= prescaler*2) then
								rgbDrawColor := sprite_color(ptero_2(sprite_y, sprite_x));
							else
								prescalerCount := 0;
								rgbDrawColor := sprite_color(ptero_2(sprite_y, sprite_x));
							end if;
						end if;


						-- T-Rex
						if ((hCount / PIX) = trexX) and ((vCount / PIX) = trexY) then
							if (gameOver = '1') then
								rgbDrawColor := sprite_color(trex_dead(sprite_y, sprite_x));
							elsif (prescalerCount <= prescaler) then
								rgbDrawColor := sprite_color(trex_1(sprite_y, sprite_x));
							elsif (prescalerCount > prescaler and prescalerCount <= prescaler*2) then
								rgbDrawColor := sprite_color(trex_2(sprite_y, sprite_x));
							else
								prescalerCount := 0;
								rgbDrawColor := sprite_color(trex_2(sprite_y, sprite_x));
							end if;
						end if;
						

						-- Ground
						if ((vCount / PIX) = 24) then
							if ((vCount mod PIX) = (PIX - 4)) then
								rgbDrawColor := "000" & "000" & "00";
							end if;
						end if;
						

						-- Show dem colors
						Red <= rgbDrawColor(7 downto 5);
						Green <= rgbDrawColor(4 downto 2);
						Blue <= rgbDrawColor(1 downto 0);
					else
						Red <= "000";
						Green <= "000";
						Blue <= "00";
					end if;
				end if;
				divide_by_2 := not divide_by_2;
				prescalerCount := prescalerCount + 1;
			end if;
		end if;
	end process;

	gameLogic: process(clk, cleanJump)
		variable endGame: std_logic := '0';

		variable trexCount: integer := 0;
		variable cactusCount: integer := 0;
		variable pteroCount: integer := 0;
		variable cloudCount: integer := 0;
		variable waitCount: integer := 0;
		variable waitTime: integer := T_FAC*40*25;

		-- Random Number Signals
		variable rand_temp : std_logic_vector(RAN_WIDTH - 1 downto 0):=(RAN_WIDTH - 1 => '1',others => '0');
		variable temp : std_logic := '0';
	begin
		if clk'event and clk = '1' then

			-- Generate Random Number
			temp := rand_temp(RAN_WIDTH - 1) xor rand_temp(RAN_WIDTH - 2);
			rand_temp(RAN_WIDTH - 1 downto 1) := rand_temp(RAN_WIDTH - 2 downto 0);
			rand_temp(0) := temp;
		    rand_num <= to_integer(unsigned(rand_temp));


		    -- Adjust game speed
		    if gameSpeed < 20 and d0 = "0101" then
		    	gameSpeed <= gameSpeed + 5;
		    end if;


			-- Jump Logic
			if cleanJump = '1' and trexY = 24 then
				if (gameOver = '0') then
					isJumping <= '1';
					trexCount := 0;					
				end if;		
			end if;
			
			
			-- Trex Jump animation
			if trexCount >= T_FAC * trexSpeed then
				if isJumping = '1' then
					if (trexY > 20) then
						trexY <= trexY - 1;
					else
						isJumping <= '0';
					end if;
					trexCount := 0;
				else
					if (trexY < 24) then
						trexY <= trexY + 1;
					end if;
					trexCount := 0;
				end if;
			end if;
			trexCount := trexCount + 1;


			-- Detect Hit Cactus
			if (trexY = cactusY) and ((trexX = cactusX_1) or (trexX = cactusX_2) or (trexX = cactusX_3)) then
				endGame := '1';
			end if;

			-- Detect Hit Pterodactyl
			if (trexY = pteroY) and (trexX = pteroX) then
				endGame := '1';
			end if;
			gameOver <= endGame;

			-- Game Over
			if endGame = '1' then
				if waitCount >= waitTime then
					trexX <= 8;
					trexY <= 24;
					endGame := '0';
					waitCount := 0;
					resetGame <= '1';
				end if;
				waitCount := waitCount + 1;
			end if;

			
			if resetGame = '1' then
				cactusX_1 <= COLS;
				cactusX_2 <= COLS + (COLS/2);
				cactusX_3 <= COLS + COLS;
				cloudX_1 <= COLS;
				cloudX_2 <= COLS + (COLS/2);
				pteroX <= COLS + COLS;
				gameSpeed <= 0;
				resetGame <= '0';
			else
				-- Cactus Movement
				if (endGame = '0') and (cactusCount >= T_FAC * cactusSpeed - gameSpeed) then
					if (cactusX_1 <= 0) then
						cactusX_1 <= COLS + rand_num;
					elsif (cactusX_2 <= 0) then
						cactusX_2 <= COLS + rand_num;
					elsif (cactusX_3 <= 0) then
						cactusX_3 <= COLS + rand_num;
					else
						cactusX_1 <= cactusX_1 - 1;
						cactusX_2 <= cactusX_2 - 1;
						cactusX_3 <= cactusX_3 - 1;
					end if;
					cactusCount := 0;
				end if;
				cactusCount := cactusCount + 1;


				-- Pterodactyl Movement
				if (endGame = '0') and (pteroCount >= T_FAC * pteroSpeed - gameSpeed) and (d10 >= "0001") then
					if pteroX <= 0 then
						pteroX <= COLS + (COLS/2) + rand_num;
					else
						pteroX <= pteroX - 1;
					end if;
					pteroCount := 0;
				end if;
				pteroCount := pteroCount + 1;


				-- Cloud Movement
				if (endGame = '0') and (cloudCount >= T_FAC * cloudSpeed) then
					if cloudX_1 <= 0 then
						cloudX_1 <= COLS + (COLS/2);
					elsif cloudX_2 <= 0 then
						cloudX_2 <= COLS + (COLS/2);
					else
						cloudX_1 <= cloudX_1 - 1;
						cloudX_2 <= cloudX_2 - 1;
					end if;
					cloudCount := 0;

				end if;
				cloudCount := cloudCount + 1;
			end if;

		end if; -- end clock event
	end process;

end Behavioral;

