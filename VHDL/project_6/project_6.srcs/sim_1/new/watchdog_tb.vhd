----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/15/2015 05:21:51 PM
-- Design Name: 
-- Module Name: watchdog_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;



entity watchdog_tb is
end watchdog_tb;

architecture Behavioral of watchdog_tb is

component connection_watchdog is
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
end component;

signal iClk : std_logic := '0';
signal receivedData : std_logic_vector (7 downto 0) := (others => '0');
signal connLost : std_logic := '0';
signal oLCDEn : std_logic := '0';
signal oLCDRs : std_logic :='0';
signal oLCDData : std_logic_vector (3 downto 0) := (others => '0');

begin
iClk <= not iClk after 5ns;

DUT: connection_watchdog
	generic map (waitTime => 1000)
	port map(
		iClk => iClk,		 
		receivedData => receivedData,
		connLost => connLost,
		oLCDEn => oLCDEn,
		oLCDRs => oLCDRs,
		oLCDData => oLCDData
	);

end Behavioral;
