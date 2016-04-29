----------------------------------------------------------------------------------
-- Description:    Driver for 4-digit 7-segment display.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_UNSIGNED.ALL;

entity SegmentDriver is
    Port ( disp1 : in  std_logic_vector (6 downto 0);
           disp2 : in  std_logic_vector (6 downto 0);
           disp3 : in  std_logic_vector (6 downto 0);
           disp4 : in  std_logic_vector (6 downto 0);
             clk : in  std_logic;
     display_seg : out  std_logic_vector (6 downto 0);
     display_ena : out  std_logic_vector (3 downto 0));
end SegmentDriver;

architecture Behavioral of SegmentDriver is

signal cnt : std_logic_vector (1 downto 0);

begin
   process (clk) begin
      if (rising_edge(clk)) then
         cnt <= cnt + 1;
         if (cnt = "11") then
            cnt <= "00";
         end if;
     case (cnt) is
        when "00" =>
           display_seg <= disp1;
           display_ena <= "1110";
        when "01" =>
           display_seg <= disp2;
           display_ena <= "1101";
        when "10" =>
           display_seg <= disp3;
           display_ena <= "1011";
        when "11" =>
           display_seg <= disp4;
           display_ena <= "0111";
        when others =>
           display_seg <= (others => '0');
           display_ena <= "0000";
     end case;
      end if;
  end process;
  

end Behavioral;