library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_UNSIGNED.all;

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
		Blue: out std_logic_vector(2 downto 1)
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
	
	signal isJumping : std_logic := '0';
	signal gameOver : std_logic := '1';
	
	-- TODO: Randomize these values
	signal cactusX_1: integer := COLS - 24*1;
	signal cactusX_2: integer := COLS - 24*2;
	signal cactusX_3: integer := COLS - 24*3;
	signal cactusY: integer := 24;
	
	signal hasMoved: std_logic := '0';
	
begin							
	
	vgasignal: process(clk)
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
	

						-- Ground
						if ((vCount / PIX) = 24) then
							if ((vCount mod PIX) > (PIX - 4)) and ((vCount mod PIX) < (PIX - 2)) then
								rgbDrawColor := "000" & "000" & "00";
							end if;
						end if;
			
						
						-- Cactus1
						if ((hCount / PIX) = cactusX_1) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := "011" & "011" & "11";
						end if;
						
						-- Cactus2
						if ((hCount / PIX) = cactusX_2) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := "011" & "011" & "11";
						end if;
						
						-- Cactus3
						if ((hCount / PIX) = cactusX_3) and ((vCount / PIX) = cactusY) then 
							rgbDrawColor := "011" & "011" & "11";
						end if;
						
						-- T-Rex
						if ((hCount / PIX) = trexX) and ((vCount / PIX) = trexY) then 
							rgbDrawColor := "001" & "001" & "01";
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
			end if;
		end if;
	end process;
	
	
	controlJump: process(clk, jump)
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 2500000;
		
		variable waitCount: integer := 0;
		variable waitTime: integer := 50000000;
	begin
		if clk'event and clk = '1' then
			if hasMoved = '0' and trexY = 24 then
				if (jump = '1') then
					isJumping <= '1';
					hasMoved <= '1';
					prescalerCount := 0;
				else
					hasMoved <= '0';
				end if;
			elsif (jump = '0') then
				hasMoved <= '0';
			end if;
			
			
			if prescalerCount >= prescaler then
				if isJumping = '1' then
					if (trexY > 20) then
						trexY <= trexY - 1;
					else
						isJumping <= '0';
					end if;
					prescalerCount := 0;
				else
					if (trexY < 24) then
						trexY <= trexY + 1;
					end if;
					prescalerCount := 0;
				end if;
			end if;
			
			
			-- Detect Hit
			if (trexY = cactusY) and ((trexX = cactusX_1) or (trexX = cactusX_2) or (trexX = cactusX_2)) then
				gameOver <= '1';
			end if;
			
			if gameOver = '1' then
				if waitCount >= waitTime then
					trexX <= 8;
					trexY <= 24;
					
					gameOver <= '0';
					waitCount := 0;
				end if;
				waitCount := waitCount + 1;
			end if;
		
			prescalerCount := prescalerCount + 1;
		end if;
	end process;
		
		
	controlCactus: process(clk, gameOver)
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 2500000;
	begin
		if gameOver = '1' then
			cactusX_1 <= COLS - 24*1;
			cactusX_2 <= COLS - 24*2;
			cactusX_3 <= COLS - 24*3;
			
		elsif clk'event and clk = '1' then
			if prescalerCount >= prescaler then
					if (cactusX_1 <= 0) then
						cactusX_1 <= COLS;
					else
						cactusX_1 <= cactusX_1 - 1;
					end if;
					
					if (cactusX_2 <= 0) then
						cactusX_2 <= COLS;
					else
						cactusX_2 <= cactusX_2 - 1;
					end if;
					
					if (cactusX_3 <= 0) then
						cactusX_3 <= COLS;
					else
						cactusX_3 <= cactusX_3 - 1;
					end if;
			
					prescalerCount := 0;
				end if;
				
				prescalerCount := prescalerCount + 1;
		end if;
	end process;

end Behavioral;

