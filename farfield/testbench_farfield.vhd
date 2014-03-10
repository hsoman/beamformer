----------------------------------------------------------------------------------
-- Created by Sam Rohrer                                                        --
-- Beamforms in the nearfield based on a generic for distance                   -- 
-- This is the testbench used for ISim models                                   --
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity testbench_farfield is
	
	port(
	--sys_clock           : in     std_logic; -- system clk signal
	swt_distance        : in     std_logic_vector (4 downto 0); -- switch 0 to 4
	--but_reset           : in     std_logic ; --Button D
	
	pin_dataout         :    out std_logic_vector (7 downto 0); -- JA 0 to 7 
	pin_channel         :    out std_logic_vector (4 downto 0); -- JB 0 to 4
	
	--pin_datain          : in     std_logic_vector (7 downto 0); -- JC 0 to 7
	--pin_datain_2        : in     std_logic_vector (7 downto 0); -- JD 0 to 7
	
	--pin_int             : in     std_logic; -- JB5
	
	pin_speaker_enable  :    out std_logic; --JB7
	
	pin_rd              :    out std_logic  --JB6
	
	);
end testbench_farfield;

architecture Behavioral of testbench_farfield is
	
	--******************* Signal Processing ***************--
	component farfield_processing is
		
		generic(
		divisor           : integer := 50; -- difference between system clock 1 us 
		speed_sound       : integer := 13397; -- in inches/second
		speaker_distance  : integer := 2 -- in inches
		);
	
		port(
		i_datain_r        : in     std_logic_vector (7 downto 0); -- 8 bit from memory
		i_datain_l        : in     std_logic_vector (7 downto 0); -- 8 bit from memory
		i_clock           : in     std_logic;                     -- 
		i_distance        : in     std_logic_vector (4 downto 0); -- Switches determine distance
		i_reset           : in     std_logic ;                    -- To reset the entire system
		i_sampleclock     : in     std_logic ;                    -- Rate at which the music is playing
	
		o_speaker_enable  :    out std_logic; --LDAC enable	
		o_dataout         :    out std_logic_vector (7 downto 0); -- 8 bit to be multiplexed 
		o_channel         :    out std_logic_vector (4 downto 0)  -- 5 bit to select which DAC to enable
		);
		
	end component;
	
	--**************** User Signals ***************--
	
	-- To mimic the input ports
	signal test_datain_r   : std_logic_vector (7 downto 0) := X"00";
	signal test_datain_l   : std_logic_vector (7 downto 0) := X"00";
	signal sys_clock       : std_logic;
	signal but_reset       : std_logic;
	signal pin_int         : std_logic;

	-- Normal signals needed
	signal clockpulses     : integer range 0 to 2200;
	
	signal sample_clock    : std_logic;
	
	signal sig_datain_r    : std_logic_vector (7 downto 0);
	signal sig_datain_l    : std_logic_vector (7 downto 0);
	
	--**************** End User Signals ***********--

begin
	
	--*************** User Processes **************--
	but_reset <= '0', '1' after 100 ns, '0' after 1000 ns;
	pin_int   <= '0';
	
	
	-- *************** Test Data Being Generated **********--
	generate_data: process (sample_clock)
	begin
	if (rising_edge(sample_clock)) then
		test_datain_r <= test_datain_r + X"11";
		test_datain_l <= test_datain_l + X"11";
	end if;
	end process;
	-- **************************************************** --


	clock: process
	begin
		sys_clock   <= '0';
		wait for 5 ns;
		sys_clock   <= '1';
		wait for 5 ns;
	end process; 

	sampleclock_division : process(but_reset, sys_clock)
	begin
		if (but_reset = '1') then
			clockpulses                 <= 0;
			sample_clock             <= '0';
		elsif(rising_edge(sys_clock)) then
			clockpulses                 <= clockpulses + 1 ;
			if(clockpulses = 1100) then 
				sample_clock            <= Not sample_clock;
				clockpulses             <= 0;
			end if;		
		end if;
	end process;
	
	rd_control : process (but_reset, sys_clock, clockpulses)
	begin
		if (but_reset = '1' ) then 
			pin_rd <= '1';
		elsif (rising_edge(sys_clock)) then
			if (clockpulses = 400) then
				pin_rd <= '0';
			elsif (clockpulses = 650) then 
				pin_rd <= '1';
				if(pin_int = '0') then
					sig_datain_r <= test_datain_r;
					sig_datain_l <= test_datain_l;
				end if;
			end if;
		end if;
	end process;
 
	--*************** End User Processes **********--
	
--**************** Signal Processing Port Map ***********--	
	
	fpga : farfield_processing
	generic map(
		divisor           	=> 50,
		speed_sound         => 13397,
		speaker_distance    => 2
		)

	port map(
		i_datain_r          => sig_datain_r,
		i_datain_l          => sig_datain_l,
		i_clock             => sys_clock,
		i_distance          => swt_distance,
		i_reset             => but_reset,
		i_sampleclock       => sample_clock,

		o_speaker_enable    => pin_speaker_enable,
		o_dataout           => pin_dataout,
		o_channel           => pin_channel
		);	
	
end Behavioral;