----------------------------------------------------------------------------------
--Written by Ian McCann and Joseph Koone
--Date Created: 4/5/2015
--Last Modified: 4/22/2015
--Top level entity for project 6: Electronic Etch-a-Sketch.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port (
		Clock       : in std_logic := '0'; --100MHz clock.
		sw0         : in std_logic := '0'; --Switch 0, controls display mode (256x256 or 362x362).
		sw1         : in std_logic := '0'; --Switch that overrides the smaller resolutions to the full 640 by 480.
		--sw15        : in std_logic := '0'; --Switch that controls whether or not the the canvas is cleared.
		PS2Clk      : in std_logic; --The PS/2 clock from the keyboard.
		PS2Data     : in std_logic; --The PS/2 data from the keyboard.
		--JC0	       : in std_logic := '0'; --Receive (Rx).
		--JC1        : out Std_logic := '0'; --Transmit (Tx).
		JC2	       : inout std_logic := '0'; --SCL for PMOD ADC.
		JC3        : inout std_logic := '0'; --SDA for PMOD ADC.
		RamCLK     : out std_logic := '0'; -- The clock for the RAM.
		RamADVn    : out std_logic := '0';
		RamCEn     : out std_logic := '0';
		RamCRE     : out std_logic := '0';
		RamOEn     : out std_logic := '0';
		RamWEn     : out std_logic := '0';
		RamLBn     : out std_logic := '0';
		RamUBn     : out std_logic := '0';
		RamWait    : in std_logic := '0';
		MemAdr     : out std_logic_vector (22 downto 0) := (others => '0');
		MemDB      : inout std_logic_vector (15 downto 0) := (others => '0');
		vgaRed     : out std_logic_vector(3 downto 0) := (others => '0'); --Red color data.
		vgaGreen   : out std_logic_vector(3 downto 0) := (others => '0'); --Green color data.
		vgaBlue    : out std_logic_vector(3 downto 0) := (others => '0'); --Blue color data.
		Hsync	   : out std_logic := '0'; --Horizontal synchronization control signal.
		Vsync	   : out std_logic := '0';	--Vertical synchronization control signal.
		LCDData    : out std_logic_vector (3 downto 0) := (others => '0'); --4-bit data to the LCD.
		LCDEn      : out std_logic := '0'; --LCD enable signal.
		LCDMode    : out std_logic := '0'; --LCD mode select.
		LED0	   : out std_logic := '0'; --Lets the user know that the connection has been lost.
		RsRx	   : in std_logic := '0';
		RsTx       : out std_logic := '0';
		RGB1_Red   : out std_logic := '0';
		RGB1_Green : out std_logic := '0';
		RGB1_Blue  : out std_logic := '0';
		--aclMISO    : in std_logic;
		--aclMOSI    : out std_logic;
		--aclSCK     : out std_logic;
		--aclSS      : out std_logic;
		--JA		   : out std_logic_vector (7 downto 0);
		btnC       : in std_logic := '0'
		--
		--x_Register : out std_logic_vector(2 downto 0);
		--y_Register : out std_logic_vector(2 downto 0);
		--DataReady_Pmod : out std_logic
	);
end top_level;

architecture Behavioral of top_level is

--The VGA Controller.
component VGA_Controller is
	port(
		iClk : in std_logic := '0'; --The 100MHz clock.
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
		HS   : out std_logic := '0'; --The horizontal synchronization signal.
		VS   : out std_logic := '0' --The vertical synchronization signal.	
	);
end component;

--UART
component UART is
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
end component;

--Character ROM
component CGROM IS
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

--Keyboard ROM.
component KeyboardROM IS
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

--LCD initialization ROM.
component LCDinitROM is
PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

--Keyboard Controller.
component keyboard_controller is
	Port ( Clock : in STD_LOGIC;
           KeyboardClock : in std_logic;
           KeyboardData : in std_logic;
           DataPulse : out std_logic;
		   ScanCode : out STD_LOGIC_VECTOR (7 downto 0)
		  );
end component;

--LCD display Controller.
component LCD_initializer is
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
end component;

--Component responsible for knowing the state of the connection for the hardware.
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

component Pmod_Controller IS
  PORT(
    Clock       	 : IN     STD_LOGIC;                   -- system clock
    oSDA     		 : inout STD_LOGIC;		       -- Connects to Board (i2c data bus)
    oSCL      		 : inout STD_LOGIC;		       -- Connects to Board (i2c clock)
    Data_Ready_Pulse	 : out std_logic;	               -- Pulse the new data is ready
    oData		 : out std_logic_vector(15 downto 0);  -- Data Ready from the PMODAD2
    Sample_Done          : out std_logic		       -- Pulse sent when done sampling the defined number of samples
    );
end component;

--RAM used for holding data between reads and writes.
component PSRAM_Buffer is
	PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component;


--PSRAM Controller.
component PSRAM is
    Port (
              -----------------------------------------------
              --        Signals for the controller         --
              -----------------------------------------------
              clock             :   in      STD_LOGIC;                              -- 100MHz
              address_in        :   in      STD_LOGIC_VECTOR (22 downto 0); -- RAM address
              go_in             :   in      STD_LOGIC;                              -- if='1' starts the operation
              write_in          :   in      STD_LOGIC;                              -- if='0' => read; if='1' => write
              data_in           :   in      STD_LOGIC_VECTOR (15 downto 0); -- data that has to be written
              data_out          :   out     STD_LOGIC_VECTOR (15 downto 0); -- data that has been read
              read_done_signal  :   out     STD_LOGIC;
              -----------------------------------------------
              -- Signals from the controller to the memory --
              -----------------------------------------------
              clock_out         :   out     STD_LOGIC;
              ADDRESS           :   out     STD_LOGIC_VECTOR (22 downto 0);
              ADV               :   out     STD_LOGIC;
              CRE               :   out     STD_LOGIC;
              CE                :   out     STD_LOGIC;
              OE                :   out     STD_LOGIC;
              WE                :   out     STD_LOGIC;
              LB                :   out     STD_LOGIC;
              UB                :   out     STD_LOGIC;
              Wait_in           :   in      STD_LOGIC; 
              Write_Length      :   in      STD_LOGIC_VECTOR(17 downto 0);
              reading_data      :   out     STD_LOGIC_VECTOR(0 downto 0);
              line_address      :   out     std_logic_vector(8 downto 0);
              DATA              :   inout   STD_LOGIC_VECTOR (15 downto 0)
             );
end component;

--Buffer to hold the different x,y and color combinations from the user before writing them into PSRAM.
component Write_Buffer IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END component;

component UART_Controller is
	port(
			iClk : in std_logic := '0'; --100MHz clock.
			connLost :in std_logic := '0';
			keyboardPulse : in std_logic := '0'; --pulse from the keyboard stating that it has captured the scancode.
			xCoorData : in std_logic_vector (7 downto 0) := (others => '0'); --x corrdinate data.
			yCoorData : in std_logic_vector (7 downto 0) := (others => '0'); --y coordinate data.
			KeyboardASCII : in std_logic_vector (7 downto 0) := (others => '0'); --ASCII code from the keyboard ROM.
			color : in std_logic_vector (15 downto 0);
			startTrans : out std_logic := '0'; --Start transmitting data to the UART.
			dataToUART : out std_logic_vector (7 downto 0) --Data sent to the UART.
			);
end component;

component color_change is
    Port (
		iClk : in std_logic := '0';
		ASCIIData : in std_logic_vector (7 downto 0) := x"00";
		keyboardPulse: in std_logic := '0';
		redPWMData: out std_logic_vector (7 downto 0) := x"00";
		greenPWMData: out std_logic_vector (7 downto 0) := x"00";
		bluePWMData: out std_logic_vector (7 downto 0) := x"00";
		color : out std_logic_vector (15 downto 0)
	);
end component;

--PWM controller
component PWMcontroller is
	port(
		iClk	: in std_logic := '0'; --100MHz clock.
		iData	: in std_logic_vector (7 downto 0) := (others => '0'); --Data from the ADC.
		oPWM	: out std_logic := '0' --Single bit vector that is switched on and off at a varying rate.
	    );
end component;

--Width changing component.
component width_change is
    Port ( iClk : in std_logic := '0';
		ASCIIData : in std_logic_vector (7 downto 0) := x"00";
		keyboardPulse: in std_logic := '0';
		cursorSize : out std_logic_vector (2 downto 0) := "000"
		);
end component;

--SPI Controller
--component SPI_Controller is
	--generic (
		--	boardSpeed : integer := 100000000; --THe clock rate of the board in Hz.
			--transSpeed : integer := 5000000 --The clock rate at which transmission will occur at.
		--	);
   -- Port ( 
	--	   i_clk : in STD_LOGIC;--The 100MHz clock.
		--   MISO : in std_logic := '0'; --Output of the slave device.
									   --Master In Slave Out.
		--   accelData : out std_logic_vector (7 downto 0) := x"00";
         --  SCK : out STD_LOGIC;--The clock that defines how fast data will be transmitted/received.
          -- MOSI : out STD_LOGIC;--Master out, slave in. This is the line where data is sent to a slave device.
          -- SS : out STD_LOGIC);--Slave select: this line should be kept low and brought high for the next byte.
--end component;

--VGA control signals/outputs/inputs.
signal hBlankUpper : integer range 0 to 639 := 255; --Signal that switches between 256 pixels on the horizontal to 362.
signal vBlankUpper : integer range 0 to 479 := 255; --Signal that switches between 256 pixels on the vertical to 362.
signal hBlankLower : integer range 0 to 639:= 0; --Signal that defines the lower bound horizontally of which
												 --no data can be shown.
signal vBlankLower : integer range 0 to 479 := 0; --Signal that defines the lower bound vertically of which
												  --no data can be shown.			  
signal pixelX : integer range 0 to 649 := 0; --The x coordinate the horizontal counter is currently on.
signal pixelY : integer range 0 to 479 := 0; --The y coordinate the vertical counter is currently on.
signal pixelClock : std_logic := '0'; --Pixel clock signal.

--UART control signals/inputs/outputs.
signal charData : std_logic_vector (7 downto 0); --Data that is used to draw a particular character.
signal transData : std_logic_vector (7 downto 0); --Data to be sent to the computer (PC).
signal startTrans : std_logic := '0'; --Tells the UART to start a transmission.
signal recData : std_logic_vector (7 downto 0); --Data received from the computer.
--signal transData Register : std_logic_vector (7 downto 0) := x"00";

--LCD and keyboard control signals.
signal initialized : std_logic := '0'; --Whether or not initialization has taken place.
signal initRS      : std_logic := '0'; --Initial mode select to the LCD.
signal initEn	   : std_logic := '0'; --Initial enable to the LCD.
signal initData    : std_logic_vector (3 downto 0) := x"0"; --Initial data to the LCD.
signal tfrData,DataFromROM,addrToROM,initAddr,initDataFromROM,keyboardDataFromROM : std_logic_vector (7 downto 0) := x"00";
signal keyboardPulse : std_logic := '0'; --Pulse that determines when the scan code of the keyboard has been captured.

--Watchdog signals.
signal connLost : std_logic := '0'; --signal that lets the sytem know when connection to the software has been lost.
signal watchEn : std_logic := '0';
signal watchData : std_logic_vector (3 downto 0) := (others => '0');
signal watchRs : std_logic := '0';
signal strobeCnt : integer range 0 to 9999999; --Counter turns an LED on every 100ms, letting you know that the connection is lost.
signal strobeEn : std_logic := '0';
signal strobeState : integer range 0 to 1 := 0; --used for a look-up table.

--PMOD signals.
signal dataReady : std_logic := '0'; --Signal used to etermine if data is ready to grab from the PMOD ADC.
signal regADCData : std_logic_vector (15 downto 0) := (others => '0'); --Register to hold the valid data.
signal ADCData : std_logic_vector (15 downto 0) := (others => '0'); --Signal to transfer the output of the PMOD controller to the register.
signal xRegister : std_logic_vector (8 downto 0) := (others => '0'); --Holds the x-coordinate data.
signal yRegister : std_logic_vector (8 downto 0) := (others => '0'); --Holds the y-coordinate data.
signal xReady : std_logic := '0'; --x-coordinate data is ready.
signal yReady : std_logic := '0'; --y-coordinate data is ready.
signal coorData : std_logic_vector (33 downto 0) := (others => '0'); --Stores the completed x,y data.

signal yregister_int : integer := 0; --Integer conversions of the data received from the PMOD ADC
signal xregister_int : integer := 0;

--PSRAM and read/write RAM signals.
signal addr_to_PSRAM : std_logic_vector (22 downto 0) := (others => '0'); --The address in memory where we're writting into / reading from.
signal PSRAM_pulse : std_logic := '0'; --Tells the us when to write or read.
signal PSRAM_RW : std_logic := '1'; --Controls whether a read or write operation is to be done.
signal write_data : std_logic_vector (15 downto 0) := (others => '0'); --Data to be written to the PSRAM.
signal read_data : std_logic_vector (15 downto 0) := (others => '0'); --Data read from the PSRAM.
signal reading : std_logic := '0'; --Signal that tells us when the PSRAM is still reading.
signal PSRAM_out_clk : std_logic := '0'; --Output clock signal created from the PSRAM.
signal PSRAM_write_length : std_logic_vector (17 downto 0) := (others => '0'); --Number of addresses to be written to.
signal RAM_read_En : std_logic_vector (0 downto 0) := "0"; --Enable signal to the RAM buffer from the PSRAM.
signal line_address : std_logic_vector (8 downto 0) := (others => '0'); --Which line in the PSRAM that is being written to.
signal PSRAM_init : std_logic := '0'; --Control bit that tells us when PSRAM initialization is done.
signal clk_50_en : std_logic := '0'; --50MHz enable signal.
signal clk_50_cnt : integer range 0 to 1 := 0; --50MHz counter.
signal prevYpos : integer range 0 to 800 := 0;
signal init_counter : integer := 0;
signal init_done : std_logic := '0';
signal addr_counter : integer := 0;

signal readBufferAddr : std_logic_vector (8 downto 0) := (others => '0'); --read address for the RAM.
signal readBufferData : std_logic_vector (15 downto 0) := (others => '0'); --Data from the RAM buffer.

signal color : std_logic_vector (15 downto 0) := x"0000"; --What color that is to be drawn into SRAM.

--PWM data signals.
signal PWMRed : std_logic_vector (7 downto 0) := x"00";
signal PWMGreen : std_logic_vector (7 downto 0) := x"00";
signal PWMBlue : std_logic_vector (7 downto 0) := x"00";

signal cursorSize : std_logic_vector (2 downto 0) := "001"; --default cursor size is 1 pixel in size.

--signal xAxisData : std_logic_vector (7 downto 0) := x"00";
signal keyPulse : std_logic := '0';
signal keyData : std_logic_vector (7 downto 0) := x"00";

begin

--Simple process that switches between "different" resolutions.
process(Clock,sw0)
begin
	if rising_edge(Clock) then
		if (sw1 = '1') then
			if(sw0 = '1') then --Flip between the smaller resolutions.
				hBlankLower <= 0;--191;
				hBlankUpper <= 256;--447; --256x256
				vBlankLower <= 0;--111;
				vBlankUpper <= 256;--367; 
			else
				hBlankLower <= 0;--138;
				hBlankUpper <= 362; --362x362
				vBlankLower <= 0;
				vBlankUpper <= 362;	
			end if;
		
		else --Otherwise show full size.
				hBlankUpper <= 450;
				vBlankUpper <= 450;
				hBlankLower <= 0;
				vBlankLower <= 0;
		end if;
	end if;
end process;


--THE VGA CONTROLLER.
Inst_VGA_Controller : VGA_Controller
	port map(
			iClk => Clock,
			hBlankUpper => hBlankUpper,
			vBlankUpper => vBlankUpper,
			hBlankLower => hBlankLower,
			vBlankLower => vBlankLower,
			i_VGAred => readBufferData(11 downto 8),
			i_VGAblue => readBufferData (3 downto 0),
			i_VGAgreen => readBufferData(7 downto 4),
			pixelX  => pixelX,
			pixelY  => pixelY,
			VGAred => vgaRed,
			VGAblue => vgaBlue,
			VGAgreen => vgaGreen,
			pixelClkOut => pixelClock,
			HS => Hsync,
			VS => Vsync	
			);

--The PMOD ADC controller
Inst_PMOD_Controller : PMOD_Controller
PORT map(
    Clock => Clock,
    oSDA => JC3,	       -- Connects to Board (i2c data bus)
    oSCL => JC2,		       -- Connects to Board (i2c clock)
    Data_Ready_Pulse => dataReady,  -- Pulse the new data is ready
    oData => ADCData,  -- Data Ready from the PMODA2D
    Sample_Done => open		       -- Pulse sent when done sampling the defined number of samples
    );
	
process (Clock, dataReady)
begin
	if(rising_edge(Clock) and dataReady = '1') then --If data is ready to grab, grab it!
			regADCData <= ADCData;
	end if;
end process;
--DataReady_Pmod <= dataReady;

--THE CHARACTER ROM.			
Inst_CGROM : CGROM
	port map(
		clka => Clock,
		addra => '0' & x"00",
		douta => charData
		);
		
		
--THE UART.
Inst_UART : UART
    Generic  map(TxBaudSpeed => 9600,
				 RxBaudSpeed => 9600,
				 Boardspeed  => 100000000,
				 StartBit    => '0',
				 StopBit     => '1')
    Port map( Clock => Clock,
			  TransPulse => startTrans, --Figure out what data we're sending to the computer and when. 
              TransData => transData,
			  Tx => RsTx,
              --Tx => JC1,
		      RecData => recData,
              --Rx => JC0
			  Rx => RsRx
			);
			
INST_UART_Controller : UART_Controller
	port map(
			iClk => Clock,
			connLost => connLost,
			keyboardPulse => keyPulse, --pulse from the keyboard stating that it has captured the scancode.
			xCoorData => coorData(33 downto 26),
			yCoorData => coorData(24 downto 17), --y coordinate data.
			KeyboardASCII => keyData, --ASCII code from the keyboard ROM.
			color => color,
			startTrans => startTrans, --Start transmitting data to the UART.
			dataToUART => transData --Data sent to the UART.
			);
			
--Process that allows a user to signal the software to save the drawing as an image.
process(Clock, btnC)
begin
	if rising_edge(Clock) then
		if(btnC = '1') then
			keyPulse <= '1';
			keyData <= x"50";
		else
			keyPulse <= keyboardPulse;
			keyData <= keyboardDataFromROM;
		end if;
	end if;
end process;
			
--LCD display initializer.			
Inst_LCD_initializer : LCD_initializer 
    Port map( i_clk => Clock,-- 100 Mhz xilinx oscilator clock
           rData => initDataFromROM,--read from ROM
           rAddr => initAddr, --address sent to ROM
           initDone => initialized,
           oRs => initRS, -- 0=instruction, 1=data
           oEn => initEn, -- LCD enable, active high
           oData => initData);--Data transfer is performed twice 
                                                     --thru DB4-DB7 in 4-bit mode. 
                                                     --Upper nibble first then 
                                                     --lower nibble.



--The keyboard scan code to ASCII conversion ROM. This ROM also containes the data for the LCD's initialization.
Inst_keyboardROM : keyboardROM
	port map (
		clka => Clock,
		addra => tfrData,
		douta => keyboardDataFromROM	
	);

--The initialization ROM for the LCD.
Inst_LCDinitROM : LCDinitROM
	port map (
		clka => Clock,
		addra => initAddr,
		douta => initDataFromRom
	);
	
--The keyboard controller.	
Inst_keyboard_controller : keyboard_controller
	port map(
		   Clock => Clock,
           KeyboardClock => PS2Clk,
           KeyboardData => PS2Data,
           DataPulse => KeyboardPulse,
		   ScanCode => tfrData
	);
	
Inst_connection_watchdog : connection_watchdog
	generic map( waitTime => 699999999 --The time waited by the "watchdog".
			)
    Port map(
			iClk => Clock,
			receivedData => recData,
			connLost => connLost,
			oLCDEn => watchEn,
			oLCDRs => watchRs,
			oLCDData => watchData
		);
		
--Process that strobes an LED when the connection to the PC has been lost.
process(Clock, connLost)
begin
	if rising_edge(Clock) then
		if(connLost = '1') then
			if(strobeCnt = 9999999) then
				strobeCnt <= 0;
				strobeEn <= '1';
			else
				strobeCnt <= strobeCnt + 1;
				strobeEn <= '0';
			end if;
		else
			strobeEn <= '0';
			strobeCnt <= 0;
			strobeState <= 1;
		end if;
		
		if(strobeEn = '1') then --Changes the state of the LED.
			if(strobeState = 1) then
				strobeState <= 0;
			else
				strobeState <= strobeState + 1;
			end if;
		end if;
	end if;
	
	--pure combinational logic.
	case strobeState is
		when 0 => LED0 <= '0';
		when 1 => LED0 <= '1';
		when others => LED0 <= '0';
	end case;	
end process;

--Process that controls when data to the LCD is from either the UART, initialization ROM, or from the watchdog.
process (initialized, connLost)
begin
	if(initialized = '1' and connLost = '0') then
		LCDMode <= recData(5);
		LCDEn <= recData(4);
		LCDData <= recData(3 downto 0);
	--elsif(initialized = '1' and connLost = '0' and recData(7) = '1')then
		
	elsif(initialized = '1' and connLost = '1') then
		LCDMode <= watchRs;
		LCDEn <= watchEn;
		LCDData <= watchData;
	else
		LCDMode <= initRS;
		LCDEn <= initEn;
		LCDData <= initData;
	end if;
end process;

--Controls how a color is changed.
Inst_color_change : color_change
	port map(	
		iClk => Clock,
		ASCIIData => KeyboardDataFromROM,
		keyboardPulse => keyboardPulse,
		redPWMData => PWMRed,
		greenPWMData => PWMGreen,
		bluePWMData => PWMBlue,
		color => color
	);

--COLOR PWM CONTROLLERS
RED_PWM : PWMController
	port map(
		iClk => Clock, --100MHz clock.
		iData => PWMRed, --8-bit data from the color change controller.
		oPWM => RGB1_Red --Single bit vector that is switched on and off at a varying rate.
	    );

GREEN_PWM : PWMController
	port map(
		iClk => Clock, --100MHz clock.
		iData => PWMGreen, --8-bit data from the color change controller.
		oPWM => RGB1_green --Single bit vector that is switched on and off at a varying rate.
	    );

BLUE_PWM : PWMController
	port map(
		iClk => Clock, --100MHz clock.
		iData => PWMBlue, --8-bit data from the color change controller.
		oPWM => RGB1_Blue --Single bit vector that is switched on and off at a varying rate.
	    );

--Width changing statemachine.
Inst_width_change : width_change
    Port map( 
		iClk => Clock,
		ASCIIData => KeyboardDataFromROM,
		keyboardPulse => keyboardPulse,
		cursorSize => cursorSize
		);

--RAM buffer for PSRAM read/write.
Inst_PSRAM_Buffer : PSRAM_Buffer
	port map(
		clka => PSRAM_out_clk,
		wea  => RAM_read_En,
		addra => line_address,
		dina => read_data,
		clkb => pixelClock,
		addrb => std_logic_vector(to_unsigned(pixelX,9)),--readBufferAddr,
		doutb => readBufferData
	);

--50MHz clock enabler.
process(Clock)
begin
	if rising_edge(Clock) then
		if(clk_50_cnt = 1) then
			clk_50_en <= '1';
			clk_50_cnt <= 0;
		else
			clk_50_en <= '0';
			clk_50_cnt <= clk_50_cnt + 1;
		end if;
	end if;
end process;

--Process to Control registering of the x and y coordinate data.
process(Clock)
begin
	if rising_edge(Clock) then
		if (regADCData(15 downto 12) = "0001" and xReady = '0') then
			xRegister <= regADCData(11 downto 3);
			xReady <= '1';
		elsif (regADCData(15 downto 12) = "0000" and yReady = '0') then
				yRegister <= regADCData(11 downto 3);
				yReady <= '1';
		elsif(yReady = '1' and xReady = '1') then
				coorData <= xRegister & yRegister & color; --Place the complete x,y coordinate set and color into a single register.
				xregister_int <= to_integer(unsigned(xRegister));
				yregister_int <= to_integer(unsigned(yRegister));
				xReady <= '0'; --Reset the ready control bits.
				yReady <= '0';
		end if;
	end if;
end process;

process(clk_50_en)
begin
    if rising_edge(clk_50_en) then
        
        if(init_done = '0') then
             psram_pulse <= '1';
             write_data <= "0000111111111111";
             PSRAM_Write_Length <= "111000010000000000"; --"110001011100000100";--"101101010000000000"; --"000000000000000010";--"000000000000100000"; --"101101010000000000"; --"000000010000000000"; --"111111111"; --"101101010";
									 
			if(init_counter > 100000000) then --202500) then --185344) then --1000000
                    init_counter <= 0;
					--addr_counter <= 0;
					--color <= x"02F3";
                    init_done <= '1';
             else
                     init_counter <= init_counter+1;
                     PSRAM_RW <= '1';
                     addr_counter <= 0;
                      init_done <= '0';
             end if;

        else
                if(pixelX > hBlankUpper and pixelY < vBlankUpper) then
                addr_counter <= 512*(pixelY+1);
                psram_pulse <= '1';
                PSRAM_RW <= '0';
                elsif(pixelX > hBlankUpper and pixelY > 522) then
                PSRAM_RW <= '0';
                addr_counter <= 0;
                psram_pulse <= '1';
                elsif(pixelY > vBlankUpper and pixelY < 520 ) then --424
                      --PSRAM_Write_Length <= "000000000001000001";
					  PSRAM_Write_Length <= "000000000000000001";
                      write_data <= color; --"0000111111111111";--coorData(15 downto 0);--"0000000000000000";
					  if(yregister_int > vBlankUpper and xregister_int < hBlankUpper) then
					  addr_counter <= vBlankUpper*512+xregister_int;
					  elsif(yregister_int > vBlankUpper and xregister_int > hBlankUpper) then
					  addr_counter <= vBlankUpper*512+hBlankUpper;
					  elsif(yregister_int < vBlankUpper and xregister_int > hBlankUpper) then
					  addr_counter <= yregister_int*512+hBlankUpper;
					  else
                      addr_counter <= yregister_int*512+xregister_int;  --41502;
                      end if;
					  PSRAM_RW <= '1';
                      psram_pulse <= '1';
                else
                    psram_pulse <= '0';
                  
                end if;
        end if;
    end if;
end process;

RamCLK <= PSRAM_out_clk;
addr_to_PSRAM <= std_logic_vector(to_unsigned(addr_counter,23));

--PSRAM controller.
Inst_PSRAM : PSRAM
	Port map (
              -----------------------------------------------
              --        Signals for the controller         --
              -----------------------------------------------
              clock             => Clock, -- 100MHz
              address_in        => addr_to_PSRAM, -- RAM address
              go_in             => PSRAM_pulse,                              -- if='1' starts the operation
              write_in          => PSRAM_RW,                              -- if='0' => read; if='1' => write
              data_in           => write_data, -- data that has to be written
              data_out          => read_data, -- data that has been read
              read_done_signal  => reading,
              -----------------------------------------------
              -- Signals from the controller to the memory --
              -----------------------------------------------
              clock_out         => PSRAM_out_clk,
              ADDRESS           => MemAdr,
              ADV               => RamADVn,
              CRE               => RamCRE,
              CE                => RamCEn,
              OE                => RamOEn,
              WE                => RamWEn,
              LB                => RamLBn,
              UB                => RamUBn,
              Wait_in           => RamWait, 
              Write_Length      => PSRAM_write_length,
              reading_data      => RAM_read_En,
              line_address      => line_address,
              DATA              => MemDB
             );
end Behavioral;
