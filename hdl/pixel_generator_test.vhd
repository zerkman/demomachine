-- pixel_generator_test.vhd - Test pixel generator
--
-- Copyright (c) 2021 Francois Galea <fgalea at free.fr>
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_generator is
	generic (
		XRES : integer := 1920;
		YRES : integer := 1080
	);
	port (
		clk 	: in std_logic;
		resetn	: in std_logic;
		pr 		: in std_logic;
		cfg		: in std_logic;
		data 	: out std_logic_vector(15 downto 0)
	);
end pixel_generator;


architecture behavioral of pixel_generator is
	signal xpos 	: unsigned(11 downto 0);
	signal ypos 	: unsigned(10 downto 0);
	signal r		: unsigned(4 downto 0);
	signal g		: unsigned(5 downto 0);
	signal b		: unsigned(4 downto 0);
	signal xcc		: unsigned(5 downto 0);
	signal ycc		: unsigned(7 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if resetn = '0' then
				xpos <= (others => '0');
				ypos <= (others => '0');
				r <= (others => '1');
				g <= (others => '0');
				b <= (others => '0');
				xcc <= (others => '0');
				ycc <= (others => '0');
				data <= (others => '0');
			elsif pr = '1' then
				if cfg = '0' then
					data <= std_logic_vector(r & g & b);
				else
					data <= (others => xpos(5) xor ypos(5));
				end if;
				if xpos = XRES-1 then
					xpos <= (others => '0');
					if ypos = YRES-1 then
						ypos <= (others => '0');
						ycc <= (others => '0');
						r <= (others => '1');
						g <= (others => '0');
						b <= (others => '0');
					else
						ypos <= ypos + 1;
					end if;
				else
					xpos <= xpos + 1;
				end if;
				if xcc = (XRES/64)-1 then
					xcc <= (others => '0');
					g <= g + 1;
				else
					xcc <= xcc + 1;
				end if;
				if xpos = XRES-1 then
					xcc <= (others => '0');
					if ycc+4 >= (YRES*4/32) then
						ycc <= ycc + 4 - (YRES*4/32);
						r <= r - 1;
						b <= b + 1;
					else
						ycc <= ycc + 4;
					end if;
				end if;
			end if;
		end if;
	end process;

end behavioral;
