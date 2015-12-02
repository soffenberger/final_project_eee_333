--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:14:52 11/29/2015
-- Design Name:   
-- Module Name:   C:/Users/c16186/Documents/GitHub/final_project_eee_333/implementation_vending_machine/VendMachine_tb.vhd
-- Project Name:  implementation_vending_machine
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: VendMachine
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY VendMachine_tb IS
END VendMachine_tb;
 
ARCHITECTURE behavior OF VendMachine_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT VendMachine
    PORT(
         Nickel : IN  std_logic;
         Dime : IN  std_logic;
         Quarter : IN  std_logic;
         Coin_Return : IN  std_logic;
         Restock : IN  std_logic;
         reset : IN  std_logic;
         VendA : IN  std_logic;
         VendB : IN  std_logic;
         VendC : IN  std_logic;
         VendD : IN  std_logic;
         Clock : IN  std_logic;
         Toggle_Hex1 : IN  std_logic;
         Toggle_Hex2 : IN  std_logic;
         Toggle_Hex3 : IN  std_logic;
         AN : OUT  std_logic_vector(3 downto 0);
         Seven_segment_out : OUT  std_logic_vector(6 downto 0);
         Decimal : OUT  std_logic;
         RNick : OUT  std_logic;
         RDime : OUT  std_logic;
         RQuarter : OUT  std_logic;
         Clock_out : OUT  std_logic;
         MoreCash : OUT  std_logic;
         SoldOut : OUT  std_logic;
         LockOut : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Nickel : std_logic := '0';
   signal Dime : std_logic := '0';
   signal Quarter : std_logic := '0';
   signal Coin_Return : std_logic := '0';
   signal Restock : std_logic := '0';
   signal reset : std_logic := '0';
   signal VendA : std_logic := '0';
   signal VendB : std_logic := '0';
   signal VendC : std_logic := '0';
   signal VendD : std_logic := '0';
   signal Clock : std_logic := '0';
   signal Toggle_Hex1 : std_logic := '0';
   signal Toggle_Hex2 : std_logic := '0';
   signal Toggle_Hex3 : std_logic := '0';

 	--Outputs
   signal AN : std_logic_vector(3 downto 0);
   signal Seven_segment_out : std_logic_vector(6 downto 0);
   signal Decimal : std_logic;
   signal RNick : std_logic;
   signal RDime : std_logic;
   signal RQuarter : std_logic;
   signal Clock_out : std_logic;
   signal MoreCash : std_logic;
   signal SoldOut : std_logic;
   signal LockOut : std_logic;

   -- Clock period definitions
   constant Clock_period : time := 10 ns;
--   constant Clock_out_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: VendMachine PORT MAP (
          Nickel => Nickel,
          Dime => Dime,
          Quarter => Quarter,
          Coin_Return => Coin_Return,
          Restock => Restock,
          reset => reset,
          VendA => VendA,
          VendB => VendB,
          VendC => VendC,
          VendD => VendD,
          Clock => Clock,
          Toggle_Hex1 => Toggle_Hex1,
          Toggle_Hex2 => Toggle_Hex2,
          Toggle_Hex3 => Toggle_Hex3,
          AN => AN,
          Seven_segment_out => Seven_segment_out,
          Decimal => Decimal,
          RNick => RNick,
          RDime => RDime,
          RQuarter => RQuarter,
          Clock_out => Clock_out,
          MoreCash => MoreCash,
          SoldOut => SoldOut,
          LockOut => LockOut
        );

   -- Clock process definitions
   Clock_process :process
   begin
		Clock <= '0';
		wait for Clock_period/2;
		Clock <= '1';
		wait for Clock_period/2;
   end process;
 
--   Clock_out_process :process
--   begin
--		Clock_out <= '0';
--		wait for Clock_out_period/2;
--		Clock_out <= '1';
--		wait for Clock_out_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- insert stimulus here 
		reset <= '1';
		wait for 20 ns;
		reset <= '0';
		wait for 20 ns;
		
		Restock <= '1';
		wait for 20 ns;
		Restock <= '0';
		wait for 20 ns;
		
--Testing absolute combination for N,D,Q, VendA,VendB,VendC,VendD
      Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 100 ns;
		VendA <= '1';
		wait for 10 ns;
		VendA <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
      Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		

      Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
      Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 10 ns;
		Nickel <= '1';
		wait for 10 ns;
		Nickel <= '0';
		wait for 100 ns;
		VendD <= '1';
		wait for 10 ns;
		VendD <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Restock <= '1';
		wait for 10 ns;
		Restock <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendA <= '1';
		wait for 10 ns;
		VendA <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 20 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendD <= '1';
		wait for 10 ns;
		VendD <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Restock <= '1';
		wait for 10 ns;
		Restock <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendA <= '1';
		wait for 10 ns;
		VendA <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 50 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendD <= '1';
		wait for 10 ns;
		VendD <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
--Restock before testing various combinations		
		Restock <= '1';
		wait for 10 ns;
		Restock <= '0';
		wait for 300 ns;
		
--Testing Restock, MoreCash, Soldout
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 50 ns;		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
	
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
	
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
		
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
		
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
		
	--Insert 20 cents
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left

	--Here we should have no more of ProdB
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 50 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;		--ProdB has 4 left
		
	--Restock for ProdA
		Restock <= '1';
		wait for 10 ns;
		Restock <= '0';
		wait for 50 ns;
		
--Test Lockout Phase (this will take a while)
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Quarter <= '1';
		wait for 10 ns;
		Quarter <= '0';
		wait for 100 ns;
		VendC <= '1';
		wait for 10 ns;
		VendC <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;
		
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 10 ns;
		Dime <= '1';
		wait for 10 ns;
		Dime <= '0';
		wait for 100 ns;
		VendB <= '1';
		wait for 10 ns;
		VendB <= '0';
		wait for 20 ns;
		Coin_return <= '1';
		wait for 10 ns;
		Coin_return <= '0';
		wait for 100 ns;

      wait;
   end process;

END;
