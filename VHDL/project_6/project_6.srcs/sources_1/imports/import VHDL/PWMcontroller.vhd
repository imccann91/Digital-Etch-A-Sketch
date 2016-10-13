library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWMcontroller is
	port(
		iClk	: in std_logic := '0'; --100MHz clock.
		iData	: in std_logic_vector (7 downto 0) := (others => '0'); --Data from the ADC.
		oPWM	: out std_logic := '0' --Single bit vector that is switched on and off at a varying rate.
	    );
end PWMcontroller;

--Speed of the FPGA is 100MHz, 100*10^6
--how often we want to refresh the signal is t = 1/(115200/2) = 0.0000174sec or 0.001sec
--So the the period of the PWM is P = t*(100*10^6) = 1737 or 100000    
--Since it's an 8-bit ADC the step-count (sc) is 256.
--Now we must calculate the step-delay (sd) sd = P/sc = 7 or 391
--To calculate the number of bits long the counter should be use log2(P) = 11 bits
--The number of bits can be auto calculated by the synthesis tool.

architecture behavioral of PWMcontroller is

--constant sd : integer := 0; --step delay, just a single number to multiply the data by.
signal regData: std_logic_vector (7 downto 0) := (others => '0'); --Register that stores tyhe input data.
signal counter : integer range 0 to 256 := 0;
signal MHzCounter : integer range 0 to 28 := 0;
signal countEN : std_logic := '0';

begin

--Example PWM code and concept using an FPGA can be found here: http://www.ece301.com/fpga-projects/53-pwm.html
--The duty cycle is calculated by saying that while our counter is less or equal to 
--the multiplication of the step count (switches) and step delay ( our set parameter),
--the output will be HIGH, else it will be ZERO.
    
    --Counter that determines when to grab new data.
    process(iClk, counter)
    begin
        if rising_edge(iClk) then
            if (counter = 255) then
                --regData <= "00" & iData(7 downto 2); --Grab the new data. (shifted right by 2 bits) pinches to 25% duty cycle
				regData <= '0' & iData(7 downto 1); --shift right by 1 bit. Pinches to 50% duty cycle
				--regData <= iData(7 downto 0); --Alsows 100% duty cycle.
			else
                regData <= regData; --Otherwise the data stays the way it is.
            end if;
        end if;
    end process;
    
    --3.5MHz clock enabler.
    process(iClk)
    begin
        if rising_edge(iClk) then
            if (MHzCounter = 28) then
                MHzCounter <= 0;
                countEN <= '1';
            else
                MHzCounter <= MHZCounter + 1;
                countEN <= '0';
            end if;            
        end if;
    end process;
    
    process(iClk, countEN)
    begin
        if rising_edge(iClk) and countEN = '1' then
            if(counter = 255) then
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
	process(iClk, counter)
	begin	  
		  if (counter < unsigned(regData)) then --Type cast the 8-bit vector into an integer.
			oPWM <= '1'; --Output a logical 1.
		  else
			oPWM <= '0'; --Otherwise output a logical 0.
		  end if;
	end process;

end behavioral;