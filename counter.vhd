library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity Counter is
   port(clk : in std_logic;
        countup: in std_logic;
        reset: in std_logic;
        d0: out std_logic_vector(3 downto 0);
		d10: out std_logic_vector(3 downto 0);
		d100: out std_logic_vector(3 downto 0));
		--d1000: out std_logic_vector(3 downto 0));
end Counter;
 
architecture Behavioral of Counter is
    signal t0: integer := 0;
	signal t10: integer := 0;
	signal t100: integer := 0;
	--signal t1000: integer := 0;
begin   
  process(clk)
		variable prescalerCount: integer := 0;
		variable prescaler: integer := 25000000;
    begin
      if (reset = '1') then
		t0 <= 0;
		t10 <= 0;
		t100 <= 0;
		--t1000 <= 0;
      elsif(clk = '1' and clk'event) then
			if prescalerCount >= prescaler then
					if countup='1' then
						if t100 >= 9 then 
							t0 <= 0;
							t10 <= 0;
							t100 <= 0;
							--t1000 <= 0;
						else
							t0 <= t0 + 1;
							if t0 >= 9 then
								t10 <= t10 + 1;
								t0 <= 0;
								if t10 >= 9 then
									t100 <= t100 + 1;
									t10 <= 0;
									--if t100 >= 9 then
									--	t1000 <= t1000 + 1;
									--	t100 <= 0;
									--end if;
								end if;
							end if;
						end if;
					end if;

					prescalerCount := 0;
				end if;
				prescalerCount := prescalerCount + 1;
    end if;
   end process;
   d0 <= std_logic_vector(to_unsigned(t0, d0'length));
	d10 <= std_logic_vector(to_unsigned(t10, d10'length));
	d100 <= std_logic_vector(to_unsigned(t100, d100'length));
	--d1000 <= std_logic_vector(to_unsigned(t1000, d1000'length));
end Behavioral;