library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity color_change is
    Port (
		iClk : in std_logic := '0';
		ASCIIData : in std_logic_vector (7 downto 0) := x"00";
		keyboardPulse: in std_logic := '0';
		redPWMData: out std_logic_vector (7 downto 0) := x"00";
		greenPWMData: out std_logic_vector (7 downto 0) := x"00";
		bluePWMData: out std_logic_vector (7 downto 0) := x"00";
		color : out std_logic_vector (15 downto 0)
	);
end color_change;

architecture Behavioral of color_change is

type statemachine is (watch, enter);
signal state : statemachine := watch;
type characterArray is array (5 downto 0) of std_logic_vector(3 downto 0);
signal keyboardArray : characterArray;
signal registerPointer : integer range 0 to 5 := 0; --Pointer to know which array element you are currently looking at.
signal hex : std_logic_vector (3 downto 0) := x"0";

begin

process(iClk, keyboardPulse)
begin
	if rising_edge(iClk) then
	
		case state is
		
		when watch =>
			if (keyboardPulse = '1') then
				if(ASCIIData = x"43") then
					state <= enter;
				else
					state <= state;
				end if;
			end if;
		when enter =>
			if(keyboardPulse = '1') then
				if(ASCIIData = x"0D") then
					state <= watch;
					registerPointer <= 0; --resetting the pointer back to zero.
					color(11 downto 8) <= keyboardArray(0);
					color(7 downto 4) <= keyboardArray(2);
					color(3 downto 0) <= keyboardArray(4);
					redPWMData <= keyboardArray(0) & keyboardArray(1);
					greenPWMData <= keyboardArray(2) & keyboardArray(3);
					bluePWMData <= keyboardArray(4) & keyboardArray(5);
				--If the keyboard press is not a C, not a carriage return but is between 0-9 and A-F.
				elsif((ASCIIData >= x"30" and ASCIIData <= x"39") or (ASCIIData >= x"41" and ASCIIData <= x"46"))then
				
					keyboardArray(registerPointer) <= hex;
					if(registerPointer = 5) then --If the pointer is already at its max value it stays there.
						registerPointer <= 5;
					else
						registerPointer <= registerPointer + 1; --Otherwise increment.
					end if;
				
				elsif(ASCIIData = x"08") then --If the keypress was a backspace.
					keyboardArray(registerPointer) <= x"0";
					if(registerPointer = 0) then --if the pointer is at its minimum it stays at zero, otherwise decrement.
						registerPointer <= 0;
					else
						registerPointer <= registerPointer - 1; 
					end if;
				end if;
			end if;
		end case;
	end if;
end process;

process(iClk, keyboardPulse, ASCIIData, state)
begin
	if ((ASCIIData >= x"30" and ASCIIData <= x"39") or (ASCIIData >= x"41" and ASCIIData <= x"46"))then
		if(state = enter) then
			case ASCIIData is
			when x"30" => hex <= x"0";
			when x"31" => hex <= x"1";
			when x"32" => hex <= x"2";
			when x"33" => hex <= x"3";
			when x"34" => hex <= x"4";
			when x"35" => hex <= x"5";
			when x"36" => hex <= x"6";
			when x"37" => hex <= x"7";
			when x"38" => hex <= x"8";
			when x"39" => hex <= x"9";
			when x"41" => hex <= x"A";
			when x"42" => hex <= x"B";
			when x"43" => hex <= x"C";
			when x"44" => hex <= x"D";
			when x"45" => hex <= x"E";
			when x"46" => hex <= x"F";
			when others => hex <= x"0";
			end case;
		end if;
	end if;
end process;
end Behavioral;
