----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:46:55 11/11/2015 
-- Design Name: 
-- Module Name:    VendMachine - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--Inputs: -------------------------------------------------------------
--Nickel, Dime, Quarter: Coins inserted into machine.
--Coin_Return: Input used to return coins.
--Restock: Input to restock machine
--VendA, VendB, VendC, VendD: Switch to press to Vend specific product.
--Toggle_Hex1, Toggle_Hex2, Toggle_Hex3: Used to toggle Hex Display.
-----------------------------------------------------------------------

--Outputs: ------------------------------------------------------------
--ProdA, ProdB, ProdC, ProdD: Output signal to dispense products.
--RNick, RDime, RQuarter:     Output signal to dispense change.
--MoreCash: LED that turns on when more cash is needed to dispense product chosen.
--Soldout: LED that turns on when product chosen is sold out.
--Lockout: Turns on when machine is out of change, must be restocked to turn off.
------------------------------------------------------------------------

--Signals and Variables: -------------------------------------------------------------
--Ct: If reaches 15 seconds, machine will return change. Since we are using a 3Hz clock
-- it will happen when it reaches 45.
--Np,Dp,Qp: Debounced signal for Nickel, Dime, and Quarter Inputs
--Ct: Amount of credit that has been inserted into machine.
--Ai,Bi,Ci,Di: Amount of Product A,B,C,D left in machine.
--Ni,Dimei,Qi: Amount of Coins left in machine that can be returned as change.
--------------------------------------------------------------------------------------

--Assumptions-------------------------------------------------------------------------
--1. Once the machine's credit reaches 25 cents, the user can not insert more coins. 
--This means the maximum amount of credit is 45 cents.
--2. Only one coin can be inserted in any clock cycle.


entity VendMachine is
Port( Nickel, Dime, Quarter, Coin_Return, Restock: in std_logic;
		VendA, VendB, VendC, VendD, Clock			 : in std_logic;
		Toggle_Hex1, Toggle_Hex2, Toggle_Hex3      : in std_logic;
		AN													 : out std_logic_vector(3 downto 0);
		Seven_segment_out									: out std_logic_vector(6 downto 0);
		--ProdA, ProdB, ProdC, ProdD, 
		Decimal				 : out std_logic;
		RNick, RDime, RQuarter, Clock_out			 : out std_logic;
		MoreCash, SoldOut, LockOut						 : out std_logic);
end VendMachine;

architecture Behavioral of VendMachine is


Component DEBOUNCE IS
PORT (
  Clk       : IN STD_LOGIC;
  PB       : IN STD_LOGIC;  -- active low input
  pulse     : OUT STD_LOGIC);
END Component;

Component seven_segment is
    Port ( clock : in  STD_LOGIC;
           sseg  : in  std_logic_vector(27 downto 0);
			  AN : out STD_LOGIC_VECTOR (3 downto 0);
			  SS7   : out STD_LOGIC_VECTOR (6 downto 0)
			  );
end Component;

type state is (S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15, S16, S17);
signal Cstate: state:=S0; 
Signal Np, Dp, Qp, restock_temp: std_logic := '0';
signal Ct, Count: integer range 0 to 45 := 0;
signal Ai,Bi,Ci,Di,Ni,Dimei,Qi: integer range 0 to 5 := 5;
signal SLOW_CLK: std_logic;
signal CLK_DIVIDER: std_logic_vector(27 downto 0) := x"0000000";
signal full_seven_segment: STD_LOGIC_vector ( 27 downto 0);
signal ProdA, ProdB, ProdC, ProdD : std_logic;


begin

Decimal<='1';


CLK_DIVISION: process(Clock, CLK_DIVIDER)

begin
    if Clock'event and Clock = '1' then
        CLK_DIVIDER <= CLK_DIVIDER + 1;
    end if;
    SLOW_CLK <= CLK_DIVIDER(24); --21
	 Clock_out <= SLOW_CLK;
end process;

nick_deb: DEBOUNCE PORT MAP (SLOW_CLK, Nickel, Np);
restock_deb: DEBOUNCE PORT MAP (SLOW_CLK, Restock, restock_temp);
quart_deb: DEBOUNCE PORT MAP (SLOW_CLK, Quarter, Qp);
dime_deb: DEBOUNCE PORT MAP (SLOW_CLK, Dime, Dp);
display: seven_segment PORT MAP (Clock, full_seven_segment, AN, Seven_segment_out);

Transitions: process (Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return,SLOW_CLK)
begin
	if Count = 45 then Cstate <= S16;
		elsif (SLOW_CLK'event and SLOW_CLK = '1') then
			case Cstate is
				when S0 => 										-- Ct = 0 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif Restock = '1' then
					Cstate <= S14;
					elsif Np = '1' then 
					Cstate <= S1;
					elsif Dp = '1' then
					Cstate <= S2;
					elsif Qp = '1' then
					Cstate <= S5;
					else
					Cstate <= S0;
					end if;
					Ct <= 0;
				
				when S1 =>										-- Ct = 5 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif Np = '1' then 
					Cstate <= S2;
					elsif Dp = '1' then
					Cstate <= S3;
					elsif Qp = '1' then
					Cstate <= S6;
					else
					Cstate <= S1;
					end if;
					Ct <= 5;
					
				when S2 =>										-- Ct = 10 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif Np = '1' then 
					Cstate <= S3;
					elsif Dp = '1' then
					Cstate <= S4;
					elsif Qp = '1' then
					Cstate <= S7;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S0;
					else
					Cstate <= S2;
					end if;
					Ct <= 10;
					
				when S3 =>										-- Ct = 15 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif Np = '1' then 
					Cstate <= S4;
					elsif Dp = '1' then
					Cstate <= S5;
					elsif Qp = '1' then
					Cstate <= S8;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S1;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S0;
					else
					Cstate <= S3;
					end if;
					Ct <= 15;
					
				when S4 =>										-- Ct = 20 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif Np = '1' then 
					Cstate <= S5;
					elsif Dp = '1' then
					Cstate <= S6;
					elsif Qp = '1' then
					Cstate <= S9;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S2;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S1;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S0;
					else
					Cstate <= S4;
					end if;
					Ct <= 20;
				when S5 =>										-- Ct = 25 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S3;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S2;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S1;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S0;
					elsif (Np = '1' or Dp = '1' or Qp = '1') then
					Cstate <= S16;
					else
					Cstate <= S5;
					end if;
					Ct <= 25;
					
				when S6 =>										-- Ct = 30 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S4;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S3;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S2;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S1;
					elsif (Np = '1' or Dp = '1' or Qp = '1') then
					Cstate <= S16;
					else
					Cstate <= S6;
					end if;
					Ct <= 30;
					
				when S7 =>										-- Ct = 35 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S5;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S4;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S3;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S2;
					elsif (Np = '1' or Dp = '1' or Qp = '1') then
					Cstate <= S16;
					else
					Cstate <= S7;
					end if;
					Ct <= 35;
					
				when S8 =>										-- Ct = 40 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S6;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S5;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S4;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S3;
					elsif (Np = '1' or Dp = '1' or Qp = '1') then
					Cstate <= S16;
					else
					Cstate <= S8;
					end if;
					Ct <= 40;
					
				when S9 =>										-- Ct = 45 Cents
					if Coin_Return = '1' then
					Cstate <= S16;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S7;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S6;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S5;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S4;
					elsif (Np = '1' or Dp = '1' or Qp = '1') then
					Cstate <= S16;
					else
					Cstate <= S9;
					end if;
					Ct <= 45;
				
				when S10 =>										-- Return Nickel State
					if (Ct > 0 and Ni = 0) then
						Cstate <= S13;
					elsif (Ct = 0) then
						Cstate <= S0;
					else
						Cstate <= S15;
						Ct <= Ct - 5;
					end if;
					
					
				when S11 =>										-- Return Dime State
					if (Ct < 10 or Dimei = 0) then
						Cstate <= S10;
					else
						Cstate <= S15;
						Ct <= Ct - 10;
					end if;
					
				
				when S12 =>										-- Return Quarter State
					null;
--					Cstate <= S11;
--					Ct <= Ct - 25;
					
				when S13 =>										-- Lockout State, Must Restock Machine
					if Restock = '1' then
					Cstate <= S14;
					else
					Cstate <= S13;
					end if;
				
				when S14 =>
					if (Ai < 5 or Bi < 5 or Ci < 5 or Di < 5) then
						Cstate<= S14;
					else
						Cstate <= S0;
					end if;

					
				when S15 =>										-- Blank State
					Cstate <= S11;
					
				when S16 =>
					if (Ct = 5) then
						Ct <= Ct - 5;
						Cstate <= S0;
					elsif (Ct = 10) then
						Ct <= Ct - 10;
						Cstate <= S0;
					elsif (Ct =15) then
						Ct <= Ct - 10;
						Cstate <= S17;
					elsif (Ct = 20) then
						Ct <= Ct -10;
						Cstate <= S17;
					elsif (Ct =25) then
						Ct <= Ct - 25;
						Cstate <= S17;
					elsif (Ct = 30) then
						Ct <= Ct - 25;
						Cstate <= S17;
					elsif (Ct = 35) then
						Ct <= Ct - 25;
						Cstate <= S17;
					elsif (Ct = 40) then
						Ct <= Ct - 25;
						Cstate <= S17;
					elsif (Ct = 45) then
						Ct <= Ct -25;
						Cstate <= S17;
					else 
						Ct <= 0;
						Cstate <= S0;
					end if;
			 
				when S17 =>
					Cstate <= S16;
				
					end case;
					end if;
					end process;

Outputs: Process(Cstate,Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return)
begin
--	Count <= 0;
	case Cstate is
		when S0 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' or VendB = '1' or VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			end if;
		
		when S1 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' or VendB = '1' or VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			end if;
			
		when S2 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' or VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			else
				null;
			end if;
			
		when S3 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			else
				null;
			end if;
			
		when S4 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1') then
				MoreCash <= '1';
			else
				null;
			end if;
		
		when S5 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			Di <= Di - 1;
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			else
				null;
			end if;

		when S6 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
				ProdA <= '1';
				Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
				ProdB <= '1';
				Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			Di <= Di - 1;
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			else
				null;
			end if;
			
		when S7 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			Di <= Di - 1;
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			else
				null;
			end if;
			
		when S8 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi<= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			Di <= Di - 1;
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			else
				null;
			end if;
			
		when S9 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			Ai <= Ai - 1;
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			Bi <= Bi - 1;
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			Ci <= Ci - 1;
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			Di <= Di - 1;
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			else
				null;
			end if;
			
		when S10 =>
		MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (Ct > 0 and Ni > 0) then
				RNick <= '1';
				Ni <= Ni - 1;
			end if;
			
		when S11 =>
		MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (Ct > 5 and Di > 0) then
				RDime <= '1';
				Dimei <= Dimei - 1;
			end if;
			
		when S12 =>
			null;
--			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
--			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
--			if (Ct > 20 and Qi > 0) then
--				RQuarter <= '1';
--				Qi <= Qi - 1;
--			end if;
			
		when S13 =>
			Lockout <= '1';
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; 
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
		
		when S14 =>
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			Ai <= 5;
			Bi <= 5;
			Ci <= 5;
			Di <= 5;
			Ni <= 5;
			Dimei <= 5;
			Qi <= 5;
			
			
		when S15 =>
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			
			
			
		when S16 => 
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			if (Ct = 5) then
						RNick <= '1';
						Ni <= Ni - 1;
			elsif (Ct = 10) then
						RDime <= '1';
						Dimei <= Dimei - 1;
			elsif (Ct =15) then
						RDime <= '1';
						Dimei <= Dimei - 1;
			elsif (Ct = 20) then
						RDime <= '1';
						Dimei <= Dimei - 1;
			elsif (Ct =25) then
						RQuarter <= '1';
						Qi <= Qi - 1;
			elsif (Ct = 30) then
						RQuarter <= '1';
						Qi <= Qi - 1;
			elsif (Ct = 35) then
						RQuarter <= '1';
						Qi <= Qi - 1;
			elsif (Ct = 40) then
						RQuarter <= '1';
						Qi <= Qi - 1;
			end if;
					
			
		when S17 =>
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			
		end case;
		end process;
sseg: Process(Cstate,Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return,ProdA, ProdB, ProdC, ProdD, Toggle_Hex1, Ai, Bi, Ci, Di, Ni, Qi, Dimei)
begin
		if (Toggle_Hex1 = '1') then
			Case Ai is
			when 0 => 
				full_seven_segment(6 downto 0) <=  "1000000"; 
			when 1 => 
				full_seven_segment(6 downto 0) <=  "1111001";
			when 2 => 	
				full_seven_segment(6 downto 0) <=  "0100100";
			when 3 => 
			full_seven_segment(6 downto 0) <=  "0110000";
			when 4 => 
				full_seven_segment(6 downto 0) <=  "0011001";
			when 5 => 
				full_seven_segment(6 downto 0) <=  "0010010";
			end case;
			Case Bi is
			when 0 => 
				full_seven_segment(13 downto 7) <=  "1000000"; 
			when 1 => 
				full_seven_segment(13 downto 7) <=  "1111001";
			when 2 => 	
				full_seven_segment(13 downto 7) <=  "0100100";
			when 3 => 
			full_seven_segment(13 downto 7) <=  "0110000";
			when 4 => 
				full_seven_segment(13 downto 7) <=  "0011001";
			when 5 => 
				full_seven_segment(13 downto 7) <=  "0010010";
			end case;
			Case Ci is
			when 0 => 
				full_seven_segment(20 downto 14) <=  "1000000"; 
			when 1 => 
				full_seven_segment(20 downto 14) <=  "1111001";
			when 2 => 	
				full_seven_segment(20 downto 14) <=  "0100100";
			when 3 => 
			full_seven_segment(20 downto 14) <=  "0110000";
			when 4 => 
				full_seven_segment(20 downto 14) <=  "0011001";
			when 5 => 
				full_seven_segment(20 downto 14) <=  "0010010";
			end case;
			Case Di is
			when 0 => 
				full_seven_segment(27 downto 21) <=  "1000000"; 
			when 1 => 
				full_seven_segment(27 downto 21) <=  "1111001";
			when 2 => 	
				full_seven_segment(27 downto 21) <=  "0100100";
			when 3 => 
			full_seven_segment(27 downto 21) <=  "0110000";
			when 4 => 
				full_seven_segment(27 downto 21) <=  "0011001";
			when 5 => 
				full_seven_segment(27 downto 21) <=  "0010010";
			end case;
		elsif (Toggle_Hex1 = '0') then
			if Cstate = S0 then
				full_seven_segment <= "1000000111111111111110010010";
			elsif Cstate = S1 then
				full_seven_segment <= "1111111111111111111110010010";
			elsif Cstate = S2 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				else 
					full_seven_segment <= "1111111111111110000001111001";
				end if;
			elsif Cstate = S3 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				else
					full_seven_segment <= "1111111111111100100101111001";
				end if;
			elsif Cstate = S4 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				else
					full_seven_segment <= "1111111111111110000000100100";
				end if;
			elsif Cstate = S5 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "1111111111111100100100100100";
				end if;
			elsif Cstate = S6 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "0001001100011010011110001100";
				end if;
			elsif Cstate = S6 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "0001001100011010011110001100";
				end if;
			elsif Cstate = S7 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "0001001100011010011110001100";
				end if;
			elsif Cstate = S8 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "0001001100011010011110001100";
				end if;
			elsif Cstate = S9 then
				if ProdA = '1' then
					full_seven_segment <= "0001000000100000010000001000";
				elsif ProdB = '1' then
					full_seven_segment <= "0000011000001100000110000011";
				elsif ProdC = '1' then
					full_seven_segment <= "1000110100011010001101000110";
				elsif ProdD = '1' then
					full_seven_segment <= "0100001010000101000010100001";
				else 
					full_seven_segment <= "0001001100011010011110001100";
				end if;
			elsif Cstate = S10 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S11 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S12 then
				full_seven_segment <= "1111111111111111111111111110";
			elsif Cstate = S13 then
				full_seven_segment <= "0001001100011010000001000111";
			elsif Cstate = S14 then
				full_seven_segment <= "1000111100011110000010001110";
			elsif Cstate = S15 then
				full_seven_segment <= "0111111011111101111110111111";
			elsif Cstate = S16 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S17 then
				full_seven_segment <= "0111111011111101111110111111";
	--		elsif ProdA = '1' then
	--			full_seven_segment <= "0001000000100000010000001000";
	--		elsif ProdB = '1' then
	--			full_seven_segment <= "0000011000001100000110000011";
	--		elsif ProdC = '1' then
	--			full_seven_segment <= "1000110100011010001101000110";
	--		elsif ProdD = '1' then
	--			full_seven_segment <= "0100001010000101000010100001";
			else
				full_seven_segment <= "1111111111111111111111111111";
	end if;
	end if;
end process;

--count: Process(Cstate,Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return, SLOW_CLK)
--	begin
--	if (SLOW_CLK'event and SLOW_CLK = '1') then
--		if(Np = '1' or Dp= '1' or Qp= '1' or VendA= '1' or VendB= '1' or VendC= '1' or VendD= '1' or Coin_Return = '1') then
--		Count <= 0;
--		else 
--		Count <= Count + 1;
--	end if; 
--	end if;
--	end process;
end Behavioral;

