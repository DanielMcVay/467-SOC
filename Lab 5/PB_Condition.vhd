library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

LIBRARY altera;
USE altera.altera_primitives_components.all;

entity PB_Condition is
	port(
		clk                : in std_logic;                        -- system clock
		reset              : in std_logic;                        -- system reset
		PB                 : in std_logic;                        -- Pushbutton to change state
		SYS_CLKs_sec       : in std_logic_vector(31 downto 0);    -- Number of system clock cycles in one second
		PB_out				 : out std_logic
    );
end entity;

architecture PB_Condition_arch of PB_Condition is

signal Clocks_per_transition, Clock_count : std_logic_vector(27 downto 0);

begin

		Clocks_per_transition <= SYS_CLKs_sec(31 downto 4);
		
		SignalUpdate : process(clk,reset)
			begin
				if(reset ='0') then
					PB_out <= '1';
				
				elsif(clk'event and clk = '1') then
					if(Clock_count = Clocks_per_transition) then
						if(PB = '0') then
							PB_out <= '0';
							Clock_count <= (others => '0');
						end if;
					else
						Clock_count <= std_logic_vector(unsigned(Clock_count) + 1);
						PB_out <= '1';
					end if;
				end if;
			end process;
				

end architecture PB_Condition_arch;