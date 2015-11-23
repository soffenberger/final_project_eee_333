--Synthesizable VHDL files contain three parts: library declarations, entity and
--behavior.  The library describes what each function will do.  For example, it defines 
--what a 2 input AND gate is and how it should function. Entity
--describes the inputs and outputs.  You can either have std-logic which can be thought 
--of as a single wire or std-logic-vector which can be thought of as a bus of wires. 
--A (3 downto 0) bus is the same as a four bit bus. Behavior is the working 
--portion of the project. There are two ways that work can be done. The first is by putting 
--the work statements outside the process. The other operation is to put the work statement 
--within the process. In this case, there is a sensitivity list that determines where the 
--work is performed. In the case of this tutorial , the clock or (clk) is in the sensitivity list. 
--This mean that the only time you will fall into the process is when something occurs on 
--the clk signal. Work within a process is acted upon sequentially. Processes are acted upon 
--concurrently (at the same time).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--Declaration of the module's inputs and outputs
entity Buff is port (
input: in std_logic_vector (2 downto 0);
bufferOut: out std_logic_vector (2 downto 0)
); 
end Buff;

--Defining the modules behavior
Architecture behavioral of regBuf is 
begin
bufferOut <= input; --send the input to bufferout
end behavioral;
