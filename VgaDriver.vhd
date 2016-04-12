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

entity VgaDriver is
	port(
		clk: in std_logic;
		rgbDrawColor : in std_logic_vector(7 downto 0);

		hsync: out std_logic;
		vsync: out std_logic;
		redOut: out std_logic_vector(2 downto 0);
		greenOut: out std_logic_vector(2 downto 0);
		blueOut: out std_logic_vector(2 downto 1)
	);
end VgaDriver;



architecture Behavioral of VgaDriver is
	-- Start out at the end of the display range, 
	signal hCount: integer := 640;
	signal vCount: integer := 480;
	
	signal nextHCount: integer := 641;
	signal nextVCount: integer := 480;
begin							

	vgaSignal: process(clk)
		variable divideBy2 : std_logic := '0';
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
				
				divideBy2 := '0';
			else
				
				-- Running at 25 Mhz (50 Mhz / 2)
				if divideBy2 = '1' then
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
						
						-- Show your colors
						redOut <= rgbDrawColor(7 downto 5);
						greenOut <= rgbDrawColor(4 downto 2);
						blueOut <= rgbDrawColor(1 downto 0);
						
					
					else
						redOut <= "000";
						greenOut <= "000";
						blueOut <= "00";
					end if;
			
				end if;
				divideBy2 := not divideBy2;
			end if;
		end if;
	end process;
end Behavioral;

