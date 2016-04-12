library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
	port(
		clk: in std_logic;
		reset: in std_logic; -- SW0
		
		jump: in std_logic; -- BTN0
		
		hsync: out std_logic;
		vsync: out std_logic;
		Red: out std_logic_vector(2 downto 0);
		Green: out std_logic_vector(2 downto 0);
		Blue: out std_logic_vector(2 downto 1);

		segments : out  std_logic_vector (7 downto 0);
        anodes   : out  std_logic_vector (0 to 3)
	);
end top;



architecture Behavioral of top is
	constant PIX : integer := 16;
	constant ROWS : integer := 30;
	constant COLS : integer := 40;

	-- Start out at the end of the display range, 
	signal hCount: integer := 640;
	signal vCount: integer := 480;
	
	signal nextHCount: integer := 641;
	signal nextVCount: integer := 480;
	
	signal trexX: integer := 8;
	signal trexY: integer := 24;

	signal pteroX_1: integer := COLS + (COLS*2);
	signal pteroY_1: integer := 21;

	signal cloudX_1: integer := 8;
	signal clounY_1: integer := 10;
	
	signal isJumping : std_logic := '0';
	signal gameOver : std_logic := '0';
	signal isPlaying : std_logic := '1';
	
	-- TODO: Randomize these values
	signal resetCactus : std_logic := '0';
	signal cactusX_1: integer := COLS + (24*2);
	signal cactusX_2: integer := COLS + (24*3);
	signal cactusX_3: integer := COLS + (24*4);
	signal cactusY: integer := 24;
	
	signal hasMoved: std_logic := '0';

	-- Sprite
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
									 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 10
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
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 10
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
									 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 10
									 (0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 12
		 							 (0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0), -- 13
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
									 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	type color_arr is array(0 to 1) of std_logic_vector(7 downto 0);
	constant sprite_color : color_arr := ("11011111", "00000000");

	-- COMPONENTS
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
			  d100  : out std_logic_vector(3 downto 0);
			  d1000  : out std_logic_vector(3 downto 0));
   end component;
	
	--Bcd to Seg Decoder
   component BcdSegDecoder
       port ( 	clk : in std_logic;
				bcd : in  std_logic_vector (3 downto 0);
				segment7 : out  std_logic_vector (6 downto 0));
   end component;
   
   --Segment Driver
   component SegmentDriver
       port ( disp1 : in  std_logic_vector (6 downto 0);
              disp2 : in  std_logic_vector (6 downto 0);
              disp3 : in  std_logic_vector (6 downto 0);
              disp4 : in  std_logic_vector (6 downto 0);
                clk : in  std_logic;
        display_seg : out  std_logic_vector (6 downto 0);
        display_ena : out  std_logic_vector (3 downto 0));
   end component;

   -- COMPONENT SIGNALS
	signal sclock : std_logic;
	signal resetScore : std_logic := '0';
	signal d0, d10, d100, d1000 : std_logic_vector (3 downto 0);
	signal disp1, disp2, disp3, disp4 : std_logic_vector (6 downto 0);

begin
	segments(0) <= '1';
	isPlaying <= not gameOver;

	-- COMPONENTS
	SegClock: CDiv port map (Cin => clk,
							Cout => sclock);
									
	ScoreCounter: Counter
		port map (	clk => clk,
					countup => isPlaying,
					reset => resetScore, 
					d0 => d0,
					d10 => d10,
					d100 => d100,
					d1000 => d1000);
						
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
												
   Digit4: BcdSegDecoder
		port map (	clk => clk,
					bcd => d1000,
					segment7 => disp4);
												
   Driver: SegmentDriver
		port map (	disp1 => disp1,
					disp2 => disp2,
					disp3 => disp3,
					disp4 => disp4,
					clk => sclock,
					display_seg => segments(7 downto 1),
					display_ena => anodes);				
	

	-- PROCESSES
	vgasignal: process(clk)
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
				
				-- Start out at the end of the display range, 
				-- so we give a sync pulse to kick things off
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
					
					
					-- Make sure we got the rollover covered
					if (nextHCount = 799) then	
						nextHCount <= 0;
						
						-- Make sure we got the rollover covered
						if (nextVCount = 524) then	
							nextVCount <= 0;
						else
							nextVCount <= vCount + 1;
						end if;
					else
						nextHCount <= hCount + 1;
					end if;
					
					
					
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
					
					
					-- If in display range
					if (hCount < 640 and vCount < 480) then
					
						-- Draw stack:
						-- Default is background
						rgbDrawColor := "110" & "111" & "11";
			
						sprite_x := hCount mod PIX;
						sprite_y := vCount mod PIX;
						
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
						if ((hCount / PIX) = pteroX_1) and ((vCount / PIX) = pteroY_1) then
							if (gameOver = '1') then
								rgbDrawColor := sprite_color(ptero_1(sprite_y, sprite_x));
							elsif (prescalerCount <= prescaler) then
								rgbDrawColor := sprite_color(ptero_1(sprite_y, sprite_x));
							elsif (prescalerCount > prescaler and prescalerCount <= prescaler*2) then
								rgbDrawColor := sprite_color(ptero_2(sprite_y, sprite_x));
							else
								prescalerCount := 0;
								rgbDrawColor := sprite_color(trex_2(sprite_y, sprite_x));
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
						
						-- Show your colors
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
	
	
	controlJump: process(clk, jump)
		variable endGame: std_logic := '0';

		variable trexCount: integer := 0;
		variable trexTime: integer := 2500000;

		variable cactusCount: integer := 0;
		variable cactusTime: integer := 2500000;
		
		variable waitCount: integer := 0;
		variable waitTime: integer := 100000000;
	begin
		if clk'event and clk = '1' then

			-- Jump Logic
			if hasMoved = '0' and trexY = 24 then
				if (jump = '1') and (gameOver = '0') then
					isJumping <= '1';
					hasMoved <= '1';
					trexCount := 0;
				else
					hasMoved <= '0';
				end if;
			elsif (jump = '0') then
				hasMoved <= '0';
			end if;
			
			
			-- Trex Jump animation
			if trexCount >= trexTime then
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
			
			
			-- Detect Hit
			if (trexY = cactusY) and ((trexX = cactusX_1) or (trexX = cactusX_2) or (trexX = cactusX_3)) then
				endGame := '1';
			end if;
			

			-- Game Over
			if endGame = '1' then
				if waitCount >= waitTime then
					trexX <= 8;
					trexY <= 24;
					
					endGame := '0';
					waitCount := 0;
					resetCactus <= '1';
					resetScore <= '1';
				end if;
				waitCount := waitCount + 1;
			end if;

			if resetCactus = '1' then
				cactusX_1 <= COLS + (24*1);
				cactusX_2 <= COLS + (24*2);
				cactusX_3 <= COLS + (24*3);
				resetCactus <= '0';
				resetScore <= '0';
			elsif (endGame = '0') and (cactusCount >= cactusTime) then
				if (cactusX_1 <= 0) then
					cactusX_1 <= COLS;
				else
					cactusX_1 <= cactusX_1 - 1;
				end if;
				
				if (cactusX_2 <= 0) then
					cactusX_2 <= COLS + 24*2;
				else
					cactusX_2 <= cactusX_2 - 1;
				end if;
				
				if (cactusX_3 <= 0) then
					cactusX_3 <= COLS + 24*3;
				else
					cactusX_3 <= cactusX_3 - 1;
				end if;

				if pteroX_1 <= 0 then
					pteroX_1 <= COLS + COLS*2;
				else
					pteroX_1 <= pteroX_1 - 1;
				end if;
				
				cactusCount := 0;
			end if;
			cactusCount := cactusCount + 1;

		end if; -- end clock event
		gameOver <= endGame;
	end process;

end Behavioral;

