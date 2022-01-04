-- hd_video.vhd - Video signal generator
--
-- Copyright (c) 2021-2022 Francois Galea <fgalea at free.fr>
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

entity hd_video is
	generic (
		-- 1920x1200@50
		-- CLKFREQ : integer := 148500000;
		-- VFREQ : integer := 50;
		-- VRES : integer := 1350;		-- HRES*VRES must be equal to CLKFREQ/VFREQ
		-- VSWIDTH : integer := 5;
		-- VBORDER : integer := 41;
		-- VLINES : integer := 1200;
		-- HRES : integer := 2200;
		-- HSWIDTH : integer := 44;
		-- HBORDER : integer := 192;
		-- HCOLUMNS : integer := 1920

		-- 1080p60
		CLKFREQ : integer := 148500000;
		VFREQ : integer := 60;
		VRES : integer := 1125;			-- HRES*VRES must be equal to CLKFREQ/VFREQ
		VSWIDTH : integer := 5;
		VBORDER : integer := 41;
		VLINES : integer := 1080;
		HRES : integer := 2200;
		HSWIDTH : integer := 44;
		HBORDER : integer := 192;
		HCOLUMNS : integer := 1920

		-- 1080p50
		-- CLKFREQ : integer := 148500000;
		-- VFREQ : integer := 50;
		-- VRES : integer := 1350;			-- HRES*VRES must be equal to CLKFREQ/VFREQ
		-- VSWIDTH : integer := 5;
		-- VBORDER : integer := 41;
		-- VLINES : integer := 1080;
		-- HRES : integer := 2200;
		-- HSWIDTH : integer := 44;
		-- HBORDER : integer := 192;
		-- HCOLUMNS : integer := 1920

		-- 576p50
		-- CLKFREQ : integer := 32000000;
		-- VFREQ : integer := 50;
		-- VRES : integer := 625;			-- HRES*VRES must be equal to CLKFREQ/VFREQ
		-- VSWIDTH : integer := 5;
		-- VBORDER : integer := 41;
		-- VLINES : integer := 576;
		-- HRES : integer := 1024;
		-- HSWIDTH : integer := 22;
		-- HBORDER : integer := 96;
		-- HCOLUMNS : integer := 832
	);
	port (
		pclk : in std_logic;
		resetn : in std_logic;
		vsync : out std_logic;
		hsync : out std_logic;
		de : out std_logic;
		pr : out std_logic
	);
end hd_video;

architecture behavioral of hd_video is

	signal xcnt 	: unsigned(11 downto 0);
	signal ycnt 	: unsigned(11 downto 0);
	signal hde		: std_logic;
	signal vde		: std_logic;
	signal hpr		: std_logic;

begin
	de <= hde and vde;
	pr <= hpr and vde;

	process(xcnt)
	begin
		if xcnt<HSWIDTH and resetn = '1' then
			hsync <= '1';
		else
			hsync <= '0';
		end if;
	end process;

	process(ycnt)
	begin
		if ycnt<VSWIDTH and resetn = '1' then
			vsync <= '1';
		else
			vsync <= '0';
		end if;
	end process;

	process(pclk)
	begin
		if rising_edge(pclk) then
			if resetn = '0' then
				xcnt <= (others => '0');
				ycnt <= (others => '0');
				hde <= '0';
				vde <= '0';
			else
				if xcnt = HRES-1 then
					xcnt <= (others => '0');
					if ycnt = VRES-1 then
						ycnt <= (others => '0');
					else
						ycnt <= ycnt + 1;
					end if;
				else
					xcnt <= xcnt + 1;
				end if;
				if xcnt >= HBORDER-2 and xcnt < HBORDER+HCOLUMNS-2 then
					hpr <= '1';
				else
					hpr <= '0';
				end if;
				hde <= hpr;
				if ycnt >= VBORDER and ycnt < VBORDER+VLINES then
					vde <= '1';
				else
					vde <= '0';
				end if;
			end if;
		end if;
	end process;


end behavioral;
