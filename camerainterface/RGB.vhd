
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;



entity RGB is
    Port ( Din_l 	: in	STD_LOGIC_VECTOR (3 downto 0);	
           Din_r 	: in	STD_LOGIC_VECTOR (3 downto 0);		
		   Nblank : in	STD_LOGIC;								
																				
           R,G,B 	: out	STD_LOGIC_VECTOR (7 downto 0));		
end RGB;

architecture Behavioral of RGB is

signal Gray : std_logic_vector(7 downto 0);
begin
        Gray  <= (Din_r(3 downto 0) & Din_r(3 downto 0));
		R <= Gray when Nblank='1' else "00000000";
		G <= Gray  when Nblank='1' else "00000000";
		B <= Gray  when Nblank='1' else "00000000";

end Behavioral;

