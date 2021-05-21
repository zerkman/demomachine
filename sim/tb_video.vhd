-- tb_video.vhd - Video output testbench
--
-- Copyright (c) 2020,2021 Francois Galea <fgalea at free.fr>
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

entity tb_video is
end tb_video;


architecture dut of tb_video is
	component hd_video is
		port (
			pclk : in std_logic;
			resetn : in std_logic;
			vsync : out std_logic;
			hsync : out std_logic;
			de : out std_logic;
			pr : out std_logic
		);
	end component;

	component pixel_generator is
		port (
			clk 	: in std_logic;
			resetn	: in std_logic;
			pr 		: in std_logic;
			cfg		: in std_logic;
			data 	: out std_logic_vector(15 downto 0)
		);
	end component;

	signal clk			: std_logic := '1';
	signal resetn		: std_logic;
	signal irq_f2p		: std_logic_vector(0 downto 0);

	signal config_reg	: std_logic_vector(31 downto 0);

	signal vcfg			: std_logic;
	signal pix			: std_logic_vector(15 downto 0);
	signal vsync		: std_logic;
	signal hsync		: std_logic;
	signal de			: std_logic;
	signal pr			: std_logic;

begin

	vid:hd_video port map (
		pclk => clk,
		resetn => resetn,
		vsync => vsync,
		hsync => hsync,
		de => de,
		pr => pr
	);

	pixgen:pixel_generator port map (
		clk => clk,
		resetn => resetn,
		pr => pr,
		cfg => vcfg,
		data => pix
	);

	vcfg <= '1';

	clk <= not clk after 3367003 fs;	-- 148.5 MHz
	resetn <= '0', '1' after 100 ns;

end dut;
