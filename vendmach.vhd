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
		ProdA, ProdB, ProdC, ProdD, Decimal				 : out std_logic;
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

type state is (S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15);
signal Cstate: state;
Signal Np, Dp, Qp: std_logic;
signal Ct, Count: integer range 0 to 45;
signal Ai,Bi,Ci,Di,Ni,Dimei,Qi: integer range 0 to 5;
signal SLOW_CLK: std_logic;
signal CLK_DIVIDER: std_logic_vector(27 downto 0) := x"0000000";
signal full_seven_segment: STD_LOGIC_vector ( 27 downto 0);


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
quart_deb: DEBOUNCE PORT MAP (SLOW_CLK, Quarter, Qp);
dime_deb: DEBOUNCE PORT MAP (SLOW_CLK, Dime, Dp);
display: seven_segment PORT MAP (Clock, full_seven_segment, AN, Seven_segment_out);

Transitions: process (Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return,SLOW_CLK)
begin
	if Count = 45 then Cstate <= S12;
		elsif (SLOW_CLK'event and SLOW_CLK = '1') then
			case Cstate is
				when S0 => 										-- Ct = 0 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif Np = '1' then 
					Cstate <= S1;
					elsif Dp = '1' then
					Cstate <= S2;
					elsif Qp = '1' then
					Cstate <= S5;
					else
					Cstate <= S0;
					end if;
				
				when S1 =>										-- Ct = 5 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif Np = '1' then 
					Cstate <= S2;
					elsif Dp = '1' then
					Cstate <= S3;
					elsif Qp = '1' then
					Cstate <= S6;
					else
					Cstate <= S1;
					end if;
					
				when S2 =>										-- Ct = 10 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif Np = '1' then 
					Cstate <= S3;
					elsif Dp = '1' then
					Cstate <= S4;
					elsif Qp = '1' then
					Cstate <= S7;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S0;
					else
					Cstate <= S1;
					end if;
					
				when S3 =>										-- Ct = 15 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
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
					
				when S4 =>										-- Ct = 20 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
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
					
				when S5 =>										-- Ct = 25 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S3;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S2;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S1;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S0;
					else
					Cstate <= S5;
					end if;
					
				when S6 =>										-- Ct = 30 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S4;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S3;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S2;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S1;
					else
					Cstate <= S6;
					end if;
				
				when S7 =>										-- Ct = 35 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S5;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S4;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S3;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S2;
					else
					Cstate <= S7;
					end if;
					
				when S8 =>										-- Ct = 40 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S6;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S5;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S4;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S3;
					else
					Cstate <= S8;
					end if;
					
				when S9 =>										-- Ct = 45 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S7;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S6;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S5;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S4;
					else
					Cstate <= S9;
					end if;
				
				when S10 =>										-- Return Nickel State
					if (Ct > 0 and Ni = 0) then
						Cstate <= S13;
					elsif (Ct = 0) then
						Cstate <= S0;
					else
						Cstate <= S15;
					end if;
					
				when S11 =>										-- Return Dime State
					if (Ct < 10 or Dimei = 0) then
						Cstate <= S10;
					else
						Cstate <= S15;
					end if;
					
				when S12 =>										-- Return Quarter State
					Cstate <= S11;
					
				when S13 =>										-- Lockout State, Must Restock Machine
					if Restock = '1' then
					Cstate <= S14;
					else
					Cstate <= S13;
					end if;
				
				when S14 =>
					if Restock = '1' then
					Cstate <= S14;
					else 
					Cstate <= S0;
					end if;
					
				when S15 =>										-- Blank State
					Cstate <= S11;
					end case;
				Count <= Count + 1;
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
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' or VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			end if;
			
		when S3 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' or VendD = '1') then
				MoreCash <= '1';
			end if;
			
		when S4 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1') then
				MoreCash <= '1';
			end if;
		
		when S5 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			end if;

		when S6 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			end if;
			
		when S7 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			end if;
			
		when S8 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			end if;
			
		when S9 =>
		   MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (VendA = '1' and Ai > 0) then
			ProdA <= '1';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1';
			elsif (VendB = '1' and Bi > 0) then
			ProdB <= '1';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1';
			elsif (VendC = '1' and Ci > 0) then
			ProdC <= '1';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1';
			elsif (VendD = '1' and Di > 0) then
			ProdD <= '1';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1';
			end if;
			
		when S10 =>
		MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (Ct > 0 and Ni > 0) then
				RNick <= '1';
			end if;
			
		when S11 =>
		MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (Ct > 5 and Di > 0) then
				RDime <= '1';
			end if;
			
		when S12 =>
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			if (Ct > 20 and Qi > 0) then
				RQuarter <= '1';
			end if;
			
		when S13 =>
			Lockout <= '1';
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; 
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
		when S14 =>
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
	
			
			
		when S15 =>
			MoreCash <= '0';
			RNick <= '0'; RDime <= '0'; RQuarter <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end case;
			end process;
		
sseg: Process(Cstate,Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return)
begin
		if Cstate = S13 then
			full_seven_segment <= "1000000100000010000001000000";
		elsif Cstate = S0 then
			full_seven_segment <= "1000000100000010000001000000";
	end if;
end process;

end Behavioral;

