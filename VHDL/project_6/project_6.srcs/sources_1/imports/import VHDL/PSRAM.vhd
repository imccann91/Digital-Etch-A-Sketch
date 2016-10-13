library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_STD.all;
 
entity PSRAM is
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
end PSRAM;
 
architecture Behavioral of PSRAM is
 
    type state is (start_up, idle, writing, reading, init, BCR_write, array_read_setup, array_read, burst_read_setup, burst_read_cycle, write_cycle, write_setup);
    signal next_state, current_state : state := init; -- init
--  signal next_state, current_state : state := idle; -- for TESTING
 
    -- Clock source = 100MHz - 10ns
    constant init_counter : integer := (151000); -- 151 microseconds
    constant timing_counter : integer := (5-1); -- 70 nanoseconds
 
    signal counter, next_counter : integer range 0 to init_counter := 0;
 
    signal writing_out : STD_LOGIC := '0';
 
    signal current_data_out, next_data_out : std_logic_vector(15 downto 0):= (others => '0');
    
    signal wait_prev : std_logic :='0';
    
    signal clk_out_en : std_logic :='0';
    
    signal bcr_settings : std_logic_vector(22 downto 0);
    signal data_out_ok : std_logic := '0';
    signal psram_clock : std_logic;
    
    signal done_counter: integer := 0;
    signal read_done : std_logic := '0';
    
    signal data_out_test : std_logic_vector(63 downto 0);
    signal end_of_row : std_logic := '0';
    signal wait_in_prev : std_logic := '0';
    
    constant data_out_okay : integer := (4-1);
    
    signal Data_Ready : std_logic := '0';
    
    signal row_count : integer := 0;
    
    signal write_count : integer := 0;
    
    signal current_mem_buffer_addr : integer range 0 to 2047 := 0;
begin
--    BM_MemAddress <= std_logic_vector(to_unsigned(current_mem_buffer_addr, 11));
    line_address <= std_logic_vector(to_unsigned(row_count,9));
    
    --------    Config Initialization    --------
        --          Write to the config the following features:
        --          BCR[2:0] = 111      Continuous Burst
        --          BCR[3] = 1          No Wrap
        --          BCR[5:4] = 01       1/2 Drive Strength
        --          BCR[7:6] = 00       Reserved 0
        --          BCR[8]  =  0        Wait Asserted during delay
        --          BCR[9] = 0          Reserved 0
        --          BCR[10] = 0         Active Low (Use Pullup resistor in constraints)
        --          BCR[13:11] = 110    Code6 (7 clocks) Max Clk Freq = 104Mhz
        --          BCR[14] = 1         Fixed Delay
        --          BCR[15] = 0         Synchronous Burst Access Mode
        --          BCR[17:16] = 00      Reserved 0
        --          BCR[19:18] = 10     Register Select BCR
        --          BCR[22:20] = 000    Reserved 0
        --          000 10 00 0 1 110 0 0 0 00 01 1 111 =  "00010000111000000011111" 
        --          Hex equivalent (Convienence purposes) = x"8701F"
    bcr_settings <= "000" & "10" & "00" & '0' & '1' & "011" & '0' & '0' & '0' & '0' & '0' & "01" & '1' & "111";
    
    read_done_signal <= Data_Ready;
--    DATA <= data_in when writing_out='1' else (others => 'Z');
--     DATA <= "0000000100000011" when writing_out='1' else (others => 'Z');
--   data_out <= current_data_out;
--    clock_out <= psram_clock when clk_out_en = '1' else '0';
--    psram_clock <= clock WHEN clk_out_en = '1' ELSE '0';
   
    process(clock) 
    begin
            if(rising_edge(clock)) then
                        psram_clock <= not psram_clock;
                        if(clk_out_en = '1') then
                            clock_out <= not psram_clock;
                        else
                            clock_out <= '0';
                        end if;
            end if;
    end process;
    -- FSM process
    process(psram_clock)
    begin
        if (rising_edge(psram_clock)) then
                
                
        -- Default outputs
--        clk_out_en <= '0';
 
        writing_out <= '0'; -- this signal drives the inout DATA port
 
        case current_state is
            -- Init
            when start_up =>
                     ADV <= '1';
                     next_data_out <= (others => '0');
             
                     if (counter >= init_counter) then
                       current_state <= init;
                       counter <= 0;
                     else
                       counter <= counter + 1;
                       current_state <= start_up;
                     end if;
            
            when init =>
                ADDRESS <= bcr_settings;
                ADV <= '1';
                CRE <= '1';
                CE <= '1';
                OE <= '1';
                WE <= '1';
                UB <= '1';
                LB <= '1';
                
                current_state <= BCR_write;
                
            when BCR_write =>
                ADDRESS <= bcr_settings;
                ADV <= '0';
                CRE <= '1';
                CE <= '0';
                OE <= '1';
                WE <= '0';
                UB <= '1';
                LB <= '1';
                
                if(counter = 3) then -- t(cw) requirements see spec sheet page 18 / 39
                    counter <= 0;
                    current_state <= array_read;
                    ADV <= '1';
                    CE <= '1';
                    WE <= '1';
                else
                    counter <= counter + 1;
                    current_state <= BCR_write;
                end if;
        
            
            when array_read_setup =>
                   ADDRESS <= (others => '0');
                   ADV <= '0';
                   CRE <= '0';
                   CE <= '0';
                   OE <= '1';
                   WE <= '1';
                   UB <= '0';
                   LB <= '0';
                   current_state <= array_read;
                   
           when array_read =>
                   ADDRESS <= (others => '0');
                   
                   if (counter >= timing_counter) then
                    counter <= 0;
                    next_data_out <= DATA;
                    current_state <= idle;
                    clk_out_en <= '1';
                   else
                       ADV <= '1';
                       CRE <= '0';
                       CE <= '0';
                       OE <= '0';
                       WE <= '1';
                       UB <= '0';
                       LB <= '0';  
                        
                       counter <= counter + 1;
                       current_state <= array_read;
                   end if;       
            
            
            -- Idle
            when idle =>
                ADDRESS <= address_in;
                clk_out_en <= '1';
                read_done <= '0';
--                clock_out <= '0';
                if (go_in = '0') then
                    current_state <= idle;
                else -- if a signal of start is received
                    if (write_in = '0') then -- start the reading
                        current_state <=  burst_read_setup;
                        DATA <= "ZZZZZZZZZZZZZZZZ";
                        ADV <= '0';
                        CE <= '0';
                        WE <= '1';
                        OE <= '1';
                        UB <= '0';
                        LB <= '0';
                        CRE <= '0';
--                        clk_out_en <= '1';
                    else -- start the writing
--                        current_state <= writing;
                          DATA <= data_in;
                          current_state <= write_setup;
                    end if;
                end if;
           
           when write_setup =>
                                DATA <= data_in;
                                   clk_out_en <= '1';
                                   ADV <= '0';
                                   CE <= '0';
                                   WE <= '0';
                                   OE <= '1';
                                   UB <= '0';
                                   LB <= '0';
                                    if(counter >=1) then
                                           -- next_state <= burst_read_wait_latency;
                                           current_state <= write_cycle;
                                           counter <= 0;
                                     else
                                           current_state <= write_setup;
                                           counter <= counter +1;
                                     end if;                                  
                                   
                                   
                                   
           when write_cycle =>
--                               if(Continue_Writing = '1') then
                                               clk_out_en <= '1';
                                               writing_out <= '1';
                                               ADV <= '1';
                                               CE <= '0';
                                               WE <= '0';
                                               OE <= '1';
                                               UB <= '0';
                                               LB <= '0';
           --                                    current_state <= write_cyclse;
                                                
                                               if(wait_in = '1') then
                                                   write_count <= write_count +1;
                                                   DATA <= data_in;   
           --                                         if(write_count = 100) then
           --                                           DATA <= "0000111100000001";
           --                                         elsif(write_count = 110) then
           --                                           DATA <= "0000111100000010";
           --                                         else
           --                                           DATA <= "0000111111111000"; --std_logic_vector(to_unsigned(write_count,16));
           --                                         end if;
           --                                        if(write_count => 100) then
           --                                            DATA <= "0000111100000001";
           ----                                         elsif(write_count => 200) then
           ----                                            DATA <= "0000111100000010";
           --                                         else
           --                                            DATA <= "0000111111111000"; --std_logic_vector(to_unsigned(write_count,16));
           --                                         end if;
                                                   if(write_count = to_integer(unsigned(Write_Length))) then
                                                       WE <= '1';
                                                       CE <= '1';
                                                       current_state <= idle;
                                                       write_count <= 0;
                                                     else
                                                       current_state <= write_cycle;
                                                     end if;
                                               end if;
           --                                else
           --                                    WE <= '1';
           --                                    CE <= '1';
           --                                    current_state <= idle;
           --                                    write_count <= 0;
           --                                end if;
           
           when burst_read_setup =>
                                ADV <= '1';
                                CE <= '0';
                                WE <= '1';
                                OE <= '0';
                                UB <= '0';
                                LB <= '0';
                                CRE <= '0';
                                current_state <= burst_read_cycle;
                               
           when burst_read_cycle =>
                        ADV <= '1';
                        CE <= '0';
                        WE <= '1';
                        OE <= '0';
                        UB <= '0';
                        LB <= '0';
                        CRE <= '0';
--                         if(read_done = '1') then
--                       if(done_counter >= 4) then
                    if(wait_in = '1') then
                        reading_data <= "1";
                        data_out <= DATA;
                         if(row_count = 450) then
                            OE <= '1';
                            CE <= '1';
                           
                            current_state <= idle;
                            read_done <= '1';
                           clk_out_en <= '1';
                            row_count <= 0;
                            reading_data <= "0";
                         else
                            row_count <= row_count +1;
                            clk_out_en <= '1';
                            current_state <= burst_read_cycle;
                         end if;      
                     else
                        current_state <= burst_read_cycle;
                        clk_out_en <= '1';
                     end if;
                                                                            
            
            
            
            -- Writing
            when writing =>
                writing_out <= '1';
 
                if (counter >= timing_counter) then -- the data has been written
                    counter <= 0;
                    current_state <= idle;
                else
                    CE <= '0';
                    LB <= '0';
                    UB <= '0';
                    OE <= '0';
                    WE <= '0';
 
                    counter <= counter + 1;
                    current_state <= writing;
                end if;
 
            -- Reading
            when reading =>
                if (counter >= timing_counter) then -- the data has been read
                    counter <= 0;
                    data_out_ok <= '1';
                    data_out <= DATA;
                    current_state <= idle;
                else
                    CE <= '0';
                    LB <= '0';
                    UB <= '0';
                    OE <= '0';
 
                    counter <= counter + 1;
                    current_state <= reading;
                end if;
        end case;
    end if;
    end process;
 
end Behavioral;