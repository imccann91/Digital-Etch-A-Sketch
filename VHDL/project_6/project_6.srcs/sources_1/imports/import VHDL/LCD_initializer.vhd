library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LCD_initializer is
    Port ( i_clk : in STD_LOGIC;-- 100 Mhz xilinx oscilator clock
           rData : in STD_LOGIC_VECTOR ( 7 downto 0);--read from ROM
           rAddr : out STD_LOGIC_VECTOR ( 7 downto 0); --address sent to ROM
           initDone : out STD_LOGIC;
           oRs : out STD_LOGIC; -- 0=instruction, 1=data
           oEn : out STD_LOGIC; -- LCD enable, active high
           oData : out STD_LOGIC_VECTOR (3 downto 0));--Data transfer is performed twice 
                                                     --thru DB4-DB7 in 4-bit mode. 
                                                     --Upper nibble first then 
                                                     --lower nibble.
end LCD_initializer;

architecture Behavioral of LCD_initializer is

--signals go here
signal clk_en_200hz : STD_LOGIC := '0';--impulse 200 times a second = 5 milliseconds
signal cnt_200hz    : INTEGER  RANGE 1 to 500001 := 1;--count this many clock cycles then do an impulse
signal clk_en_600hz : STD_LOGIC := '0';--impulse 600 times a second
signal cnt_600hz    : INTEGER  RANGE 1 to 166667 := 1;--count this many clock cycles then do an impulse
signal waited20ms   : STD_LOGIC := '0';--wait 20 ms after vcc rises to 4.5V and then go high
signal waited20cnt  : INTEGER RANGE 0 to 4 := 0;--wait for four 200 hz (5 millisecond) impulses
signal initAddr     : STD_LOGIC_VECTOR (5 downto 0) := "000000";--address of ROM to initialize LCD
signal sel          : INTEGER RANGE 1 TO 3 :=1;--selection bits for mux_oEn
signal init         : std_logic :='0';
begin
initDone<=init;
  --processes go here
    clk_enabler_600:PROCESS(i_clk)--The clk enabler for 600hz
      BEGIN
      --clock part
      IF RISING_EDGE (i_clk) THEN
        IF (cnt_600hz = 166667) THEN -- 5 in sim, otherwise 166667 for approx 600hz... The integer division is impossible so this is a compromise
            clk_en_600hz <= '1';--pulse high
            cnt_600hz <= 1;--reset the count
        ELSE
            clk_en_600hz <= '0';--stay low
            cnt_600hz <= cnt_600hz + 1;--increment count
        END IF;
      END IF;
    END PROCESS clk_enabler_600;
    
    --5ms (200 hz) clock_en pulse based on 100MHz clock on board (this is for the oEn)
    --counts 1 thru 500,000
    clk_enabler_200:PROCESS(i_clk)--The old clk enabler for 200hz
      BEGIN
      --clock part
      IF RISING_EDGE (i_clk) THEN
    	IF cnt_200hz = 500001 THEN -- 15 in sim, otherwise 500001 for approx 5 ms = 200hz... Should be 500000 - 1 = 499999 
    						   -- but dividing that into 3 is impossible so this was the compromise
    		clk_en_200hz <= '1';
    		cnt_200hz <= 1;
    	ELSE
    		clk_en_200hz <= '0';
    		cnt_200hz <= cnt_200hz + 1;
    	END IF;
      END IF;
    END PROCESS clk_enabler_200;

    
--20 ms delay after power up
    wait20msAtStart:PROCESS(i_clk, clk_en_200hz)
        begin
        IF RISING_EDGE (i_clk) and (clk_en_200hz = '1') THEN
            IF waited20cnt = 4 THEN
                waited20ms <= '1';
            ELSE
                waited20cnt <= waited20cnt + 1;
            END IF;
        END IF;
    END PROCESS wait20msAtStart;
--00 thru 13 address generator and nevermore
    addressGenerator:PROCESS(i_clk, clk_en_200hz, waited20ms)
    begin
    IF RISING_EDGE (i_clk) and (clk_en_200hz = '1') and (waited20ms ='1') then
        IF initAddr <= "101011" THEN--are we at thirteen  "001101"?
            initAddr <= std_logic_vector( unsigned ( initAddr) + 1);--increment address
            --oRS <= '0';--always instructions according to zack.
       -- elsif(initAddr <= "101011")then--have we reached the last address yet? (43rd address)
			--oRs <= '1';
			--initAddr <= std_logic_vector( unsigned ( initAddr) + 1);--increment address
		else
            init <= '1';--initialize is finished, all future addresses are instructions and characters are from other components.
        END IF;
    END IF;
    end process addressGenerator;
    
      mux_oEn:PROCESS(i_clk, clk_en_600hz)
      BEGIN
    	--clock part
    	IF RISING_EDGE (i_clk) and (clk_en_600hz = '1') THEN
    		IF (sel = 3) THEN
    			sel <= 1;
    		ELSE
    			sel <= sel + 1;
    		END IF;
    	END IF;
    	--combinational part
    	CASE sel IS
    		WHEN 1=> oEn <= '0';
    		WHEN 2=> oEn <= '1';
    		WHEN 3=> oEn <= '0';
    		WHEN OTHERS => oEn <= '0';
    	END CASE;
    END PROCESS mux_oEn;
    oRs <= rData(4); --fifth bit contains RS
    rAddr <= "00" & initAddr;
    oData <= rData (3 downto 0);

end Behavioral;
