library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity seven_segment is
    Port ( clock : in  STD_LOGIC;
           sseg  : in  std_logic_vector(27 downto 0);
			  AN : out STD_LOGIC_VECTOR (3 downto 0);
			  SS7   : out STD_LOGIC_VECTOR (6 downto 0)
			  );
end seven_segment;

	

architecture Behavioral of seven_segment is

	constant N: integer := 20;
	signal Q_REG, Q_NEXT: unsigned(N-1 downto 0);
	signal SEL: std_logic_vector(1 downto 0);

	
	begin 
	
		-- Control Reset Value
		process (clock)
		begin
			if (clock'event and clock='1') then
				Q_REG <= Q_NEXT;
			end if;
		end process;
		
		-- Set Q_NEXT to Q_REG with 1 added
		Q_NEXT <= Q_REG + 1;
		
		-- Set SEL equal to the MSB of Q_REG
		SEL <= std_logic_vector(Q_REG(N-1 downto N-2));
		
		-- Process to turn on the corresponding annode as the 7 segment counts
		process (SEL, sseg)
		begin
			case SEL is 
				when "00" =>
					AN <="1110";
					SS7 <= sseg(6 downto 0);
					
				when "01" =>
					AN <= "1101";
					SS7  <= sseg(13 downto 7);
				
				when "10" =>
					AN <= "1011";
					SS7  <= sseg(20 downto 14);
					
				when "11" => 
					AN <= "0111";
					SS7  <= sseg(27 downto 21);
					
				when others =>
					AN <= "1111";
					
			end case;
		end process;
		
		-- Convert the display bit corresponding to an anode into the seven segment hex encoding



end Behavioral;

