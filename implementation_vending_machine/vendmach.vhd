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
--RNick, Ret_Dime, RQuarter:     Output signal to dispense change.
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
Port( Nickel, Dime, Quarter, Coin_Return, Restock, reset: in std_logic;
		VendA, VendB, VendC, VendD, Clock			 : in std_logic;
		Toggle_Hex1, Toggle_Hex2, Toggle_Hex3      : in std_logic;
		AN													 : out std_logic_vector(3 downto 0);
		Seven_segment_out									: out std_logic_vector(6 downto 0);
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

Component Buff is port (
	clock: in std_logic;
	input: in integer;
	bufferOut: out integer
); 
end Component;

type state is (S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16); -- State for the FSM
signal Cstate: state; 
Signal Np, Dp, Qp, restock_temp: std_logic; -- Debounced values
signal Ct: integer range 0 to 80; -- Credit the user has
shared variable Count: integer range 0 to 45; -- Count for the timeout
signal Ai,Bi,Ci,Di: integer range 0 to 5 :=5; -- Variables to track the inventory
signal Ni,Dimei,Qi: integer range 0 to 10 :=10;
signal Al,Bl,Cl,Dl: integer range 0 to 5 :=5; -- Buffer signals to track inventory
signal Nl,Dimel,Ql: integer range 0 to 10 :=10;
signal SLOW_CLK: std_logic; -- Slow clock to work the seven segment
signal ret_nick, ret_dime, ret_quart: std_logic;  -- Buffer signal for returning coins
signal CLK_DIVIDER: std_logic_vector(24 downto 0); -- Clock divider for slow clock
signal full_seven_segment: STD_LOGIC_vector ( 27 downto 0); -- A vector that can hold all the seven segment values
signal ProdA, ProdB, ProdC, ProdD : std_logic; -- Outputs high if the user gets product this helps with subtracting from inventorya and resetting count
signal timeout : std_logic := '0';  -- boolean variable to reset after inactivity
constant five_cons: integer := 5; -- Constant used when refilled

begin

Decimal<='1'; -- Decimal is always off in our instance


-- Divide the clock to approximately 3 Hz
CLK_DIVISION: process(Clock, CLK_DIVIDER)

begin
    if Clock'event and Clock = '1' then
        CLK_DIVIDER <= CLK_DIVIDER + 1;
    end if;
    SLOW_CLK <= CLK_DIVIDER(23); --21
	 Clock_out <= SLOW_CLK;
end process;

-- Debounce the user button inputs
nick_deb: DEBOUNCE PORT MAP (SLOW_CLK, Nickel, Np);
restock_deb: DEBOUNCE PORT MAP (SLOW_CLK, Restock, restock_temp);
quart_deb: DEBOUNCE PORT MAP (SLOW_CLK, Quarter, Qp);
dime_deb: DEBOUNCE PORT MAP (SLOW_CLK, Dime, Dp);

--Seven segment outputs the values in full_seven_segment to corresponding display
display: seven_segment PORT MAP (Clock, full_seven_segment, AN, Seven_segment_out);

-- Buffer signals for the signals storing inventorys
nick_buff: Buff PORT MAP (Clock, Ni, Nl);
dime_buff: Buff PORT MAP (Clock, Dimei, Dimel);
quarter_buff: Buff PORT MAP (Clock, Qi, Ql);
A_buff: Buff PORT MAP (Clock, Ai, Al);
B_buff: Buff PORT MAP (Clock, Bi, Bl);
C_buff: Buff PORT MAP (Clock, Ci, Cl);
D_buff: Buff PORT MAP (Clock, Di, Dl);

-- This determines the next state in 
Transitions: process (Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return,SLOW_CLK, reset, timeout)
begin
	if timeout = '1' then Cstate <= S12;  --Give change back on timeout state
	elsif reset = '1' then -- Reset allows for easier testing
		Cstate <= S0;
	elsif (SLOW_CLK'event and SLOW_CLK = '1') then
			case Cstate is
				when S0 => 										-- Ct = 0 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
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
					Ct <= 5;
					
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
					Cstate <= S2;
					end if;
					Ct <= 10;
					
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
					Ct <= 15;
					
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
					Cstate <= S16;
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
					Cstate <= S12;
					Ct <= 25;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S16;
					Ct <= 25;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S2;
					Ct <= 25;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S1;
					Ct <= 25;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S0;
					Ct <= 25;
					elsif (Np = '1') then
					Cstate <= S12;
					Ct <= 30;
					elsif Dp = '1' then
					Ct <= 35;
					elsif Qp = '1' then
					Cstate <= S12;
					Ct <= 50;
					else
					Cstate <= S5;
					Ct <= 25;
					end if;
					
				when S6 =>										-- Ct = 30 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					Ct <= 30;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S16;
					Ct <= 30;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S16;
					Ct <= 30;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S2;
					Ct <= 30;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S1;
					Ct <= 30;
					elsif (Np = '1') then
					Cstate <= S12;
					Ct <= 35;
					elsif Dp = '1' then
					Ct <= 40;
					elsif Qp = '1' then
					Cstate <= S12;
					Ct <= 55;
					else
					Cstate <= S6;
					Ct <= 30;
					end if;
					
					
				when S7 =>										-- Ct = 35 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					Ct <= 35;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S16;
					Ct <= 35;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S16;
					Ct <= 35;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S3;
					Ct <= 35;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S2;
					Ct <= 35;
					elsif (Np = '1') then
					Cstate <= S12;
					Ct <= 40;
					elsif Dp = '1' then
					Ct <= 55;
					elsif Qp = '1' then
					Cstate <= S12;
					Ct <= 60;
					else
					Cstate <= S7;
					Ct <= 35;
					end if;
					
					
				when S8 =>										-- Ct = 40 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					Ct <= 40;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S16;
					Ct <= 40;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S16;
					Ct <= 40;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S16;
					Ct <= 40;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S3;
					Ct <= 40;
					elsif (Np = '1') then
					Cstate <= S12;
					Ct <= 45;
					elsif Dp = '1' then
					Ct <= 50;
					elsif Qp = '1' then
					Cstate <= S12;
					Ct <= 65;
					else
					Cstate <= S8;
					Ct <= 40;
					end if;
					
					
				when S9 =>										-- Ct = 45 Cents
					if Coin_Return = '1' then
					Cstate <= S12;
					Ct <= 45;
					elsif (VendA = '1' and Ai > 0) then
					Cstate <= S16;
					Ct <= 45;
					elsif (VendB = '1' and Bi > 0) then
					Cstate <= S16;
					Ct <= 45;
					elsif (VendC = '1' and Ci > 0) then
					Cstate <= S16;
					Ct <= 45;
					elsif (VendD = '1' and Di > 0) then
					Cstate <= S4;
					Ct <= 45;
					elsif (Np = '1') then
					Cstate <= S12;
					Ct <= 50;
					elsif Dp = '1' then
					Ct <= 55;
					elsif Qp = '1' then
					Cstate <= S12;
					Ct <= 70;
					else
					Cstate <= S9;
					Ct <= 45;
					end if;
					
				
				when S10 =>										-- Return Nickel State
					if (Ct > 0 and Ni = 0) then
						Cstate <= S13;
						Ct <= Ct - 5;
					elsif (Ct = 0) then
						Cstate <= S0;
					else
						Cstate <= S15;
						Ct <= Ct - 5;
					end if;
					
					
				when S11 =>										-- Return Dime State
					if (Ct < 10 or Dimei = 0) then
						Cstate <= S10;
					elsif (Di =0 and Ni = 0) then
						Cstate <= S13;
						Ct <= Ct - 10;
					else
						Cstate <= S15;
						Ct <= Ct - 10;
					end if;
					
				
				when S12 =>										-- Return Quarter State
					if (Ct >= 25) then
						Ct <= Ct - 25;
						Cstate <= S15;
					elsif Qi = 0 and Ni = 0 then
						Cstate <= S13;
						Ct <= 0;
					else
						Ct <= Ct;
						Cstate <= S11;
					end if;
					
					
				when S13 =>										-- Lockout State, Must Restock Machine
					Ct <= 0;
					if Restock = '1' then
					Cstate <= S14;
					else
					if Np = '1' then
						Ct <= 5;
					elsif Dp = '1' then
						Ct <= 10;
					elsif Qp = '1' then
						Ct <= 25;
					end if;
					Cstate <= S13;
					end if;
				
				when S14 =>
					if (Ai < 5 or Bi < 5 or Ci < 5 or Di < 5) then
						Cstate<= S14;
					else
						Cstate <= S0;
					end if;

					
				when S15 =>										-- Blank State
					if Ct >= 25 then
						Cstate <= S12;
					elsif Ct < 25 and Ct >= 10 then
						Cstate <= S11;
					else 
						Cstate <= S10;
					end if;
				
				when S16 =>
					if Ct = 20 and VendA = '1' then
						Cstate <= S2;
						Ct <= Ct - 10;
					elsif Ct = 25 and VendA = '1' then
						Cstate <= S3;
						Ct <= Ct - 10;
					elsif Ct = 30 and VendA = '1' then
						Cstate <= S4;
						Ct <= Ct - 10;
					elsif Ct = 30 and VendB = '1' then
						Cstate <= S3;
						Ct <= Ct -15;
					elsif Ct = 35 and VendA = '1' then
						Cstate <= S5;
						Ct <= Ct - 10;
					elsif Ct = 35 and VendB = '1' then
						Cstate <= S4;
						Ct <= Ct -15;
					elsif Ct = 40 and VendA = '1' then
						Cstate <= S6;
						Ct <= Ct - 10;
					elsif Ct = 40 and VendB = '1' then
						Cstate <= S5;
						Ct <= Ct -15;
					elsif Ct = 40 and VendC = '1' then
						Cstate <= S4;
						Ct <= Ct - 20;
					elsif Ct = 45 and VendA = '1' then
						Cstate <= S7;
						Ct <= Ct -15;
					elsif Ct = 45 and VendB = '1' then
						Cstate <= S6;
						Ct <= Ct -15;
					elsif Ct = 45 and VendC = '1' then
						Cstate <= S5;
						Ct <= Ct - 20;
					elsif Ct = 20 and VendA = '0' then
						Cstate <= S2;
					elsif Ct = 25 and VendA = '0' then
						Cstate <= S3;
					elsif Ct = 30 and VendA = '0' then
						Cstate <= S4;
					elsif Ct = 30 and VendB = '0' then
						Cstate <= S3;
					elsif Ct = 35 and VendA = '0' then
						Cstate <= S5;
					elsif Ct = 35 and VendB = '0' then
						Cstate <= S4;
					elsif Ct = 40 and VendA = '0' then
						Cstate <= S6;
					elsif Ct = 40 and VendB = '0' then
						Cstate <= S5;
					elsif Ct = 40 and VendC = '0' then
						Cstate <= S4;
					elsif Ct = 45 and VendA = '0' then
						Cstate <= S7;
					elsif Ct = 45 and VendB = '0' then
						Cstate <= S6;
					elsif Ct = 45 and VendC = '0' then
						Cstate <= S5;
					else 
						Cstate <= S0;
					
					end if;
				
					end case;
					end if;
					end process;

Outputs: Process(Cstate,Np,Dp,Qp,Coin_Return, VendA, VendB, VendC, VendD, reset, Ai, Bi, Ci, Di, Ct, Ni)
begin
	case Cstate is
		when S0 =>
			if (VendA = '1' or VendB = '1' or VendC = '1' or VendD = '1') then -- need more money
				MoreCash <= '1';
			else 
				MoreCash <= '0';
			end if;
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
		
		when S1 => 
			if (VendA = '1' or VendB = '1' or VendC = '1' or VendD = '1') then -- need more money
				MoreCash <= '1';
			else 
				MoreCash <= '0';
			end if;
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			
		when S2 =>
			if (VendA = '1' and Ai > 0) then -- vend A
				ProdA <= '1'; MoreCash <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then -- A is soldout
				Soldout <= '1';
				ProdA <= '0'; MoreCash <= '0';
			elsif (VendB = '1' or VendC = '1' or VendD = '1') then --need more money
				MoreCash <= '1';
				Soldout <= '0'; ProdA <= '0';
			else 
				MoreCash <= '0'; Soldout <= '0'; ProdA <= '0';
			end if;
			 ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0';  Lockout <= '0';
			
		when S3 =>
			if (VendA = '1' and Ai > 0) then -- vend A
				ProdA <= '1'; Soldout <= '0'; MoreCash <= '0'; ProdB <= '0';
			elsif (VendA = '1' and Ai = 0) then -- Soldout 
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; MoreCash <= '0';
			elsif (VendB = '1' and Bi > 0) then -- vend B
				ProdB <= '1'; Soldout <= '0';  ProdB <= '0'; MoreCash <= '0';
			elsif (VendB = '1' and Bi = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; MoreCash <= '0';
			elsif (VendC = '1' or VendD = '1') then -- Need money
				MoreCash <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0';
			else
				MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; Soldout <= '0';
			end if;
			ProdC <= '0'; ProdD <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Lockout <= '0';
			
		when S4 =>
			if (VendA = '1' and Ai > 0) then -- vend A
			ProdA <= '1'; Soldout <= '0'; MoreCash <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendA = '1' and Ai = 0) then --Soldout
				Soldout <= '1'; MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendB = '1' and Bi > 0) then -- vend B
				ProdB <= '1'; Soldout <= '0'; MoreCash <= '0'; ProdA <= '0'; ProdC <= '0';
			elsif (VendB = '1' and Bi = 0) then -- Soldout
				Soldout <= '1'; MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendC = '1' and Ci > 0) then --vend C
				ProdC <= '1'; Soldout <= '0'; MoreCash <= '0'; ProdA <= '0'; ProdB <= '0';
			elsif (VendC = '1' and Ci = 0) then -- Soldout
				Soldout <= '1'; MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1') then -- Need money
				MoreCash <= '1'; ProdB <= '0'; Soldout <= '0'; MoreCash <= '0'; ProdA <= '0'; ProdC <= '0';
			else
				MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; Soldout <= '0';
			end if;
				ProdD <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Lockout <= '0';
		
		when S5 =>
			if (VendA = '1' and Ai > 0) then -- vend A
				ProdA <= '1'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi > 0) then --vend B
				ProdB <= '1'; Soldout <= '0'; ProdA <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi = 0) then -- Soldout 
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci > 0) then --Vend C
				ProdC <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci = 0) then -- Soldout 
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendD = '1' and Di > 0) then -- Vend D
				ProdD <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1' and Di = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else
				Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
			MoreCash <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0';  Lockout <= '0';

		when S6 =>
			if (VendA = '1' and Ai > 0) then --vend A
				ProdA <= '1'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then -- Soldout 
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi > 0) then -- vend B
				ProdB <= '1'; Soldout <= '0'; ProdA <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi = 0) then --Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci > 0) then -- vend C
				ProdC <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendD = '1' and Di > 0) then -- vend D
				ProdD <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1' and Di = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else
				Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
			MoreCash <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Lockout <= '0';
			
		when S7 =>
			if (VendA = '1' and Ai > 0) then --vend A
				ProdA <= '1';  ProdB <= '0'; ProdC <= '0'; ProdD <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi > 0) then --vend B
				ProdB <= '1'; Soldout <= '0'; ProdA <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci > 0) then -- vend C
				ProdC <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendD = '1' and Di > 0) then -- vend D
				ProdD <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1' and Di = 0) then -- Soldout
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else
				Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
			MoreCash <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Lockout <= '0';
			
		when S8 =>
			if (VendA = '1' and Ai > 0) then
				ProdA <= '1'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi > 0) then
				ProdB <= '1'; Soldout <= '0'; ProdA <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci > 0) then
				ProdC <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendD = '1' and Di > 0) then
				ProdD <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else
				Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
			MoreCash <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0';
			
		when S9 =>
			if (VendA = '1' and Ai > 0) then
				ProdA <= '1'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0'; Soldout <= '0';
			elsif (VendA = '1' and Ai = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi > 0) then
				ProdB <= '1'; Soldout <= '0'; ProdA <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendB = '1' and Bi = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci > 0) then
				ProdC <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdD <= '0';
			elsif (VendC = '1' and Ci = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif (VendD = '1' and Di > 0) then
				ProdD <= '1'; Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0';
			elsif (VendD = '1' and Di = 0) then
				Soldout <= '1'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else
				Soldout <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
			MoreCash <= '0'; ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Lockout <= '0';
			
		when S10 =>
			if (Ct > 0 and Ni > 0) then
				ret_nick <= '1';
			else
				ret_nick <= '0';
			end if;
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			
		when S11 =>
			if (Ct > 5 and Dimei > 0) then
				Ret_Dime <= '1';
			else
				Ret_Dime <= '0';
			end if;
			MoreCash <= '0'; ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			ret_nick <= '0';  Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			
		when S12 =>
			if Ct >= 25 and Qi >= 1 then
				MoreCash <= '0';
				ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '1'; Soldout <= '0'; Lockout <= '0';
				ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			elsif Ct >= 25 and Qi = 0 then
				MoreCash <= '0';
				ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
				ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			else 
				MoreCash <= '0';
				ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
				ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			end if;
				
		when S13 =>
			Lockout <= '1';
			MoreCash <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; 
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			if Ct = 5 then
				ret_nick <= '1';
			elsif Ct = 10 then
				ret_dime <= '1';
			elsif Ct = 25 then
				ret_Quart <= '1';
			end if;
		
		when S14 =>
			MoreCash <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			
			
		when S15 =>
			MoreCash <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			
			
		when S16 => 
			MoreCash <= '0';
			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
--			
--			if (Ct = 5) then
--						ret_nick <= '1';
--			elsif (Ct = 10) then
--						Ret_Dime <= '1';
--			elsif (Ct =15) then
--						Ret_Dime <= '1';
--			elsif (Ct = 20) then
--						Ret_Dime <= '1';
--			elsif (Ct =25) then
--						Ret_Quart <= '1';
--			elsif (Ct = 30) then
--						Ret_Quart <= '1';
--			elsif (Ct = 35) then
--						Ret_Quart <= '1';
--			elsif (Ct = 40) then
--						Ret_Quart <= '1';
--			else
--				ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0';
--			end if;
--			MoreCash <= '0';
--			 Soldout <= '0'; Lockout <= '0';
--			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
--					
--			
--		when S17 =>
--			MoreCash <= '0';
--			ret_nick <= '0'; Ret_Dime <= '0'; Ret_Quart <= '0'; Soldout <= '0'; Lockout <= '0';
--			ProdA <= '0'; ProdB <= '0'; ProdC <= '0'; ProdD <= '0';
			
		end case;
		end process;
		
sseg: Process(Dimei, Qi, Cstate,Np,Dp,Qp,VendA,VendB,VendC,VendD,Coin_Return,ProdA, ProdB, ProdC, ProdD, Toggle_Hex1, Toggle_Hex2, Ai, Bi, Ci, Di, Ct, Ni,SLOW_CLK)
begin
		if (Toggle_Hex1 = '1' and Toggle_Hex2 = '0') then
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
			when others =>
				full_seven_segment(6 downto 0) <=  "1111111";
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
			when others =>
				full_seven_segment(13 downto 7) <=  "1111111";
			end case;
			Case Ci is
			when 0 => 
				full_seven_segment(20 downto 14) <=  "1000000"; 
			when 1			=> 
				full_seven_segment(20 downto 14) <=  "1111001";
			when 2 => 	
				full_seven_segment(20 downto 14) <=  "0100100";
			when 3 => 
			full_seven_segment(20 downto 14) <=  "0110000";
			when 4 => 
				full_seven_segment(20 downto 14) <=  "0011001";
			when 5 => 
				full_seven_segment(20 downto 14) <=  "0010010";
			when others =>
				full_seven_segment(20 downto 14) <=  "1111111";
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
			when others => 
				full_seven_segment(27 downto 21) <=  "1111111";
			end case;
		elsif (Toggle_Hex1 = '0' and Toggle_Hex2 = '1')then
			Case Ni is
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
			when 6 => 
				full_seven_segment(6 downto 0) <=  "0000010"; 
			when 7 => 
				full_seven_segment(6 downto 0) <=  "1111000";
			when 8 => 	
				full_seven_segment(6 downto 0) <=  "0000000";
			when 9 => 
				full_seven_segment(6 downto 0) <=  "0010000";
			when 10 => 
				full_seven_segment(6 downto 0) <=  "0001000";
			when others =>
				full_seven_segment(6 downto 0) <=  "1000000";
			end case;
			Case Dimei is
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
			when 6 => 
				full_seven_segment(13 downto 7) <=  "0000010"; 
			when 7 => 
				full_seven_segment(13 downto 7) <=  "1111000";
			when 8 => 	
				full_seven_segment(13 downto 7) <=  "0000000";
			when 9 => 
				full_seven_segment(13 downto 7) <=  "0010000";
			when 10 => 
				full_seven_segment(13 downto 7) <=  "0001000";
			when others =>
				full_seven_segment(13 downto 7) <=  "1000000";
			end case;
			Case Qi is
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
			when 6 => 
				full_seven_segment(20 downto 14) <=  "0000010"; 
			when 7 => 
				full_seven_segment(20 downto 14) <=  "1111000";
			when 8 => 	
				full_seven_segment(20 downto 14) <=  "0000000";
			when 9 => 
				full_seven_segment(20 downto 14) <=  "0010000";
			when 10 => 
				full_seven_segment(20 downto 14) <=  "0001000";
			when others =>
				full_seven_segment(20 downto 14) <=  "1000000";
			end case;
				full_seven_segment(27 downto 21) <=  "1111111"; 
		elsif (Toggle_Hex1 = '0' and Toggle_Hex2 = '0') then
			if Cstate = S0 then
				full_seven_segment <= "1111111111111110011110001001";
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
--			elsif Cstate = S6 then
--				if ProdA = '1' then
--					full_seven_segment <= "0001000000100000010000001000";
--				elsif ProdB = '1' then
--					full_seven_segment <= "0000011000001100000110000011";
--				elsif ProdC = '1' then
--					full_seven_segment <= "1000110100011010001101000110";
--				elsif ProdD = '1' then
--					full_seven_segment <= "0100001010000101000010100001";
--				else 
--					full_seven_segment <= "11111111111111100100100100100";
--				end if;
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
					full_seven_segment <= "1111111111111110000000110000";
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
					full_seven_segment <= "1111111111111100100100110000";
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
					full_seven_segment <= "1111111111111110000000110001";
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
					full_seven_segment <= "1111111111111100100100110001";
				end if;
			elsif Cstate = S10 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S11 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S12 then
				full_seven_segment <= "1111111000001000010011000110";
			elsif Cstate = S13 then
				full_seven_segment <= "0001001100011010000001000111";
			elsif Cstate = S14 then
				full_seven_segment <= "1000111100011110000010001110";
			elsif Cstate = S15 then
				full_seven_segment <= "0111111011111101111110111111";
			elsif Cstate = S16 then
				full_seven_segment <= "0111111011111101111110111111";
--			elsif Cstate = S17 then
--				full_seven_segment <= "0111111011111101111110111111";
			else
				full_seven_segment <= "1111111111111111111111111111";
			end if;
			else 
				full_seven_segment <= "1111111111111111111111111111";
	
	end if;
end process;
	
update_inventory: process(SLOW_CLK,Cstate, prodA, prodB, prodC, prodD, reset, ret_nick, ret_dime, ret_quart, Al, Bl, Cl, Dl, Dimel, Nl, Ql) begin
		if SLOW_CLK'event and SLOW_CLK = '1' then
		if Cstate = S14 then
			Ai <= five_cons;
			Bi <= five_cons;
			Ci <= five_cons;
			Di <= five_cons;
			Ni <= 10;
			Dimei <= 10;
			Qi <= 10;
		elsif reset = '1' then
			Ai <= 5;
			Bi <= 5;
			Ci <= 5;
			Di <= 5;
			Ni <= 10;
			Dimei <= 10;
			Qi <= 10;
		elsif prodA = '1' then
			Ai <= Al;
			Bi <= Bi;
			Ci <= Ci;
			Di <= Di;
			Ni <= Ni;
			Dimei <= Dimei;
			Qi <= Qi;
		elsif prodB = '1' then
			Bi <= Bl;
			Ni <= Ni;
			Dimei <= Dimei;
			Qi <= Qi;
			Ai <= Ai;
			Ci <= Ci;
			Di <= Di; 
		elsif ProdC = '1' then
			Ci <= Cl;
			Ni <= Ni;
			Dimei <= Dimei;
			Qi <= Qi;
			Ai <= Ai;
			Bi <= Bi;
			Di <= Di;
		elsif prodD = '1' then
			Di <= Dl;
			Ni <= Ni;
			Dimei <= Dimei;
			Qi <= Qi;
			Ai <= Ai;
			Bi <= Bi;
			Ci <= Ci;
		elsif Ret_Quart = '1' then
			Qi <= Ql;
			Ni <= Ni;
			Dimei <= Dimei;
			Ai <= Ai;
			Bi <= Bi;
			Ci <= Ci;
			Di <= Di;
		elsif Ret_Dime = '1' then
			Dimei <= Dimel;
			Ni <= Ni;
			Qi <= Qi;
			Ai <= Ai;
			Bi <= Bi;
			Ci <= Ci;
			Di <= Di; 
		elsif Ret_Nick = '1' then
			Ni <= Nl;
			Dimei <= Dimei;
			Qi <= Qi;
			Ai <= Ai;
			Bi <= Bi;
			Ci <= Ci;
			Di <= Di;
		else 
			Ni <= Ni;
			Dimei <= Dimei;
			Qi <= Qi;
			Ai <= Ai;
			Bi <= Bi;
			Ci <= Ci;
			Di <= Di; 
		end if;
	end if;
end process;

increment_count: process (SLOW_CLK, Np,Dp,Qp,VendA,VendB,VendC,VendD) begin
	if (SLOW_CLK'event and SLOW_CLK = '1') then
		if (Count = 45) then
			timeout <= '1';
			Count := 0;
		elsif (Np = '1' or Dp = '1' or Qp = '1' or VendA = '1' or VendB = '1' or VendC = '1' or VendD = '1') then
			Count := 0;
			timeout <= '0';
		else
			timeout <= '0';
			Count := Count + 1;
		end if;
	end if;
end process;

RQuarter <= Ret_Quart;
RDime <= Ret_Dime;
RNick <= Ret_Nick;


end Behavioral;

