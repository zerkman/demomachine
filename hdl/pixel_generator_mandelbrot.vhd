-- pixel_generator_mandelbrot.vhd - Mandelbrot pixel generator
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
	type palette_t is array(0 to 254) of std_logic_vector(15 downto 0);
	constant pal	: palette_t := (
		x"dc25",x"feaa",x"dfaf",x"97f3",x"47b7",x"1ef9",x"061b",
		x"04fd",x"139e",x"2a7f",x"519f",x"88ff",x"b07f",x"d03f",x"e81f",
		x"f81e",x"f83e",x"f87d",x"f0dc",x"d93b",x"c1da",x"aa79",x"8317",
		x"63f6",x"44b4",x"2d73",x"1df1",x"0e70",x"06ee",x"074c",x"078b",
		x"07aa",x"17e8",x"1fe7",x"2fe6",x"47e5",x"5fc4",x"77a4",x"9763",
		x"af22",x"c6e2",x"d681",x"e621",x"eda0",x"f520",x"fca0",x"fc00",
		x"fb80",x"fb00",x"f280",x"ea00",x"d9a0",x"d140",x"c100",x"a8c0",
		x"9880",x"8061",x"6821",x"5001",x"4002",x"3002",x"2003",x"1803",
		x"1004",x"0825",x"0045",x"0066",x"00a7",x"00c7",x"0108",x"0949",
		x"09aa",x"11eb",x"224c",x"2aac",x"3b0d",x"4b8e",x"5bef",x"6c70",
		x"84d1",x"9532",x"ad93",x"bdf4",x"c635",x"d676",x"deb6",x"e6f7",
		x"ef38",x"f758",x"ff99",x"ffba",x"ffda",x"ffdb",x"fffb",x"fffc",
		x"f7fc",x"f7fc",x"effd",x"e7fd",x"dfde",x"cfbe",x"c7be",x"b79e",
		x"a75f",x"973f",x"871f",x"76df",x"669f",x"565f",x"461f",x"3ddf",
		x"2d9f",x"253f",x"1cff",x"149f",x"0c3f",x"0bdf",x"037f",x"033f",
		x"02df",x"029f",x"023e",x"01fe",x"01be",x"097e",x"095d",x"111d",
		x"18fd",x"20bc",x"289c",x"307c",x"405b",x"485b",x"583b",x"681a",
		x"701a",x"8019",x"9019",x"a018",x"b018",x"b817",x"c017",x"d036",
		x"d835",x"e055",x"e874",x"e874",x"f093",x"f0b2",x"f8f2",x"f911",
		x"f930",x"f96f",x"f9af",x"f9ce",x"fa0d",x"fa4d",x"f28c",x"eacb",
		x"eb0b",x"e36a",x"dbaa",x"d409",x"cc49",x"c4a8",x"b4e8",x"ad27",
		x"a567",x"95a6",x"85e6",x"7e25",x"6e45",x"5e84",x"56a4",x"46c4",
		x"3f03",x"3723",x"2f43",x"2762",x"1f82",x"1782",x"17a2",x"0fc1",
		x"0fc1",x"07e1",x"07e1",x"07e1",x"07e0",x"07e0",x"07e0",x"07e0",
		x"07e0",x"07e0",x"0fc0",x"0fc0",x"17a0",x"1780",x"1f80",x"2760",
		x"2f40",x"3720",x"3f00",x"46e0",x"4ec0",x"5e80",x"6660",x"6e40",
		x"7e00",x"8dc0",x"95a0",x"a560",x"ad20",x"b4e1",x"bca1",x"c461",
		x"cc21",x"d3e1",x"dba2",x"e362",x"eb22",x"eae2",x"f2a2",x"f263",
		x"fa43",x"fa03",x"f9e4",x"f9a4",x"f984",x"f945",x"f925",x"f905",
		x"f8e6",x"f8c6",x"f0a6",x"f087",x"e867",x"e868",x"e048",x"d848",
		x"d829",x"d029",x"c80a",x"c00a",x"b80b",x"b00b",x"a80c",x"980c",
		x"900d",x"880d",x"780e",x"700e",x"600f",x"582f",x"5030",x"4851"
	);

	-- current pixel to be displayed
	signal xpos 	: unsigned(11 downto 0);
	signal ypos 	: unsigned(10 downto 0);

	-- mandelbrot variables
	constant nbitsl	: integer := 25;	-- [-4..4] interval, 3.22 fixed point
	constant nbitss	: integer := 19;	-- [-2..2] inverval, 2.17 fixed point
	signal x		: signed(nbitsl-1 downto 0);
	signal y		: signed(nbitsl-1 downto 0);
	signal xinc		: signed(nbitsl-1 downto 0);
	signal yinc		: signed(nbitsl-1 downto 0);
	signal rowbegx	: signed(nbitsl-1 downto 0);
	signal rowbegy	: signed(nbitsl-1 downto 0);
	signal rbxinc	: signed(nbitsl-1 downto 0);
	signal rbyinc	: signed(nbitsl-1 downto 0);

	-- mandelbrot iteration blocks
	constant nsteps	: integer := 16;
	component mandelbrot_it is
		generic (
			nbits	: integer := 18
		);
		port (
			clk		: in std_logic;
			resetn	: in std_logic;
			i_x0	: in std_logic_vector(nbits-1 downto 0);
			i_y0	: in std_logic_vector(nbits-1 downto 0);
			i_x		: in std_logic_vector(nbits-1 downto 0);
			i_y		: in std_logic_vector(nbits-1 downto 0);
			i_n		: in std_logic_vector(7 downto 0);
			i_dv	: in std_logic;
			o_x0	: out std_logic_vector(nbits-1 downto 0);
			o_y0	: out std_logic_vector(nbits-1 downto 0);
			o_x		: out std_logic_vector(nbits-1 downto 0);
			o_y		: out std_logic_vector(nbits-1 downto 0);
			o_n		: out std_logic_vector(7 downto 0);
			o_dv	: out std_logic
		);
	end component;

	type vector_nbits is array (natural range <>) of std_logic_vector(nbitss-1 downto 0);
	type vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
	signal v_x0	: vector_nbits(0 to nsteps);
	signal v_y0	: vector_nbits(0 to nsteps);
	signal v_x	: vector_nbits(0 to nsteps);
	signal v_y	: vector_nbits(0 to nsteps);
	signal v_n	: vector8(0 to nsteps);
	signal v_dv	: std_logic_vector(0 to nsteps);

	signal initcnt	: unsigned(7 downto 0);

begin
	-- large format is [-4..4] interval
	v_x0(0) <= std_logic_vector(x(nbitsl-2 downto nbitsl-nbitss-1));
	v_y0(0) <= std_logic_vector(y(nbitsl-2 downto nbitsl-nbitss-1));
	v_x(0) <= std_logic_vector(x(nbitsl-2 downto nbitsl-nbitss-1));
	v_y(0) <= std_logic_vector(y(nbitsl-2 downto nbitsl-nbitss-1));
	v_n(0) <= (others => '0');

	-- initial overflow if x or y are out of the [-2..2] range
	process(x,y)
		-- integral parts of x and y
		variable xi	: signed(2 downto 0);
		variable yi	: signed(2 downto 0);
	begin
		xi := x(nbitsl-1 downto nbitsl-3);
		yi := y(nbitsl-1 downto nbitsl-3);
		if xi <= -3 or xi >= 2 or yi <= -3 or yi >= 2 then
			v_dv(0) <= '1';
		else
			v_dv(0) <= '0';
		end if;
	end process;

	mand_it: for i in 0 to nsteps-1 generate
		it: mandelbrot_it
		generic map ( nbits => nbitss )
		port map (
			clk => clk,
			resetn => resetn,
			i_x0 => v_x0(i),
			i_y0 => v_y0(i),
			i_x => v_x(i),
			i_y => v_y(i),
			i_n => v_n(i),
			i_dv => v_dv(i),
			o_x0 => v_x0(i+1),
			o_y0 => v_y0(i+1),
			o_x => v_x(i+1),
			o_y => v_y(i+1),
			o_n => v_n(i+1),
			o_dv => v_dv(i+1)
		);
	end generate mand_it;

	process(clk)
		variable step	: signed(nbitsl-1 downto 0);
		variable init_x	: signed(nbitsl-1 downto 0);
		variable init_y	: signed(nbitsl-1 downto 0);
	begin
		if rising_edge(clk) then
			step := to_signed(integer(4.0*real(2**(nbitsl-3))/real(XRES)),nbitsl);
			init_x := to_signed(integer(-2.5*real(2**(nbitsl-3))),nbitsl);
			init_y := to_signed(-(YRES/2)*to_integer(step),nbitsl);
			if resetn = '0' then
				xpos <= (others => '0');
				ypos <= (others => '0');
				rowbegx <= init_x;
				rowbegy <= init_y;
				x <= init_x;
				y <= init_y;
				rbxinc <= to_signed(0,nbitsl);
				rbyinc <= xinc;
				xinc <= step;
				yinc <= to_signed(0,nbitsl);
				initcnt <= to_unsigned(nsteps*2,initcnt'length);
			elsif initcnt > 0 or pr = '1' then
				if xpos = XRES-1 then
					xpos <= (others => '0');
					if ypos = YRES-1 then
						ypos <= (others => '0');
						x <= init_x;
						y <= init_y;
						rowbegx <= init_x;
						rowbegy <= init_y;
					else
						ypos <= ypos + 1;
						x <= rowbegx + rbxinc;
						y <= rowbegy + rbyinc;
						rowbegx <= rowbegx + rbxinc;
						rowbegy <= rowbegy + rbyinc;
					end if;
				else
					xpos <= xpos + 1;
					x <= x + xinc;
					y <= y + yinc;
				end if;
				if initcnt > 0 then
					initcnt <= initcnt - 1;
				end if;
				if cfg = '0' then
					if v_dv(nsteps) = '1' then
						data <= pal(to_integer(unsigned(v_n(nsteps))));
					else
						data <= x"0000";
					end if;
				else
					data <= (others => xpos(5) xor ypos(5));
				end if;
			end if;
		end if;
	end process;
end behavioral;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_it is
	generic (
		nbits	: integer := 18
	);
	port (
		clk		: in std_logic;
		resetn	: in std_logic;
		i_x0	: in std_logic_vector(nbits-1 downto 0);
		i_y0	: in std_logic_vector(nbits-1 downto 0);
		i_x		: in std_logic_vector(nbits-1 downto 0);
		i_y		: in std_logic_vector(nbits-1 downto 0);
		i_n		: in std_logic_vector(7 downto 0);
		i_dv	: in std_logic;
		o_x0	: out std_logic_vector(nbits-1 downto 0);
		o_y0	: out std_logic_vector(nbits-1 downto 0);
		o_x		: out std_logic_vector(nbits-1 downto 0);
		o_y		: out std_logic_vector(nbits-1 downto 0);
		o_n		: out std_logic_vector(7 downto 0);
		o_dv	: out std_logic
	);
end mandelbrot_it;

architecture behavioral of mandelbrot_it is
	-- pipeline registers
	signal sx0		: signed(nbits-1 downto 0);
	signal sy0		: signed(nbits-1 downto 0);
	signal sn		: unsigned(7 downto 0);
	signal sdv		: std_logic;

	-- intermediary values
	signal sx2		: unsigned(nbits-1 downto 0);
	signal sy2		: unsigned(nbits-1 downto 0);
	signal s2xy		: signed(nbits+1 downto 0);
begin

	it1: process(clk)
		variable x2		: signed(nbits*2-1 downto 0);
		variable y2		: signed(nbits*2-1 downto 0);
		variable xy		: signed(nbits*2-1 downto 0);
	begin
		if rising_edge(clk) then
			if resetn = '0' then
				sx0 <= (others => '0');
				sy0 <= (others => '0');
				sn <= (others => '0');
				sdv <= '0';
				sx2 <= (others => '0');
				sy2 <= (others => '0');
				s2xy <= (others => '0');
			else
				x2 := signed(i_x)*signed(i_x);
				y2 := signed(i_y)*signed(i_y);
				xy := signed(i_x)*signed(i_y);
				sx0 <= signed(i_x0);
				sy0 <= signed(i_y0);
				sx2 <= unsigned(x2(2*nbits-3 downto nbits-2));	-- 2.
				sy2 <= unsigned(y2(2*nbits-3 downto nbits-2));	-- 2.
				s2xy <= xy(2*nbits-2 downto nbits-3);	-- 4.
				sn <= unsigned(i_n);
				sdv <= i_dv;
			end if;
		end if;
	end process;

	it2: process(clk)
		variable m2		: unsigned(nbits downto 0);
		variable nx		: signed(nbits+1 downto 0);
		variable ny		: signed(nbits+1 downto 0);
		variable nxi	: signed(3 downto 0);
		variable nyi	: signed(3 downto 0);
	begin
		if rising_edge(clk) then
			if resetn = '0' then
				o_x0 <= (others => '0');
				o_y0 <= (others => '0');
				o_x <= (others => '0');
				o_y <= (others => '0');
				o_n <= (others => '0');
				o_dv <= '0';
			else
				m2 := ('0'&sx2) + ('0'&sy2);		-- 3.
				nx := signed("00"&sx2) - signed("00"&sy2) + resize(sx0,nx'length);	-- 4.
				ny := s2xy + resize(sy0,ny'length);	-- 4.
				nxi := nx(nbits+1 downto nbits-2);
				nyi := ny(nbits+1 downto nbits-2);
				if sdv = '1' or m2(nbits) = '1' then
					-- divergence occured
					o_n <= std_logic_vector(sn);
					o_dv <= '1';
				else
					o_n <= std_logic_vector(sn + 1);
					o_dv <= '0';
					if nxi <= -3 or nxi >= 2 or nyi <= -3 or nyi >= 2 then
						-- bounds overflow => divergence at next iteration
						o_dv <= '1';
					end if;
				end if;
				o_x0 <= std_logic_vector(sx0);
				o_y0 <= std_logic_vector(sy0);
				o_x <= std_logic_vector(nx(nbits-1 downto 0));
				o_y <= std_logic_vector(ny(nbits-1 downto 0));
			end if;
		end if;
	end process;
end behavioral;
