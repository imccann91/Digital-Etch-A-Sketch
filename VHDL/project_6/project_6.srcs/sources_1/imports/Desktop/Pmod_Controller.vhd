LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
ENTITY Pmod_Controller IS
  PORT(
    Clock       	 : IN     STD_LOGIC;                   -- system clock
    oSDA     		 : inout STD_LOGIC;		       -- Connects to Board (i2c data bus)
    oSCL      		 : inout STD_LOGIC;		       -- Connects to Board (i2c clock)
    Data_Ready_Pulse	 : out std_logic;	               -- Pulse the new data is ready
    oData		 : out std_logic_vector(15 downto 0);  -- Data Ready from the PMODAD2
    Sample_Done          : out std_logic		       -- Pulse sent when done sampling the defined number of samples
    );
END Pmod_Controller;

ARCHITECTURE behavioral OF Pmod_Controller IS

component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 150_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_master;


TYPE state_type IS(start, init, read, stop, delay);
SIGNAL State  		: state_type := start;

-- Entity only signals.
signal Delay_Count 	: integer := 100000;
signal initdone 	: std_logic := '0';
signal Sample_Count     : integer := 0;
signal count 		: integer := 0;
signal address_out 	: integer := 0;
signal DataOut 		: std_logic_vector(15 downto 0);
signal regBusy 		: std_logic;

-- Signals connected to i2c master
signal reset		: std_logic;
signal enable		: std_logic;
signal readwrite 	: std_logic;
signal writeData        : std_logic_vector(7 downto 0) := "00010000";
signal sigBusy		: std_logic;
signal DataFromADC 	: std_logic_vector(7 downto 0);
signal nackADC 		: std_logic := '0';


BEGIN
oData <= DataOut; 

output: i2c_master
port map (
    clk=>Clock,
    reset_n=>reset,
    ena=>enable,
    addr=>"0101000", -- PMODAD2 Address
    rw=>readwrite,
    data_wr=>writeData,
    busy=>sigBusy,
    data_rd=>DataFromADC,
    ack_error=>nackADC,
    sda=>oSDA,
    scl=>oSCL);


StateChange: process (Clock)
begin
	if rising_edge(Clock) then
		case State is
			when start =>

				reset<='1';
				enable<='1';
				
				if(initDone='0') then
					readwrite<='0';
					State<=init;
				else
					readwrite<='1';
					State<=read;
				end if;
				
				
				
			
			when init =>
			     regBusy<=sigBusy;
			     writeData<="00110000";  -- Configures PMODAD2 (See spec sheet)
			     if regBusy/=sigBusy and sigBusy='0' then
			         enable<='0';
			         state<=delay;
			         initDone<= '1';
			     end if;
		      
			when read =>
		    
				regBusy<=sigBusy;
				if regBusy/=sigBusy and sigBusy='0' then

--		Uncomment these lines and comment out "DataOut <= "01001011" & DataFromADC;"  to send to send data out 16 bits at a time. 	

			        if(count = 1) then
		                count <= 0;
					address_out <= address_out+1;
					Data_Ready_Pulse <= '1';
																	--DataOut <= "01001011" & DataFromADC;
		                        DataOut(7 downto 0) <= DataFromADC;
		                else
		                  count<= count+1;
		                  Data_Ready_Pulse <= '0';
		                  DataOut(15 downto 8) <= DataFromADC;
		                end if;

				--if(Sample_Count = 1024) then  -- Arbitrary value choosen (512 samples per channel @ 2 channels). Can comment this out to continue sampling indefinitely. 
					--Sample_Done <= '1';
					--state <= stop;
		                --else
					--Sample_Done <= '0';
					--Sample_Count <= Sample_Count+1;
					state <= read;
				--end if;
			else
				Data_Ready_Pulse <= '0';
		        end if;
		          
			when stop =>
		          enable<='0';
		          --Do nothing;
		          
			when delay =>
		           enable <= '0';
		           if(delay_count = 0) then
				state <= start;
		           else 
				delay_count <= delay_count -1;
		           end if;
		      
		end case;
	end if;    
end process;    
			         
			         
end behavioral;