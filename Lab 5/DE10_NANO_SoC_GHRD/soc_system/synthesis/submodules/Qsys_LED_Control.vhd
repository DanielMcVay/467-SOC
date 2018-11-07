library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity Qsys_LED_control is
	port (clk : in std_logic;
			reset_n : in std_logic;  --reset asserted low
			avs_s1_address : in std_logic_vector(1 downto 0);  
			avs_s1_write : in std_logic;
			avs_s1_writedata: in std_logic_vector(31 downto 0);
			avs_s1_read: in std_logic;
			avs_s1_readdata : out std_logic_vector(31 downto 0);
			switches: in std_logic_vector(3 downto 0);
			pushbutton: in std_logic;
			LEDs : out std_logic_vector(7 downto 0)
			);
end entity Qsys_LED_control;
	
architecture Qsys_LED_Control_arch of Qsys_LED_control is

component LED_control is 
    port(
		clk                : in std_logic;                        -- system clock
		reset              : in std_logic;                        -- system reset
		PB                 : in std_logic;                        -- Pushbutton to change state
		SW                 : in  std_logic_vector(3 downto 0);    -- Switches that determine next state
		HS_LED_control     : in std_logic;                        -- Software is in control when asserted (=1)
		SYS_CLKs_sec       : in std_logic_vector(31 downto 0);    -- Number of system clock cycles in one second
		Base_rate          : in std_logic_vector(7 downto 0);     -- base transition time in seconds, fixed- point data type
		LED_reg            : in  std_logic_vector(7 downto 0);    -- LED register
		LED                : out std_logic_vector(7 downto 0)     -- LEDs on the DE10-Nano board
    );
end component LED_control;

component PB_Condition is
	port(
		clk                : in std_logic;                        -- system clock
		reset              : in std_logic;                        -- system reset
		PB                 : in std_logic;                        -- Pushbutton to change state
		SYS_CLKs_sec       : in std_logic_vector(31 downto 0);    -- Number of system clock cycles in one second
		PB_out				 : out std_logic
    );
end component PB_Condition;
       
signal PB_out : std_logic;

signal reg0, reg1, reg2, reg3, temp0, temp1, temp2, temp3 : std_logic_vector(31 downto 0);


	begin
	
	led_control_internal : component LED_control port map (clk, reset_n, pushbutton, switches, reg0(0), reg1, reg3(7 downto 0), reg2(7 downto 0), LEDs);
	
	assign : process(clk, reset_n) is
	begin
		if(rising_edge(clk))then
			if(reset_n = '0')then
				reg0 <= "00000000000000000000000000000000";
				reg1 <= x"02FAF080";
				reg2 <= "00000000000000000000000000000011";
				reg3 <= x"00000020";
			end if;
			if (avs_s1_write = '1') then
				case avs_s1_address  is
					when "00" => reg0 <= avs_s1_writedata;
					when "01" => reg1 <= avs_s1_writedata;
					when "10" => reg2 <= avs_s1_writedata;
					when "11" => reg3 <= avs_s1_writedata;
				end case;
			end if;
		end if;
		
		if (rising_edge(clk) and avs_s1_read ='1') then
			case avs_s1_address  is
				when "00" => avs_s1_readdata <= reg0;
				when "01" => avs_s1_readdata <= reg1;
				when "10" => avs_s1_readdata <= reg2;
				when "11" => avs_s1_readdata <= reg3;
				when others => avs_s1_readdata <= (others => '0'); --return zeros for undefined registers
			end case;
		end if;
	end process;
	
	
end architecture Qsys_LED_Control_arch; 