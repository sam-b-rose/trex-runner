LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY CDiv IS
	PORT ( Cin	: IN 	std_logic ;
	  Cout : OUT std_logic ) ;
END CDiv ;

ARCHITECTURE Behavior OF CDiv IS
	constant TC: integer := 12; --Time Constant
	signal c0,c1,c2,c3: integer range 0 to 1000;
	signal D: std_logic := '0';
BEGIN
	PROCESS(Cin)
	BEGIN
		if (Cin'event and Cin='1') then
			c0 <= c0 + 1;
			if c0 = TC then
				c0 <= 0;
				c1 <= c1 + 1;
			elsif c1 = TC then
				c1 <= 0;
				c2 <= c2 + 1;
			elsif c2 = TC then
				c2 <= 0;
				c3 <= c3 + 1;
			elsif c3 = TC then
				c3 <= 0;
				D <= NOT D;
			end if;
		end if;
		Cout <= D;
	END PROCESS ;
END Behavior ;
