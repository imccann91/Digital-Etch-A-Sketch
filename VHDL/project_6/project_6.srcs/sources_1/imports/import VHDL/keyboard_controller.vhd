----------------------------------------------------------------------------------
--Code by: Zachary Rauen
--Date: 3/6/15
--Last Modified: 3/10/15
--
--Description: This reads in the data from a PS/2 protocol, specifically used
-- for a keyboard.
--
--Version: 1.1
--Change in 1.1: Made the pulse very short.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard_controller is
    Port ( Clock : in STD_LOGIC;
           KeyboardClock : in std_logic;
           KeyboardData : in std_logic;
           DataPulse : out std_logic;
		   ScanCode : out STD_LOGIC_VECTOR (7 downto 0));
end keyboard_controller;

architecture Behavioral of keyboard_controller is

signal skipCnt,riseCnt : integer:=0;
signal riseMax : integer := 33;
signal readData,regData : std_logic_vector(7 downto 0) := x"00";
signal recPulse,intClock,beenSent : std_logic :='0';

begin

ScanCode<=regData;
DataPulse<=recPulse;
intClock<=not KeyboardClock;

Receive: process(Clock,intClock)
begin
if rising_edge(Clock) then
	if riseCnt = 9  and beenSent = '0' then
		regData<=readData;
	elsif riseCnt = 10  and beenSent = '0' then
		recPulse<='1';
        beenSent<='1';
	else
		recPulse<='0';
	end if;
end if;

if rising_edge(intClock) then	
	if riseCnt = riseMax then
		riseCnt<=1;
		beenSent<='0';
    else
		riseCnt<=riseCnt+1;	
	end if;

	readData(7)<=KeyboardData;
	readData(6)<=readData(7);
	readData(5)<=readData(6);
	readData(4)<=readData(5);
	readData(3)<=readData(4);
	readData(2)<=readData(3);
	readData(1)<=readData(2);
	readData(0)<=readData(1);


end if;
end process Receive;

end Behavioral;
