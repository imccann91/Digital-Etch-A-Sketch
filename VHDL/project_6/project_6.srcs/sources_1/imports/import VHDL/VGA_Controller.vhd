--Written by Ian McCann
--Date Created: 4/5/2015
--Last Modified: 4/10/2015
--VGA_Controller

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Controller is
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
		pixelClkout : out std_logic := '0'; --signal that allows other system components to follow the pixel clock the VGA controller uses.
		HS    : out std_logic := '0'; --The horizontal synchronization signal.
		VS    : out std_logic := '0' --The vertical synchronization signal.	
	);
	
--NOTE: hBlank and vBlank determine the range in which color data will be written to the display. The max range is 639 for
	  --the horizontal and 479 for the vertical. This forms a resolution of 640x480. Any resolution smaller than that can
	  --be made by adjusting those numbers.
	
end VGA_Controller;

architecture behavioral of VGA_Controller is

signal hCountVec : std_logic_vector (9 downto 0) := (others => '0');
signal vCountVec : std_logic_vector (9 downto 0) := (others => '0');

--Pixel clock signals.
signal pixelClkCnt   : integer range 0 to 3 := 0; --Counter that counts to 4, creating a 25MHz enable signal.
signal pixelClkEn	 : std_logic := '0'; --25MHz pixel clock.

--Horizontal synchronization signals.
signal hCounter: integer range 0 to 800 := 0; --Counter that counts to 95 (3.84us with a 25MHz clk.

--Vertical synchronization signals.
signal verticalEn      : std_logic := '0'; --Vertical synchronization enable (really the same as HS).
signal vCounter : integer range 0 to  525 := 0; --Counter that counts to 41799 (the number of clock sycles). 

begin

pixelX <= hCounter;
pixelY <= vCounter;

hCountVec <= std_logic_vector(to_unsigned(hCounter,10));
vCountVec <= std_logic_vector(to_unsigned(vCounter,10));

--Create a clock enabler for the pixel clock. This runs at 25MHz.
process(iClk)
begin
	if rising_edge(iClk) then
		if (pixelClkCnt = 3) then
			pixelClkCnt <= 0;
			pixelClkEn <= '1';
			pixelClkOut <= '1';
		else
			pixelClkCnt <= pixelClkCnt + 1;
			pixelClkEn <= '0';
			pixelClkOut <= '0';
		end if;
	end if;
end process;

--Horizontal counter
process(iClk, pixelClkEn)
begin
	if (rising_edge(iClk) and pixelClkEn = '1') then
		if (hCounter = 799) then
			hCounter <= 0;
		else
			hCounter <= hCounter + 1;
		end if;
	end if;
end process;

--HORIZONTAL SYNCHRONIZATION CONTROL.
process (iClk, pixelClkEn, hCounter)
begin
		if(hCounter >= 0 and hCounter <= 639) then --Display time. 640 clock cycles
			HS <= '0';
		elsif(hCounter > 639 and hCounter <= 655) then --Front porch. 16 cycles. 
			HS <= '0';
		elsif(hCounter > 655 and hCounter <= 751) then --Pulse width. 96 cycles.
			HS <= '1';
		elsif(hCounter > 751 and hCounter <= 799) then --Back porch. 48 cycles.
			HS <= '0';
		end if;
		
		if(hCounter = 699)then --When the horizontal counter reaches this point
			verticalEn <= '1'; --allow the vertical counter to increment.
		else
			verticalEn <= '0';
		end if;
end process;

--Vertical counter that only increments on the rising edge of the 100MHz clock 
--and when the 25MHz clock is high and the horizontal counter has reached the specified point.
process(iClk, verticalEn, pixelClkEn)
begin
	if (rising_edge(iClk) and verticalEn = '1' and pixelClkEn = '1')then
		if (vCounter = 524) then
			vCounter <= 0;
		else
			vCounter <= vCounter + 1;
		end if;
	end if;
end process;

--VERTICAL SYNCHRONIZATION CONTROL.
process (iClk, pixelClkEn, vCounter)
begin
		if(vCounter >= 0 and vCounter <= 479) then --Dsiplay time. 480 cycles.
			VS <= '0';
		elsif(vCounter > 479 and vCounter <= 489) then --Front porch. 10 cycles. 
			VS <= '0';
		elsif(vCounter > 489 and vCounter <= 491) then --Pulse width. 2 cycles.
			VS <= '1';
		elsif(vCounter > 491 and vCounter <= 524) then --Back porch. 33 cycles.
			VS <= '0';
		end if;
end process;


--Only allow color data to be outputted when it can actually be displayed.
--Also known as the blanking period!!!!!!!!!!!!
process (vCounter, hCounter)
begin
	--Controls the vertical and horizontal display regions.
	if(vCounter >= vBlankLower and vCounter <= vBlankUpper and hCounter >= hBlankLower and hCounter <= hBlankUpper) then
		--VGAred <= std_logic_vector(to_unsigned(vCounter,4));
		--VGAgreen <= std_logic_vector(to_unsigned(hCounter,4));
		--VGAblue <= std_logic_vector(to_unsigned(vCounter,4));
		--VGAred <= hCountVec(5 downto 2);
		--VGAgreen <= hCountVec(7 downto 4);
		--VGAblue <= hCountVec (3 downto 0);
		--VGAred <= "1111";
		--VGAgreen <= "1111";
		--VGAblue <= "1111";
			VGAred <= i_VGAred;
			VGAgreen <= i_VGAgreen;
			VGAblue <= i_VGAblue;
	else --otherwise draw nothing, or rather draw black!
		VGAred <= "0000";
		VGAgreen <= "0000";
		VGAblue <= "0000";
	end if;
end process;

end behavioral;