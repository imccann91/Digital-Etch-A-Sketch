----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/22/2015 10:34:32 PM
-- Design Name: 
-- Module Name: width_change - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity width_change is
    Port ( iClk : in std_logic := '0';
		ASCIIData : in std_logic_vector (7 downto 0) := x"00";
		keyboardPulse: in std_logic := '0';
		cursorSize : out std_logic_vector (2 downto 0) := "000"
		);
end width_change;

architecture Behavioral of width_change is

type statemachine is (watch, enter);
signal state : statemachine := watch;
type characterArray is array (5 downto 0) of std_logic_vector(3 downto 0);
signal size : std_logic_vector (2 downto 0) := "000";
signal sizeReg : std_logic_vector (2 downto 0) := "000";

begin

process(iClk, keyboardPulse)
begin
	if rising_edge(iClk) then
	
		case state is
		
		when watch =>
			if (keyboardPulse = '1') then
				if(ASCIIData = x"57") then
					state <= enter;
				else
					state <= state;
				end if;
			end if;
		when enter =>
			if(keyboardPulse = '1') then
				if(ASCIIData = x"0D") then
					state <= watch;
					cursorSize <= sizeReg;
				--If the keyboard press is not 1-7, not a carriage return but is between 0-9 and A-F.
				elsif(ASCIIData >= x"31" and ASCIIData <= x"37")then
					sizeReg <= size;
				end if;
			end if;
		end case;
	end if;
end process;

process(iClk, keyboardPulse, ASCIIData, state)
begin
	if (ASCIIData >= x"31" and ASCIIData <= x"37")then
		if(state = enter) then
			case ASCIIData is
			when x"31" => size <= "001";
			when x"32" => size <= "010";
			when x"33" => size <= "011";
			when x"34" => size <= "100";
			when x"35" => size <= "101";
			when x"36" => size <= "110";
			when x"37" => size <= "111";
			when others => size <= "000";
			end case;
		end if;
	end if;
end process;


end Behavioral;
