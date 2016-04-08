LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY vga_test IS
END vga_test;
 
ARCHITECTURE behavior OF vga_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         led : OUT  std_logic_vector(7 downto 0);
			
			jump: in std_logic; -- BTN0
			
			hsync: out std_logic;
			vsync: out std_logic;
			Red: out std_logic_vector(2 downto 0);
			Green: out std_logic_vector(2 downto 0);
			Blue: out std_logic_vector(2 downto 1)
		);
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
	
	signal jump: std_logic := '0';

 	--Outputs
   signal led : std_logic_vector(7 downto 0);
	
	signal hsync : std_logic;
	signal vsync : std_logic;
	
	signal Red : std_logic_vector(2 downto 0);
	signal Green : std_logic_vector(2 downto 0);
	signal Blue : std_logic_vector(2 downto 1);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk => clk,
          reset => reset,
          led => led,
			 hsync => hsync,
			 vsync => vsync,
			 jump => jump,
			 Red => Red,
			 Green => Green,
			 Blue => Blue
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process (clk)
		file file_pointer: text is out "write.txt";
		variable line_el: line;
	begin
		if clk'event and clk = '1' then

			-- Write the time
			write(line_el, now); -- write the line.
			write(line_el, ":"); -- write the line.

			-- Write the hsync
			write(line_el, " ");
			write(line_el, hsync); -- write the line.

			-- Write the vsync
			write(line_el, " ");
			write(line_el, vsync); -- write the line.

			-- Write the red
			write(line_el, " ");
			write(line_el, Red); -- write the line.

			-- Write the green
			write(line_el, " ");
			write(line_el, Green); -- write the line.

			-- Write the blue
			write(line_el, " ");
			write(line_el, Blue); -- write the line.

			writeline(file_pointer, line_el); -- write the contents into the file.
	
		end if;
	end process;

END;
