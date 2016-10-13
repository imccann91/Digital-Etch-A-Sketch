--Created by Ian McCann
--Created: 4/17/2015
--Last Modified: 4/17/2015
--Controls what data is shown on the LCD, this includes input sequences from the keyboard,
-- the current color, the current width of the pen, and the current screen size.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LCD_Controller is
    Port ( iClk : in STD_LOGIC := '0'; --100MHz clock.
		   initDone : in std_logic := '0'; --Control bit that tells the controller when initialization has been completed.
           trigger : in STD_LOGIC := '0'; --Goes high when a key on the keyboard has been press, or some other event.
		   connLost : in std_logic := '0'; --Input that allows the controller to know when the hardware has lost communications.
           ASCIICode : in STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --ASCII code for a character from the keyboard or other component.
		   canvasSize : in std_logic := '0'; --the canvas size (0=256x256 1=362x362)
           oLCDRs : out STD_LOGIC := '0'; --Whether what is sent to the LCD was an instruction or a character (0=instruction 1=character)
           oLCDEn : out STD_LOGIC := '0'; --CLD enable signal.
           oLCDData : out STD_LOGIC_VECTOR (3 downto 0) := (others => '0') --4-bit data to the LCD.
		   );
end LCD_Controller;


architecture Behavioral of LCD_Controller is

--Containes the message stating that the hardware has lost connection.
component smallCanvasMessage is
	port(
		clka : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end component;

--Containes the message stating that the hardware has lost connection.
component bigCanvasMessage is
	port(
		clka : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end component;

type statemachine is (startup, showInfo, listen, backspace, enter, changeCanvas); --Statemachine.
signal state : statemachine := startup; --State signal.

signal clk_en_200hz : STD_LOGIC := '0';--impulse 200 times a second = 5 milliseconds
signal cnt_200hz    : INTEGER  RANGE 1 to 500001 := 1;--count this many clock cycles then do an impulse
signal clk_en_600hz : STD_LOGIC := '0';--impulse 600 times a second
signal cnt_600hz    : INTEGER  RANGE 1 to 166667 := 1;--count this many clock cycles then do an impulse

signal sel : integer range 1 to 3 := 1; --Enable signal selection bit.

signal cnt3Sec : integer range 0 to 299999999 := 0; --Counter that counts 3 seconds before moving back into the "showInfo" state.

signal prevCanvas : std_logic := '0'; --Control bit that stores what canvas size was used in the previous clock cycle.
signal smallAddr : std_logic_vector (5 downto 0) := (others => '0');
signal smallData : std_logic_vector (7 downto 0) := (others => '0');
signal bigAddr : std_logic_vector (5 downto 0) := (others => '0');
signal bigData : std_logic_vector (7 downto 0) := (others => '0');

begin

--5mS clock enabler that if the statemachine is within the either the "alert" state or the "reset" state the
--counter is free to count, otherwise it will remain at 1.
process(iClk, state)
begin
	if rising_edge(iClk) then
		if(state = changeCanvas) then --Modify later to include additional states.
			if(cnt_200hz = 500001)then --500001 actual 15 for sim
				cnt_200hz <= 1;
				clk_en_200hz <= '1';
			else
				cnt_200hz <= cnt_200hz + 1;
				clk_en_200hz <= '0';
			end if;
		else
			cnt_200hz <= 1;
			clk_en_200hz <= '0';
		end if;
	end if;
end process;

--Clock enabler for the LCD enable signal.
PROCESS(iClk, state)--The clk enabler for 600hz
BEGIN
      --clock part
    IF RISING_EDGE (iClk) THEN
		if(state = changeCanvas) then --Modify later to include additional states.
			IF (cnt_600hz = 166667) THEN -- 5 in sim, otherwise 166667 for approx 600hz... 
										 -- The integer division is impossible so this is a compromise
				clk_en_600hz <= '1';--pulse high
				cnt_600hz <= 1;--reset the count
			ELSE
				clk_en_600hz <= '0';--stay low
				cnt_600hz <= cnt_600hz + 1;--increment count
			END IF;
		else
			cnt_600hz <= 1;
			clk_en_600hz <= '0';
		end if;
    END IF;
END PROCESS;

--Clock enabler that controles the LCD's enable signal.
PROCESS(iClk, clk_en_600hz, state)
BEGIN
    	--clock part
    	IF(RISING_EDGE (iClk) and  clk_en_600hz = '1')then
			if(state = changeCanvas) THEN --Modify later to include additional states.
				IF (sel = 3) THEN
					sel <= 1;
				ELSE
					sel <= sel + 1;
				END IF;
			else
				sel <= 1;
			end if;
    	END IF;
    	--combinational part
    CASE sel IS
    	WHEN 1=> oLCDEn <= '0';
    	WHEN 2=> oLCDEn <= '1';
    	WHEN 3=> oLCDEn <= '0';
    	WHEN OTHERS => oLCDEn <= '0';
  	END CASE;
END PROCESS;

process(iClk, trigger, initDone)
begin
	if rising_edge(iClk) then
	
		case state is
		
		when startup =>
			if(initDone = '0')then
				state <= state;
			else
				if(cnt3Sec = 299999999)then --After 3 seconds have passed move into showing the info.
					cnt3Sec <= 0;
					state <= showInfo;
				else
					cnt3Sec <= cnt3Sec + 1;
				end if;
			end if;
			
		when showInfo => --NEEDS IMPLEMENTATION/REMOVAL.
			state <= listen;
			
		when listen =>
			prevCanvas <= canvasSize; --Storing the canvas size.
			
			if(prevCanvas /= canvasSize) then --If the previous state of the canvas size is different than before, change the message.
				state <= changeCanvas;
			else
				state <= state;
			end if;
		
		when backspace => --NEEDS IMPLEMENTATION.
			state <= listen;
			
		when enter => --NEEDS IMPLEMENTATION.
			state <= listen; 
			
		when changeCanvas =>
			if(clk_en_200hz = '1') then
				if (canvasSize = '0') then --If sw0 is 0. show the smaller canvas size.
					--Generate addresses for the ROM that containes the 256x256 message.
					IF (smallAddr <= "011011") THEN--are we at 27?
						smallAddr <= std_logic_vector( unsigned ( smallAddr) + 1);--increment address
					else
						smallAddr <= "000000"; --When max is hit reset back to zero.
						state <= listen; --move to a listening state to await another event.
					end if;
				elsif(canvasSize = '1') then --If sw0 is 1, show the larger canvas size.
					if (bigAddr <= "011011") then --are we at the 27th address?
						bigAddr <= std_logic_vector( unsigned (bigAddr) + 1); --increment address.
					else
						bigAddr <= "000000";
						state <= listen;
					end if;
				end if;
			end if;
	
		when others => null;
		end case;
		
	end if;
end process;

Inst_smallCanvasMessage : smallCanvasMessage
port map(
		clka => iClk,
		addra => smallAddr,
		douta => smallData
		);

Inst_bigCanvasMessage : bigCanvasMessage
port map(
		clka => iClk,
		addra => bigAddr,
		douta => bigData
		);
		
process(iClk, state, canvasSize)
begin
	if rising_edge(iClk) then
		if(state = changeCanvas and canvasSize = '0') then
			oLCDRs <= smallData(4);
			oLCDData <= smallData(3 downto 0);
		elsif(state = changeCanvas and canvasSize = '1') then
			oLCDRs <= bigData(4);
			oLCDData <= bigData(3 downto 0);
		end if;
	end if;
end process;

end Behavioral;
