library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity seven_segment is
    Port ( clock : in  STD_LOGIC;
           sseg  : in  std_logic_vector(31 downto 0);
			  anode : out STD_LOGIC_VECTOR (3 downto 0);
			  SS7   : out STD_LOGIC_VECTOR (7 downto 0)
			  );
end seven_segment;



architecture Behavioral of seven_segment is

signal a: integer range 0 to 3;

begin

SS7 <= sseg(7 downto 0);
anode <= "0000";
--process (clock, a)
--	begin
--	if clock'event and clock = '1' then
--		if a = 0 then
--			anode <= "1110";
--			SS7 <= sseg(7 downto 0);
--			a <= a+1;
--		elsif a = 1 then
--			anode <= "1101";
--			SS7 <= sseg(15 downto 8);
--			a <= a+1;
--		elsif a = 2 then
--			anode <= "1011";
--			SS7 <= sseg(23 downto 16);
--			a <= a+1;
--		else 
--			anode <= "0111"; 
--			SS7 <= sseg(31 downto 24);
--			a <= a+1;
--		end if;
--	end if;
--	end process;

end Behavioral;

