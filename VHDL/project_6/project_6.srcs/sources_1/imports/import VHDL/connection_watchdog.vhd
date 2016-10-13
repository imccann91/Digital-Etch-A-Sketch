--Created by Ian McCann
--Created: 4/15/2015
--Last modified: 4/17/2015
--Allows the hardware controlled by the FPGA to be aware of the status of a connection. If the data received from the UART has
--not changed within 5 seconds they system will change a controlbit to a '1', signifying that the connection is lost. 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity connection_watchdog is
	generic( waitTime : integer := 499999999 --The time waited by the "watchdog".	
		   );
    Port (
		iClk 		 : in std_logic := '0'; --100MHz clock.
		receivedData : in std_logic_vector (7 downto 0) := (others => '0'); --Data received from the UART.
		connLost     : out std_logic := '0'; --Control bit that signals the rest of the system when the connection has been lost.
		oLCDEn		 : out std_logic := '0'; --LCD enable signal.
		oLCDRs       : out std_logic := '0'; --Whether the data to the LCD is an instruction or data. 0=instruction 1=data.
		oLCDData     : out std_logic_vector (3 downto 0) := (others => '0') --4-bit data to the LCD.
		);
end connection_watchdog;

architecture Behavioral of connection_watchdog is

--Containes the message stating that the hardware has lost connection.
component connLostROM is
	port(
		clka : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end component;

--Containes the message stating that the hardware has been reconnected.
component reconnROM is
	port(
		clka : IN STD_LOGIC;
		addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end component;

type statemachine is (watch, alert, listen, reset, waiting); --Three-state statemachine.

signal state : statemachine := watch; --Statemachine signal.

signal regReceivedData : std_logic_vector (7 downto 0) := (others => '0'); --Register that stores the previous data from the receive side
																		   --of the UART.
signal clk_en_200hz : STD_LOGIC := '0';--impulse 200 times a second = 5 milliseconds
signal cnt_200hz    : INTEGER  RANGE 1 to 500001 := 1;--count this many clock cycles then do an impulse
signal clk_en_600hz : STD_LOGIC := '0';--impulse 600 times a second
signal cnt_600hz    : INTEGER  RANGE 1 to 166667 := 1;--count this many clock cycles then do an impulse

signal timeOutMax  : integer := waitTime;
signal cnt_time    : integer range 0 to waitTime; --Counter that counts to whatever time is specified by the timeout.

signal alertAddr : std_logic_vector (5 downto 0) := "000000"; --address determines what data from ROM is to be sent to the LCD display during the "alert" state. 
signal resetAddr : std_logic_vector (5 downto 0) := "000000"; --Counter that determined what adata and when is to be sen to the LCD display during the "reset" state.
signal alertData : std_logic_vector (7 downto 0) := x"00"; --data from the disconnection ROM.
signal resetData : std_logic_vector (7 downto 0) := x"00"; --data from the reconnection ROM.

signal sel : integer range 1 to 3 := 1; --Enable signal selection bit.

signal cnt3Sec : integer range 0 to 299999999 := 0; --Counter that counts 3 seconds before moving back into a watching state. 

begin

--5mS clock enabler that if the statemachine is within the either the "alert" state or the "reset" state the
--counter is free to count, otherwise it will remain at 1.
process(iClk, state)
begin
	if rising_edge(iClk) then
		if(state = alert or state = reset) then
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
		if(state = alert or state = reset) then
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

--process(iClk)
--begin
	--if rising_edge(iClk) then
		--regReceivedData <= receivedData;
	--end if;
--end process;

process(iClk, clk_en_200hz)
begin
	if rising_edge(iClk) then
		
		case state is
		
		when watch =>
--			oWatch <= '1';
			regReceivedData <= receivedData; --Registering the received data from the UART.
			if(regReceivedData = receivedData) then --If the registered data hasn't changed allow a counter to count.
				if (cnt_time = timeOutMax)then
					cnt_time <= 0;
					state <= alert;
					--oWatch <= '0';
					--oAlert <= '1';
					connLost <= '1'; --Lost connection, alert rest of system.
				else
					cnt_time <= cnt_time + 1;
				end if;
			else
				state <= state;
				cnt_time <= 0; --If the data received is changing reset the counter to zero.
			end if;
			
		when alert =>
		
			--Generate addresses for the disconnection message ROM.
			if(clk_en_200hz = '1') then
				IF alertAddr <= "100101" THEN--are we at 37?
					alertAddr <= std_logic_vector( unsigned ( alertAddr) + 1);--increment address
				else
					alertAddr <= "000000"; --When max is hit reset back to zero.
					--oAlert <= '0';
					--oListen <= '1';
					state <= listen; --move to a listening state to await reconnection.
				end if;
			else
					alertAddr <= alertAddr; --Otherwise remain at the current address.
			end if;
			
		when listen =>
			regReceivedData <= receivedData;
			if(receivedData /= regReceivedData) then --If my received dat changes move to the reset state.
				state <= reset;
				--oListen <= '0';
				--oReset <= '1';
			else
				state <= listen;
			end if;
			
		when reset =>
			--Generate addresses for the reconnection message ROM.
			if(clk_en_200hz = '1') then
				IF resetAddr <= "011101" THEN--are we at 29?
					resetAddr <= std_logic_vector( unsigned ( resetAddr) + 1);--increment address
				else
					resetAddr <= "000000"; --When max is hit reset back to zero.
					--oReset <= '0';
					--oWaiting <= '1';
					state <= waiting; --move to the watching state to look for a disconnection.
				end if;
			else
					resetAddr <= resetAddr; --Otherwise remain at the current address.
			end if;
		
		when waiting => --Wait 3 seconds before returning to the watching state.
			if(cnt3Sec = 299999999) then --299999999 actual 10 for sim
				cnt3Sec <= 0;
				connLost <= '0'; --Clear the control bit denoting that the system has lost it's connection.
				--oWaiting <= '0';
				--oWatch <= '1';
				state <= watch;
			else
				cnt3Sec <= cnt3Sec + 1;
			end if;		
		when others => null;
		
		end case;
		
	end if;
end process;

--Clock enabler that controles the LCD's enable signal.
PROCESS(iClk, clk_en_600hz, state)
BEGIN
    	--clock part
    	IF(RISING_EDGE (iClk) and  clk_en_600hz = '1')then
			if(state = alert or state = reset) THEN
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

--Message that alerts user to hardware disconnect.
Inst_connLostROM : connLostROM
	port map(
			clka => iClk,
			addra => alertAddr,
			douta => alertData
			);
--Message that alerts user to hardware reconnection.			
Inst_reconnROM : reconnROM
	port map(
			clka => iClk,
			addra => resetAddr,
			douta => resetData
			);

--multiplexor for what data from what ROM is sent to the LCD.			
process(iClk, state)
begin
	if rising_edge(iClk) then
		if(state = alert)then
			oLCDData <= alertData(3 downto 0);
			oLCDRs <= alertData(4); --RS signal is imbedded in the ROM as the 5th bit.
		elsif(state = reset) then
			oLCDData <= resetData(3 downto 0);
			oLCDRs <= resetData(4);
		--else
			--oLCDData <= "0000";
			--oLCDRs <= '0';
		end if;
	end if;
end process;


end Behavioral;
