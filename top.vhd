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
		
		up: in std_logic; -- BTN0
		down: in std_logic; -- BTN1
		right: in std_logic; -- BTN2
		left: in std_logic; -- BTN3
		
		led: out std_logic_vector(7 downto 0);
		
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
	
	signal redX: integer := 0;
	signal redY: integer := 0;
	
	signal hasMoved: std_logic := '0';

	signal led_reg: std_logic_vector(7 downto 0) := (others => '0');
	
begin							
	led <= led_reg;
	
	vgasignal: process(clk)
		variable tileColor : std_logic := '0';
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
						-- Default is black
						rgbDrawColor := "000" & "000" & "00";
						
						-- Make the Checker Board
						if (vCount / PIX) mod 2 = 0 then
							-- Blue (Even)
							tileColor := '1';
						else
							-- Green (Odd)
							tileColor := '0';
						end if;
					
						if (hCount / PIX) mod 2 = 0 then
								tileColor := not tileColor;
						end if;
						
						-- Assign Tile Color
						if tileColor = '0' then
							-- Green Tile
							rgbDrawColor := "110" & "111" & "11";
						else
							-- Blue Tile
							rgbDrawColor := "101" & "111" & "11";
						end if;	

						-- Ground
						if ((vCount / PIX) = 25) then 
							rgbDrawColor := "000" & "000" & "00";
						end if;
						
						-- T-Rex
						if ((hCount / PIX) = 8) and ((vCount / PIX) = 24) then 
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
	
	controlButtons: process(clk, up, down, right, left)
	begin
		if clk'event and clk = '1' then
			if hasMoved = '0' then
				if (up = '1') then
					if redY /= 0 then
						redY <= redY - 1;
					else
						redY <= 15;
					end if;
					hasMoved <= '1';
				elsif (down = '1') then
					if redY /= 15 then
						redY <= redY + 1;
					else
						redY <= 0;
					end if;
					hasMoved <= '1';
				elsif (right = '1') then
					if redX /= 20 then
						redX <= redX + 1;
					else
						redX <= 0;
					end if;
					hasMoved <= '1';
				elsif(left = '1') then
					if redX /= 0 then
						redX <= redX - 1;
					else
						redX <= 20;
					end if;
					hasMoved <= '1';
				else
					hasMoved <= '0';
				end if;
			elsif (up = '0' and down = '0' and right = '0' and left = '0') then 
				hasMoved <= '0';
			end if;
		end if;
	end process;
	
	-- Run the leds
	-- If in reset, leds are off
	runLeds: process(clk)
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 50000000;
	begin
		if clk'event and clk = '1' then
			if reset = '1' then
				prescalerCount := 0;
			
				led_reg <= (others => '0');
			else
				if prescalerCount >= prescaler then
					if led_reg = "00000000" then
						led_reg <= "00000001";
					else
						led_reg <= led_reg(6 downto 0) & "0";
					end if;
					
					prescalerCount := 0;
				end if;
				
				prescalerCount := prescalerCount + 1;
			end if;
		end if;
	end process;

end Behavioral;

