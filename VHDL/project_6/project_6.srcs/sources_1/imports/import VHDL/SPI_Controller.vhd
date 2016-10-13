library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Controller is
	generic (
			boardSpeed : integer := 100000000; --THe clock rate of the board in Hz.
			transSpeed : integer := 5000000 --The clock rate at which transmission will occur at.
			);
    Port ( 
		   i_clk : in STD_LOGIC;--The 100MHz clock.
		   MISO : in std_logic := '0'; --Output of the slave device.
									   --Master In Slave Out.
		   accelData : out std_logic_vector (7 downto 0) := x"00";
           SCK : out STD_LOGIC;--The clock that defines how fast data will be transmitted/received.
           MOSI : out STD_LOGIC;--Master out, slave in. This is the line where data is sent to a slave device.
           SS : out STD_LOGIC);--Slave select: this line should be kept low and brought high for the next byte.
end SPI_Controller;

architecture Behavioral of SPI_Controller is
--x"0B" read register.
--x"08" x data register.
type statemachine is (tx, rx);
signal state : statemachine := tx;
signal clkCount	   : integer := 0; --Counter for the clock enabler.
signal clkCountMax : integer := (boardSpeed/transSpeed) - 1; --Counter maximum that determines when the clock enable signal goes high.
signal clkEn 	   : std_logic := '0'; --Clock enable signal.
signal cnt	       : integer range 0 to 4 := 0;--counts the 2 signals we must send ,one to read from a register, one to tell which register.
signal cnt2	       : integer range 0 to 19:= 0;--count which bit of TX9 I am sending right now (8-bits plus 1 dummy bit).
signal TX8	       : STD_LOGIC_VECTOR (7 downto 0) := x"00";--8 bit tranmsission
signal TXbit       : integer range 0 to 17 := 8;--count which bit of TX9 I am sending right now.
signal nextByte    : std_logic := '1';--States when the next bryte should be loaded.
signal readData : std_logic_vector(7 downto 0) := x"00";
signal bitCount   : integer range 0 to 7 := 0; --Count the number of bits that have been received by the accelerometer.

begin

	--Creating a 450KHz clock.
	process (i_clk)
	begin
		if rising_edge(i_clk) then
			if (state = tx) then
				if (clkCount = clkCountMax) then--Should be 221 for actual implementation. --sim value is 20
						clkCount <= 0;
						clkEn <= '1';--Pulse high.
				else
						clkCount <= clkCount + 1;--Increment count if not at cnt_400.
						clkEn <= '0';--Otherwise low.
				end if;
			else
				clkEn <= '0';
				clkCount <= 0;
			end if;
		end if;
	end process;
	
	process(i_clk, clkEn)
	begin
		if rising_edge(i_clk) then
			case state is
				
			when tx =>
				if(clkEn = '1') then
					if(cnt = 1 and cnt2 = 18)then
						state <= rx;
					end if;
				end if;
			when rx =>
				if clkEn = '1' then
					readData(7)<=MISO; --Shift data into an 8-bit shift register.
					readData(6)<=readData(7);
					readData(5)<=readData(6);
					readData(4)<=readData(5);
					readData(3)<=readData(4);
					readData(2)<=readData(3);
					readData(1)<=readData(2);
					readData(0)<=readData(1);
					bitCount <= bitCount + 1; --when all bits have been captured, register the data so it
											--is stable for the rest of the system to work with.
					if(bitCount = 7)then
						accelData <= readData;
						bitCount <= 0;
						state <= tx;
					end if;
				end if;
			end case;		
		end if;
	end process;
	
	--state machine counts 0-16, then 13-16 forever. Selecting which byte.
	process (nextByte)
	begin
	if (nextByte = '1')	then
		case cnt is --for some reason cnt is one ahead
			when  0     => TX8 <= x"0A";    --Write to register command.
			when  1     => TX8 <= x"2D";    --Power control register.
			when  2     => TX8 <= x"02";    --data to start the accelerometer into measurement mode.
			when  3 	=> TX8 <= x"0B";	--Read register command.
			when  4 	=> TX8 <= x"08";	--Read X-axis register.
		end case;
	end if;
	end process;
	
	--Send the bits in the byte.
	--SCK forms an effective clock of 225KHz.
	process(i_clk, clkEn, state)
	begin
		if(rising_edge(i_clk) and clkEn = '1' ) then
			if (state = tx) then
			case cnt2 is
				when 0 => MOSI <= 'Z'; SS <= '1'; SCK <= '0';
				when 1 => MOSI <= TX8(7); SS <= '0'; SCK <= '0';
				when 2 => MOSI <= TX8(7); SS <= '0'; SCK <= '1';
				when 3 => MOSI <= TX8(6); SS <= '0'; SCK <= '0';
				when 4 => MOSI <= TX8(6); SS <= '0'; SCK <= '1';
				when 5 => MOSI <= TX8(5); SS <= '0'; SCK <= '0';
				when 6 => MOSI <= TX8(5); SS <= '0'; SCK <= '1';
				when 7 => MOSI <= TX8(4); SS <= '0'; SCK <= '0';
				when 8 => MOSI <= TX8(4); SS <= '0'; SCK <= '1';
				when 9 => MOSI <= TX8(3); SS <= '0'; SCK <= '0';
				when 10 => MOSI <= TX8(3); SS <= '0'; SCK <= '1';
				when 11 => MOSI <= TX8(2); SS <= '0'; SCK <= '0';
				when 12 => MOSI <= TX8(2); SS <= '0'; SCK <= '1';
				when 13 => MOSI <= TX8(1); SS <= '0'; SCK <= '0';
				when 14 => MOSI <= TX8(1); SS <= '0'; SCK <= '1';
				when 15 => MOSI <= TX8(0); SS <= '0'; SCK <= '0';
				when 16 => MOSI <= TX8(0); SS <= '0'; SCK <= '1';
				when 17 => MOSI <= '1'; SS <= '0'; SCK <= '0';
				when 18 => MOSI <= '1'; SS <= '1'; SCK <= '0';
				when others  => MOSI <= '0'; SS <= '1'; SCK <= '0';
				end case;
			
			if(cnt2 = 18) then--What bit we are sending
				nextByte <= '1';--Give us the next byte.
				cnt2 <= 1;--Reset to case 1.
				
				if(cnt = 4) then--What byte we are on.
					cnt <= 03;
				else
					cnt <= cnt + 1;
				end if;
			else				
				nextByte <= '0';--Othewise stay on this byte
				cnt2 <= cnt2 + 1;--Otherwise increment the SM.
			end if;
			else
				nextByte <= '0';
				cnt2 <= 0;
				cnt <= 3;
			end if;
		end if;
	end process;
	
	--process(MISO,i_clk,clkEn)
	--begin
		--if (rising_edge(i_clk) and clkEn = '1') then
			--if(MISO /= 'Z') then --If the MISO line isn't in high impedence.
				--readData(7)<=MISO; --Shift data into an 8-bit shift register.
				--readData(6)<=readData(7);
				--readData(5)<=readData(6);
				--readData(4)<=readData(5);
				--readData(3)<=readData(4);
				--readData(2)<=readData(3);
				--readData(1)<=readData(2);
				--readData(0)<=readData(1);
				--bitCount <= bitCount + 1; --when all bits have been captured, register the data so it
										  --is stable for the rest of the system to work with.
				--if(bitCount = 7)then
					--accelData <= readData;
					--bitCount <= 0;
				--end if;
			--end if;
		--end if;
	--end process;
	
end Behavioral;
