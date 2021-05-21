-- fx_zturn_top.vhd - Top-level for the Z-Turn board
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

entity zturn_top is
	port (
		DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
		DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
		DDR_cas_n : inout STD_LOGIC;
		DDR_ck_n : inout STD_LOGIC;
		DDR_ck_p : inout STD_LOGIC;
		DDR_cke : inout STD_LOGIC;
		DDR_cs_n : inout STD_LOGIC;
		DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
		DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
		DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
		DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
		DDR_odt : inout STD_LOGIC;
		DDR_ras_n : inout STD_LOGIC;
		DDR_reset_n : inout STD_LOGIC;
		DDR_we_n : inout STD_LOGIC;
		FIXED_IO_ddr_vrn : inout STD_LOGIC;
		FIXED_IO_ddr_vrp : inout STD_LOGIC;
		FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
		FIXED_IO_ps_clk : inout STD_LOGIC;
		FIXED_IO_ps_porb : inout STD_LOGIC;
		FIXED_IO_ps_srstb : inout STD_LOGIC;
		LCD_DATA : out std_logic_vector(15 downto 0);
		LCD_VSYNC : out std_logic;
		LCD_HSYNC : out std_logic;
		LCD_DE : out std_logic;
		LCD_PCLK : out std_logic;
		LEDS : out std_logic_vector (2 downto 0);  -- (0=>Rn,1=>Gn,2=>Bn)
		I2C0_SCL : inout STD_LOGIC;
		I2C0_SDA : inout STD_LOGIC;
		MEMS_INTn : in STD_LOGIC;
		HDMI_INTn : in STD_LOGIC
	);
end zturn_top;


architecture structure of zturn_top is
	component ps_domain_wrapper is
		port (
			DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
			DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
			DDR_cas_n : inout STD_LOGIC;
			DDR_ck_n : inout STD_LOGIC;
			DDR_ck_p : inout STD_LOGIC;
			DDR_cke : inout STD_LOGIC;
			DDR_cs_n : inout STD_LOGIC;
			DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
			DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
			DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
			DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
			DDR_odt : inout STD_LOGIC;
			DDR_ras_n : inout STD_LOGIC;
			DDR_reset_n : inout STD_LOGIC;
			DDR_we_n : inout STD_LOGIC;
			FIXED_IO_ddr_vrn : inout STD_LOGIC;
			FIXED_IO_ddr_vrp : inout STD_LOGIC;
			FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
			FIXED_IO_ps_clk : inout STD_LOGIC;
			FIXED_IO_ps_porb : inout STD_LOGIC;
			FIXED_IO_ps_srstb : inout STD_LOGIC;
			IIC_0_0_scl_io : inout STD_LOGIC;
			IIC_0_0_sda_io : inout STD_LOGIC;
			clk : out STD_LOGIC;
			out_reg0_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
			pclk : out STD_LOGIC;
			resetn : out STD_LOGIC
		);
	end component;

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

	signal clk			: std_logic;
	signal resetn		: std_logic;
	signal pclk			: std_logic;
	signal soft_resetn	: std_logic;
	signal irq_f2p		: std_logic_vector(0 downto 0);

	signal config_reg	: std_logic_vector(31 downto 0);

	signal vcfg			: std_logic_vector(0 downto 0);
	signal opix			: std_logic_vector(15 downto 0);
	signal ovsync		: std_logic;
	signal ohsync		: std_logic;
	signal ode			: std_logic;
	signal pr			: std_logic;

begin
	soft_resetn <= config_reg(0) and resetn;
	LEDS <= "111";
	LCD_PCLK <= pclk;
	LCD_DATA <= opix;
	LCD_VSYNC <= ovsync;
	LCD_HSYNC <= ohsync;
	LCD_DE <= ode;

	psd:ps_domain_wrapper port map(
		DDR_addr => DDR_addr,
		DDR_ba => DDR_ba,
		DDR_cas_n => DDR_cas_n,
		DDR_ck_n => DDR_ck_n,
		DDR_ck_p => DDR_ck_p,
		DDR_cke => DDR_cke,
		DDR_cs_n => DDR_cs_n,
		DDR_dm => DDR_dm,
		DDR_dq => DDR_dq,
		DDR_dqs_n => DDR_dqs_n,
		DDR_dqs_p => DDR_dqs_p,
		DDR_odt => DDR_odt,
		DDR_ras_n => DDR_ras_n,
		DDR_reset_n => DDR_reset_n,
		DDR_we_n => DDR_we_n,
		FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
		FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
		FIXED_IO_mio => FIXED_IO_mio,
		FIXED_IO_ps_clk => FIXED_IO_ps_clk,
		FIXED_IO_ps_porb => FIXED_IO_ps_porb,
		FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
		IIC_0_0_scl_io => I2C0_SCL,
		IIC_0_0_sda_io => I2C0_SDA,
		clk => clk,
		out_reg0_0 => config_reg,
		resetn => resetn,
		pclk => pclk
	);

	vcfg(0) <= config_reg(1);
	vid:hd_video port map (
		pclk => pclk,
		resetn => soft_resetn,
		vsync => ovsync,
		hsync => ohsync,
		de => ode,
		pr => pr
	);

	pixgen:pixel_generator port map (
		clk => pclk,
		resetn => soft_resetn,
		pr => pr,
		cfg => vcfg(0),
		data => opix
	);

end structure;
