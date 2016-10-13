----------------------------------------------------------------------------------
--Code by: Zachary Rauen
--Date: 3/6/15
--Last Modified: 3/11/15
--
--Description: This is a minimal UART, however it is fully functional
-- and is active high pulse for the transmission.
--
--Version: 2.1
--Change in 2.1: Fixed output registers
--Change in 2.0: Added receive side of UART
--Change in 1.2: Changed design of transmission
--Change in 1.1: Fixed transmission registering data
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART is
    Generic (TxBaudSpeed : integer :=9600;
			 RxBaudSpeed : integer :=9600;
             Boardspeed : integer :=100000000;
			 StartBit	: std_logic := '0';
			 StopBit	: std_logic := '1');
    Port ( Clock : in STD_LOGIC := '0';
           TransPulse : in std_logic;
           TransData : in STD_LOGIC_VECTOR (7 downto 0);
           Tx : out STD_LOGIC;
		   RecData : out STD_LOGIC_VECTOR (7 downto 0);
           Rx : in STD_LOGIC);
end UART;

architecture Behavioral of UART is

type transStates is (waitState,start,transBits,stop);
type recStates is (asyncWait,LSB,data2,data3,data4,data5,data6,data7,MSB,skip);
signal transState : transStates;
signal recStateNext,recStateCurrent : recStates;
signal TxEnableCnt,RxEnableCnt,TxBitCnt: integer:=0;
signal TxEnableMax : integer := Boardspeed/TxBaudSpeed-1;
signal RxEnableMax : integer := Boardspeed/RxBaudSpeed-1;
signal TxEn : std_logic := '0';
signal rxtest : std_logic := '1';
signal readData,DataToTrans,SingleBuffer : std_logic_vector(7 downto 0) := x"00";

begin

Transmission: process(Clock,transState)
begin
if rising_edge(Clock) and TransPulse ='1' then
    if transState=waitState then
        DataToTrans<=TransData;
    end if;
end if;

if rising_edge(Clock) then
    if TxEnableCnt = TxEnableMax then
		TxEn<='1';
        TxEnableCnt <= 0;
    else
        TxEn<='0';
        TxEnableCnt<=TxEnableCnt+1;
    end if;


case transState is
    when waitState=>
		Tx<='1';
		TxEnableCnt<=0;
        if (TransPulse='1') then
            transState<=start;
        end if;
    when start=>
        Tx<=StartBit;
		if TxEn='1' then
			transState<=transBits;
		end if;
    when transBits=>
        Tx<=DataToTrans(TxBitCnt);
		if TxEn='1' then
			if TxBitCnt=7 then
				TxBitCnt<=0;
				transState<=stop;
			else
				TxBitCnt<=TxBitCnt+1;
			end if;
		end if;
    when stop=>
        Tx<=StopBit;
		if TxEn='1' then
			transState<=waitState;
		end if;
end case;
end if;
end process Transmission;

Receive: process(Clock,recStateCurrent)
begin
if (rising_edge(Clock)) then
    if RxEnableCnt = RxEnableMax then
        recStateCurrent <= recStateNext;
        RxEnableCnt <= 0;
    else
        RxEnableCnt<=RxEnableCnt+1;
    end if;

case recStateCurrent is
        when asyncWait=>
            if (Rx='0') then
                rxtest<=Rx;
                recStateNext<=LSB;
            else
                recStateNext<=asyncWait;
            end if;
        when LSB=>
            readData(0)<=Rx;
            recStateNext<=data2;
        when data2=>
            readData(1)<=Rx;
            recStateNext<=data3;
        when data3=>
            readData(2)<=Rx;
            recStateNext<=data4;
        when data4=>
            readData(3)<=Rx;
            recStateNext<=data5;
        when data5=>
            readData(4)<=Rx;
            recStateNext<=data6;
        when data6=>
            readData(5)<=Rx;
            recStateNext<=data7;
        when data7=>
            readData(6)<=Rx;
            recStateNext<=MSB;
        when MSB=>
            readData(7)<=Rx;
            recStateNext<=skip;
        when skip=>
        if rxtest='0' then
            RecData<=readData;
            rxtest<='1';
        end if;
            recStateNext<=asyncWait;
    end case;
end if;
end process Receive;

end Behavioral;
