--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:08:21 11/21/2015
-- Design Name:   
-- Module Name:   C:/Users/Spencer Offenberger/final_project_eee_333/buffer_tb.vhd
-- Project Name:  DesignProject3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Buff
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
 
ENTITY buffer_tb IS
END buffer_tb;
 
ARCHITECTURE behavior OF buffer_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Buff
    PORT(
         input : IN  std_logic_vector(2 downto 0);
         bufferOut : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal input : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal bufferOut : std_logic_vector(2 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Buff PORT MAP (
          input => input,
          bufferOut => bufferOut
        );

 
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		input <= "111";

      -- insert stimulus here 

      wait;
   end process;

END;
