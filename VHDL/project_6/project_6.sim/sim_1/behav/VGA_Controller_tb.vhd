----------------------------------------------------------------------------------
--Written by Ian McCann
--Date Created: 4/5/2015
--Last Modified: 4/5/2015
--VGA controller testbench.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Controller_tb is
end VGA_Controller_tb;

architecture Behavioral of VGA_Controller_tb is

component VGA_Controller is
	port(
		iClk  : in std_logic := '0'; --The 100MHz clock.
		hBlankUpper : in integer := 0; --The valid time where you will display information on the horizontal axis (upper value).
		vBlankUpper : in integer := 0; --The valid time where you will display information on the vertical axis (upper value).
		hBlankLower : in integer := 0; --The valid time where you will display information on the horizontal axis (lower value).
		vBlankLower : in integer := 0; --The valid time where you will display information on the vertical axis (lower value).
		i_VGAred : in std_logic_vector (3 downto 0) := (others => '0'); --Input red color data.
		i_VGAblue : in std_logic_vector (3 downto 0) := (others => '0'); --Input blue color data.
		i_VGAgreen : in std_logic_vector (3 downto 0) := (others => '0'); --Input green color data.
		pixelX  : out integer := 0; --x coordinate of a pixel.
		pixelY : out integer := 0; --y coordinate of a pixel.
		VGAred : out std_logic_vector (3 downto 0);
		VGAblue : out std_logic_vector (3 downto 0);
		VGAgreen : out std_logic_vector (3 downto 0);
		HS    : out std_logic := '0'; --The horizontal synchronization signal.
		VS    : out std_logic := '0' --The vertical synchronization signal.	
	);
end component;

signal iClk : std_logic := '0';
signal hBlankLower : integer := 0; --The valid time where you will display information on the horizontal axis. (Lower bound)
signal hBlankUpper : integer := 639;--The valid time where you will display information on the horizontal axis. (Upper bound)
signal vBlankLower : integer := 0; --The valid time where you will display information on the vertical axis. (Lower bound)
signal hBlankUpper : integer := 479; --The valid time where you will display information on the vertical axis. (Upper bound)
signal pixelX : integer := 0; --x coordinate of a pixel.
signal pixelY : integer := 0; --y coordinate of a pixel.
signal VGAred : std_logic_vector (3 downto 0);
signal VGAblue : std_logic_vector (3 downto 0);
signal VGAgreen : std_logic_vector (3 downto 0);
signal HS : std_logic := '0';
signal VS : std_logic := '0';


begin

iClk <= not iClk after 5ns; --100MHz clock.

DUT: VGA_Controller
	port map (
		iClk <= iClk,
		hBlankUpper => hBlankUpper,
		vBlankUpper => vBlankUpper,
		hBlankLower => hBlankLower,
		vBlankLower => vBlankLower,
		i_VGAred => x"0",
		i_VGAblue => x"0",
		i_VGAgreen => x"0",
		pixelX => pixelX,
		pixelY => pixelY,
		VGAred => VGAred,
		VGAblue => VGAblue,
		VGAgreen => VGAgreen,
		HS => HS,
		VS => VS
		);
	
process
begin

	--The default 256x256 canvas.
	hBlankLower <= 191;
	hBlankUpper <= 447; --256x256
	vBlankLower <= 111;
	vBlankUpper <= 367; 
	wait for 17ms;
	
	--Change to the doubled canvas size
	hBlankLower <= 138;
	hBlankUpper <= 500; --362x362
	vBlankLower <= 58;
	vBlankUpper <= 420;	
	wait for 17ms;
	
end process;

end Behavioral;
