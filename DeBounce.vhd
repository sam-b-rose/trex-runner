-- Pushbutton Debounce Module
LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;
USE ieee.STD_LOGIC_UNSIGNED.all;

ENTITY Debo IS
PORT (
  clk: IN STD_LOGIC; ---make it a low frequency Clock input
  key: IN STD_LOGIC;  -- active low input
  pulse: OUT STD_LOGIC);
END Debo;

ARCHITECTURE onepulse OF Debo IS
  SIGNAL cnt: STD_LOGIC_VECTOR (1 DOWNTO 0);
BEGIN
  PROCESS (clk,key)
  BEGIN 
   
   IF (key = '1') THEN
      cnt <= "00";
    ELSIF (clk'EVENT AND clk= '1') THEN
      IF (cnt /= "11") THEN cnt <= cnt + 1; END IF;
    END IF;
   
   IF (cnt = "10") AND (key = '0') THEN
      pulse <= '1';
   ELSE pulse <= '0'; 
   END IF;

  END PROCESS; --You must BEGIN and END a PROCESS in VHDL.
END onepulse;

