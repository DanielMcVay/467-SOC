library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

LIBRARY altera;
USE altera.altera_primitives_components.all;


entity LED_control is 
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
end entity LED_control;

architecture LED_control_arch of LED_control is

type state_type is (State_0, State_1, State_2, State_3, State_4, State_McVay, State_Wickham, init);

signal led_7 : std_logic := '0';
signal led_val : std_logic_vector(6 downto 0) := "0000000";
signal led_transition : std_logic := '0';
signal led_transition_clock : std_logic_vector(31 downto 0) := x"00000000";
signal clocks_per_transition : std_logic_vector(31 downto 0) := x"00000000";
signal temp3 : unsigned(39 downto 0);
signal temp2 : unsigned(39 downto 0);
signal led_transition_7 : std_logic := '0';
signal wait1 : std_logic;
signal button_pushed : std_logic := '0';
signal button_push_over : std_logic := '0';
signal button_timer : unsigned(31 downto 0):= x"00000000";
signal up_cntr : unsigned(6 downto 0) := "0000000";
signal down_cntr : unsigned (6 downto 0) := "1111111";
signal initialized : std_logic := '0';
signal four_transition: std_logic := '0';
signal four_transition_clock : std_logic_vector(31 downto 0) := x"00000000";
signal four_clocks_per_transition : std_logic_vector(31 downto 0) := x"00000000";
signal two_clocks_per_transition : std_logic_vector(31 downto 0) := x"00000000";
signal two_transition_clock : std_logic_vector(31 downto 0) := x"00000000";
signal two_transition : std_logic := '0';
--signal mcvay_transition : std_logic := '0';
--signal mcvay_transition_clock : std_logic_vector(1 downto 0) := "00";
signal mcVay_shifty : unsigned(6 downto 0) := "1000000";
signal dylan_shifty : unsigned(6 downto 0) := "0000001";

signal Current_State, Next_State : state_type;
signal shifty : unsigned(6 downto 0) := "1000000";
signal double_shifty : unsigned (6 downto 0) := "1100000";



--constant State_0 : std_logic_vector(3 downto 0) := x"0";
--constant State_1 : std_logic_vector(3 downto 0) := x"1";
--constant State_2 : std_logic_vector(3 downto 0) := x"2";
--constant State_3 : std_logic_vector(3 downto 0) := x"3";
--constant State_4 : std_logic_vector(3 downto 0) := x"4";

begin

	temp3 <= unsigned(SYS_CLKs_sec) * (unsigned(Base_rate));
	clocks_per_transition <= std_logic_vector(temp3(35 downto 4));
	
	two_clocks_per_transition <= std_logic_vector(shift_right(unsigned(clocks_per_transition),1));
	four_clocks_per_transition <= std_logic_vector(shift_right(unsigned(clocks_per_transition) ,2));
	
	
	four_x_base_rate : process (clk, reset)
		begin
			if(reset ='0') then
				four_transition_clock <= (others=> '0');
				four_transition <= '0';
			elsif(clk'event and clk ='1') then
				if(unsigned(four_transition_clock) < unsigned(four_clocks_per_transition)) then
					four_transition_clock <= std_logic_vector(unsigned(four_transition_clock +1));
					four_transition <='0';
				else
					four_transition <= '1';
					four_transition_clock <= (others => '0');
				end if;
			end if;
		end process;
	
	two_x_base_rate : process (clk, reset)
		begin
			if(reset ='0') then
				two_transition_clock <= (others=> '0');
				two_transition <= '0';
				led_7 <= '0';
			elsif(clk'event and clk = '1') then
				if(unsigned(two_transition_clock) < unsigned(two_clocks_per_transition)) then
					two_transition_clock <= std_logic_vector(unsigned(two_transition_clock +1));
					two_transition <='0';
				else
					two_transition <= '1';
					two_transition_clock <= (others => '0');
					led_7 <= not(led_7);
				end if;
			end if;
		end process;
		
--		mcvay_base_rate : process (clk, reset, four_transition)
--		begin
--			if(reset ='0') then
--				mcvay_transition_clock <= (others=> '0');
--				mcvay_transition <= '0';
--			elsif(clk'event and clk = '1') then
--				if(four_transition = '1') then
--					if(unsigned(mcvay_transition_clock) < 2) then
--						mcvay_transition_clock <= std_logic_vector(unsigned(mcvay_transition_clock +1));
--						mcvay_transition <='0';
--					else
--						mcvay_transition <= '1';
--						mcvay_transition_clock <= (others => '0');
--					end if;
--				end if;
--			end if;
--		end process;
	
				
			
	
	
	
	Set_LEDs : process(clk, reset)
	begin
		if (reset = '0') then
			LED <= (others => '0');
		
		elsif(clk'event and clk = '1') then
				if (HS_LED_control ='1') then
					LED <= LED_reg;
				else
					if(four_transition = '1' or button_pushed = '1') then
						--led_7 <= '0';
						LED <= led_7 & led_val;
					end if;
				end if;
		end if;
	end process;
	
	
	calculate_LED_Transition : process(clk,reset)
	begin
		if(reset = '0') then
			led_transition_clock <= (others => '0');
			led_transition <= '0';
		
		elsif(clk'event and clk = '1') then -- and button_pushed = '0'
			if(led_transition_clock = clocks_per_transition) then
				led_transition <= '1';
			end if;
			if (unsigned(led_transition_clock) > (unsigned(clocks_per_transition))) then
					led_transition_clock <= (x"00000000");
					led_transition <= not(led_transition);
					led_transition_clock <= (others => '0');
			else
			led_transition_clock <= std_logic_vector(unsigned(led_transition_clock) + 1);
			end if;
		end if;
	end process;
	
	Next_State_Logic : process (clk, reset, PB)
		begin
			
			if (reset = '0') then
				Next_State <= State_0;
				--led_val <= (others => '0');
				button_pushed <= '0';
				button_timer <= (others => '0');								
			elsif (clk'event and clk = '1') then
				if(PB = '0' and button_pushed = '0') then 
					--led_val(3 downto 0) <= SW; debug
					button_pushed <='1';
					Current_State <= init;
					case(SW) is
						when "0000" =>
							Next_State <= State_0;
						when "0001" =>
							Next_State <= State_1;
						when "0010" =>
							Next_State <= State_2;
						when "0011" =>
							Next_State <= State_3;
						when "0100" =>
							Next_State <= State_McVay;
						when "0101" =>
							Next_State <= State_Wickham;
						when others =>
							Next_State <= Current_State;
					end case;
				end if;
				
				if(button_pushed = '1') then
					if(to_integer(button_timer) < to_integer(unsigned(SYS_CLKs_sec))) then
						button_timer <= ((button_timer) + 1);
					else
						button_timer <= (others => '0');
						button_pushed <='0';
						--led_val(3 downto 0) <= x"0";
					end if;
				else
					Current_State <= Next_State;
				end if;			
			end if;
		end process;
	
	OUTPUT_LOGIC : process(clk, Next_State, led_transition, four_transition, Current_State, SW)
		begin
		if(rising_edge(clk)) then
--				if(Current_State = init) then
--					case(Next_State) is
--							when State_0 =>
--								up_cntr <= "0000000";
--							when State_2 =>
--								shifty <= "1000000";
--							when others =>
--								led_val <= "0000000";
--						end case;
--				end if;
				if(PB = '0' and button_pushed = '0') then 
					led_val <= "000" & SW;
				elsif(button_pushed = '0') then
						case(Next_State) is
						
							when State_0 =>
								if(led_transition = '1') then
									up_cntr <= up_cntr + 1;
								end if;
									led_val <= std_logic_vector(up_cntr);
									
							when State_1 =>
								if(four_transition ='1') then 
									down_cntr <= down_cntr -1;
								end if;
									led_val <= std_logic_vector(down_cntr);

							when State_2 =>
								if(two_transition = '1') then
									if (shifty = 0) then
										shifty <= "1000000";
									else
										shifty <= shift_right(shifty,1);
									end if;
								end if;
								led_val <= std_logic_vector(shifty);
							
							when State_3 =>
								if(four_transition = '1') then
									if(double_shifty = "1100000") then
										double_shifty <= "1000001";
									elsif(double_shifty = "1000001") then
										double_shifty <= "0000011";
									else
										double_shifty <= shift_left(double_shifty,1);
									end if;
										led_val <= std_logic_vector(double_shifty);
								end if;
							when State_McVay =>
								if(four_transition ='1') then
									if(mcvay_shifty = "1010110") then
										mcvay_shifty <= "1000000";
									elsif(mcvay_shifty <= "0000000") then
										mcvay_shifty <= "1000000";
									else
										mcvay_shifty <= (1-shift_right(mcvay_shifty, 1));
									end if;
										led_val <= std_logic_vector(mcvay_shifty);
								end if;
							when State_Wickham =>
								if(four_transition ='1') then
									if(dylan_shifty = "1111110") then
										dylan_shifty <= "1000000";
									elsif(dylan_shifty = "11111111") then
										dylan_shifty <= "0000001";
									else
										dylan_shifty <= (shift_left((dylan_shifty + 1), 1));
									end if;
										led_val <= std_logic_vector(dylan_shifty);
								end if;
								
									
								
							when others =>
								
						end case;
				end if;
			end if;
		end process;
		
				
end architecture LED_control_arch;