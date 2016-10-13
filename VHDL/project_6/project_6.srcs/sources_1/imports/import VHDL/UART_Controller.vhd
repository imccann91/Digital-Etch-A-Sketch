library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Controller is
    Port ( 
			iClk : in std_logic := '0'; --100MHz clock.
			connLost :in std_logic := '0';
			keyboardPulse : in std_logic := '0'; --pulse from the keyboard stating that it has captured the scancode.
			xCoorData : in std_logic_vector (7 downto 0) := (others => '0'); --x corrdinate data.
			yCoorData : in std_logic_vector (7 downto 0) := (others => '0'); --y coordinate data.
			KeyboardASCII : in std_logic_vector (7 downto 0) := (others => '0'); --ASCII code from the keyboard ROM.
			color : in std_logic_vector (15 downto 0);
			startTrans : out std_logic := '0'; --Start transmitting data to the UART.
			dataToUART : out std_logic_vector (7 downto 0) := (others => '0') --Data sent to the UART.
		);
end UART_Controller;

architecture Behavioral of UART_Controller is

--type characterArray is array (19 downto 0) of std_logic_vector(7 downto 0);
--signal keyboardArray : characterArray;
--signal registerPointer : integer range 0 to 19 := 0; --Pointer to know which array element you are currently looking at.

type statemachine is (pause, transition, sendCoor, sendKeyboard);
signal state : statemachine := pause;
signal transData : std_logic_vector (7 downto 0) := (others => '0');
signal transmitting : std_logic := '0';

signal gapCounter : integer range 0 to 9999999 := 0; --1us gap between transmissions.
signal coordinateCount : integer range 0 to 3 := 0; --look-up table state.
signal keyboardSend : std_logic := '0';

signal waitCnt : integer range 0 to 9999999 := 0;
signal look : std_logic := '0';
signal prevXYData : std_logic_vector (15 downto 0) := x"0000";
signal switching : std_logic := '0';

signal transitionPulse : std_logic := '0';
signal count : integer range 0 to 4 := 0;

begin

--Process to control how often data is ent to the UART.
process(iClk, state)
begin
	if rising_edge(iClk) then
		if (state = sendCoor) then --If i'm in the appropriate state and the xY data has changed.
			if (gapCounter = 1999999) then
				--startTrans <= '1';
				transmitting <= '1';
				gapCounter <= 0;
			else
				--startTrans <= '0';
				transmitting <= '0';
				gapCounter <= gapCounter + 1;
			end if;
		else
			--startTrans <= '0';
			transmitting <= '0';
			gapCounter <= 0;
		end if;
	end if;
end process;

--Creates the pulse to the keyboard.
process(iClk, keyboardPulse)
begin
	if rising_edge(iClk) then
		if(keyboardPulse = '1') then
		keyboardSend <= '1';
		else
		keyboardSend <= '0';
		end if;
	end if;
end process;

--Controls how often we register new XY comparison data.
--process(iClk)
--begin
	--if rising_edge(iClk) then
		--if(waitCnt = 9999999) then
			--waitCnt <= 0;
			--look <= '1';
		--else
			--look <= '0';
			--waitCnt <= waitCnt + 1;
		--end if;
	--end if;
--end process;

--registering the X,Y coordinate data, so a camparison can be made between what it was before versus what it is now.
--process(iClk)
--begin
	--if rising_edge(iCLk) and look = '1' then
		--prevXYData <= xCoorData & yCoorData;
	--end if;
--end process;

--statemachine.
process(iClk, keyboardPulse)
begin
	if rising_edge(iClk) then
	
		case state is
		
		when pause =>
			--if (connLost = '1') then
				--state <= sendCoor; --change this too.
			--else
				--state <= sendCoor;
			--end if;
			--if(waitCnt = 1999999999) then --Counter here for debug perposes.
				--state <= sendCoor;
			--else
				--waitCnt <= waitCnt + 1;
			--end if;
			state <= sendCoor;
		when sendCoor =>
			--if(connLost = '1') then
				--state <= sendCoor; --change this later.
			if(keyboardPulse = '1') then
				--switching <= '1';
				state <= sendKeyboard;
				--if(switching = '1' and coordinateCount = 3)then
					--switching <= '0';
					--state <= transition;
				--else
					--switching <= '1';
					--state <= state;
				--end if;
			else
				--if(switching = '1' and coordinateCount = 4)then
					--switching <= '0';
					--dataToUART <= transData;
					--startTrans <= transmitting;
					--state <= transition;
				--elsif(coordinateCount <= 3) then --If the counter is in the weird 4th state don't send anything.
					--state <= state;
					dataToUART <= transData;
				--if (prevXYData /= (xCoorData & yCoorData)) then
					startTrans <= transmitting;
				--prevXYData <= xCoorData & yCoorData;
				--else
				--startTrans <= '0'; --Otherwise don't send anything.
				--end if;
				--else
					--startTrans <= '0';
				--end if;
			end if;
	
		when transition =>
			if(count < 3) then
				startTrans <= transitionPulse;
				dataToUART <= keyboardASCII;
			else
				state <= sendKeyboard;
			end if;
		when sendKeyboard =>
			--if(connLost = '1') then
				--state <= sendKeyboard; --change this.
			if(keyboardASCII = x"0D") then
					state <= sendCoor;
					dataToUART <= x"0D";
					startTrans <= keyboardPulse;
			else
					dataToUART <= keyboardASCII;
					startTrans <= keyboardPulse;
			end if;
		when others => null;
		end case;
	end if;
end process;

process(iClk)
begin
	if rising_edge(iClk) then
		if(state = transition)then
			if(count = 3) then
				count <= 0;
			else
				count <= count + 1;
			end if;
		else
			count <= 0;
		end if;
	end if;
		
		case count is 
			when 0 => transitionPulse <= '0';
			when 1 => transitionPulse <= '1';
			when 2 => transitionPulse <= '0';
			when others => transitionPulse <= '0';
			end case;
end process;

process(iClk, state)
begin
	if rising_edge(iClk) and transmitting = '1' then
		if(state = sendCoor) then --If the statemachine is in the state that allows coordinate data to be sent to the
								  --PC allow the bytes to change.
			if(coordinateCount = 3) then
				coordinateCount <= 0;
				--done <= '1';
			else
				coordinateCount <= coordinateCount + 1;
				--done <= '0';
			end if;
		else
			coordinateCount <= 0;
			--done <= '0';
		end if;
	end if;
	
	case coordinateCount is
		when 0 => transData <= x"58"; --Sending an ASCII "X" to denote following packet is x-coordinate data.
		when 1 => transData <= xCoorData; --8-bit x-coordinate data.
		when 2 => transData <= x"59"; --Sending an ASCII "Y" to denote the following packet is y-corrdinate data.
		when 3 => transData <= yCoorData; --8-bit corrdinate data.
		when others => transData <= x"00";
	end case;
	
end process;

end Behavioral;