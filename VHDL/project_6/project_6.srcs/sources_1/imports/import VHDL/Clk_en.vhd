----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/28/2015 06:07:40 PM
-- Design Name: 
-- Module Name: Clk_en - Behavioral
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

entity Clk_en is
  Generic (DesiredDisplaySpeed : integer := 10000000;
           InputClockSpeed : integer := 100000000);
            
  Port (BoardClock : in STD_LOGIC;
        OutputClock : out STD_LOGIC);
end Clk_en;

architecture Behavioral of Clk_en is

signal clkMax : integer := InputClockSpeed/DesiredDisplaySpeed;
signal clkCnt : integer := 0;

begin
    DisplaySpeed: process(BoardClock)
    begin
        if rising_edge(BoardClock) then
                if clkCnt = clkMax then
                    OutputClock <= '1';
                    clkCnt <= 0;
                else
                    clkCnt<=clkCnt+1;
                    OutputClock <= '0';
                end if;
        end if;
    end process;
end Behavioral;