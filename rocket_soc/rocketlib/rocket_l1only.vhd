-----------------------------------------------------------------------------
--! @file
--! @copyright  Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author     Sergey Khabarov - sergeykhbr@gmail.com
--! @brief      RockeTile top level.
--! @details    RISC-V "RocketTile" without Uncore subsystem.
------------------------------------------------------------------------------
--! Standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Data transformation and math functions library
library commonlib;
use commonlib.types_common.all;

--! Technology definition library.
library techmap;
--! Technology constants definition.
use techmap.gencomp.all;
--! AMBA system bus specific library.
library ambalib;
--! AXI4 configuration constants.
use ambalib.types_amba4.all;
--! Rocket-chip specific library
library rocketlib;
--! TileLink interface description.
use rocketlib.types_rocket.all;
library work;
use work.all;

--! @brief   RocketTile entity declaration.
--! @details This module implements Risc-V Core with L1-cache, 
--!          branch predictor and other stuffs of the RocketTile.
entity rocket_l1only is 
generic (
    hartid : integer := 0;
    reset_vector : integer := 16#1000#
);
port ( 
    nrst     : in std_logic;
    clk_sys  : in std_logic;
    msti1    : in nasti_master_in_type;
    msto1    : out nasti_master_out_type;
    mstcfg1  : out nasti_master_config_type;
    msti2    : in nasti_master_in_type;
    msto2    : out nasti_master_out_type;
    mstcfg2  : out nasti_master_config_type;
    interrupts : in std_logic_vector(CFG_CORE_IRQ_TOTAL-1 downto 0)
);
  --! @}

end;

--! @brief SOC top-level  architecture declaration.
architecture arch_rocket_l1only of rocket_l1only is

  constant CFG_HARTID : std_logic_vector(63 downto 0) := conv_std_logic_vector(hartid, 64);
  constant CFG_RESET_VECTOR : std_logic_vector(63 downto 0) := conv_std_logic_vector(reset_vector, 64);

  constant xmstconfig1 : nasti_master_config_type := (
     descrsize => PNP_CFG_MASTER_DESCR_BYTES,
     descrtype => PNP_CFG_TYPE_MASTER,
     vid => VENDOR_GNSSSENSOR,
     did => RISCV_CACHED_TILELINK
  );

  constant xmstconfig2 : nasti_master_config_type := (
     descrsize => PNP_CFG_MASTER_DESCR_BYTES,
     descrtype => PNP_CFG_TYPE_MASTER,
     vid => VENDOR_GNSSSENSOR,
     did => RISCV_UNCACHED_TILELINK
  );
  
  signal cpu_rst : std_logic;
  
  signal cto : tile_cached_out_type;
  signal cti : tile_cached_in_type;

  signal uto : tile_cached_out_type;
  signal uti : tile_cached_in_type;
  

  component AxiBridge is port (
    clk   : in  std_logic;
    nrst  : in  std_logic;

    --! Tile-to-AXI direction
    tloi : in tile_cached_out_type;
    msto : out nasti_master_out_type;
    --! AXI-to-Tile direction
    msti : in nasti_master_in_type;
    tlio : out tile_cached_in_type
  );
  end component;

	COMPONENT RocketTile
	PORT(
		clock : IN std_logic;
		reset : IN std_logic;
		io_cached_0_acquire_ready : IN std_logic;
		io_cached_0_acquire_valid : OUT std_logic;
		io_cached_0_acquire_bits_addr_block : OUT std_logic_vector(25 downto 0);
		io_cached_0_acquire_bits_client_xact_id : OUT std_logic_vector(1 downto 0);
		io_cached_0_acquire_bits_addr_beat : OUT std_logic_vector(2 downto 0);-- was 1
		io_cached_0_acquire_bits_is_builtin_type : OUT std_logic;
		io_cached_0_acquire_bits_a_type : OUT std_logic_vector(2 downto 0);
		io_cached_0_acquire_bits_union : OUT std_logic_vector(10 downto 0);
		io_cached_0_acquire_bits_data : OUT std_logic_vector(63 downto 0);--was 127
		io_cached_0_probe_ready : OUT std_logic;
		io_cached_0_probe_valid : IN std_logic;
		io_cached_0_probe_bits_addr_block : IN std_logic_vector(25 downto 0);
		io_cached_0_probe_bits_p_type : IN std_logic_vector(1 downto 0);
		io_cached_0_release_ready : IN std_logic;
		io_cached_0_release_valid : OUT std_logic;
		io_cached_0_release_bits_addr_beat : OUT std_logic_vector(2 downto 0);--was 1
		io_cached_0_release_bits_addr_block : OUT std_logic_vector(25 downto 0);
		io_cached_0_release_bits_client_xact_id : OUT std_logic_vector(1 downto 0);
		io_cached_0_release_bits_voluntary : OUT std_logic;
		io_cached_0_release_bits_r_type : OUT std_logic_vector(2 downto 0);
		io_cached_0_release_bits_data : OUT std_logic_vector(63 downto 0);-- was 127
		io_cached_0_grant_ready : OUT std_logic;
		io_cached_0_grant_valid : IN std_logic;
		io_cached_0_grant_bits_addr_beat : IN std_logic_vector(2 downto 0);--was 1
		io_cached_0_grant_bits_client_xact_id : IN std_logic_vector(1 downto 0);
		io_cached_0_grant_bits_manager_xact_id : IN std_logic_vector(3 downto 0);
		io_cached_0_grant_bits_is_builtin_type : IN std_logic;
		io_cached_0_grant_bits_g_type : IN std_logic_vector(3 downto 0);
		io_cached_0_grant_bits_data : IN std_logic_vector(63 downto 0);--was 127
		io_cached_0_grant_bits_manager_id : IN std_logic;--new signal
		io_cached_0_finish_ready : IN std_logic;--new signal
    io_cached_0_finish_valid : OUT std_logic;--new signal
    io_cached_0_finish_bits_manager_xact_id : OUT std_logic_vector(3 downto 0);--new signal
    io_cached_0_finish_bits_manager_id : OUT std_logic;--new signal
		io_uncached_0_acquire_ready : IN std_logic;
		io_uncached_0_acquire_valid : OUT std_logic;
		io_uncached_0_acquire_bits_addr_block : OUT std_logic_vector(25 downto 0);
		io_uncached_0_acquire_bits_client_xact_id : OUT std_logic_vector(1 downto 0);
		io_uncached_0_acquire_bits_addr_beat : OUT std_logic_vector(2 downto 0);-- was 1
		io_uncached_0_acquire_bits_is_builtin_type : OUT std_logic;
		io_uncached_0_acquire_bits_a_type : OUT std_logic_vector(2 downto 0);
		io_uncached_0_acquire_bits_union : OUT std_logic_vector(10 downto 0);
		io_uncached_0_acquire_bits_data : OUT std_logic_vector(63 downto 0);--was 127
		io_uncached_0_grant_ready : OUT std_logic;
		io_uncached_0_grant_valid : IN std_logic;
		io_uncached_0_grant_bits_addr_beat : IN std_logic_vector(2 downto 0);--was 1
		io_uncached_0_grant_bits_client_xact_id : IN std_logic_vector(1 downto 0);
		io_uncached_0_grant_bits_manager_xact_id : IN std_logic_vector(3 downto 0);
		io_uncached_0_grant_bits_is_builtin_type : IN std_logic;
		io_uncached_0_grant_bits_g_type : IN std_logic_vector(3 downto 0);
		io_uncached_0_grant_bits_data : IN std_logic_vector(63 downto 0);--was 127
		io_hartid : IN std_logic_vector(63 downto 0);
    io_interrupts_debug : IN std_logic;
    io_interrupts_mtip : IN std_logic;
    io_interrupts_msip : IN std_logic;
    io_interrupts_meip : IN std_logic;
    io_interrupts_seip : IN std_logic;
    io_resetVector : IN std_logic_vector(63 downto 0)
		);
	END COMPONENT;

begin

  mstcfg1 <= xmstconfig1;
  mstcfg2 <= xmstconfig2;
  cpu_rst <= not nrst;
   
	inst_tile: RocketTile PORT MAP(
		clock => clk_sys,
		reset => cpu_rst,
		io_cached_0_acquire_ready => cti.acquire_ready,
		io_cached_0_acquire_valid => cto.acquire_valid,
		io_cached_0_acquire_bits_addr_block => cto.acquire_bits_addr_block,
		io_cached_0_acquire_bits_client_xact_id => cto.acquire_bits_client_xact_id,
		io_cached_0_acquire_bits_addr_beat => cto.acquire_bits_addr_beat,
		io_cached_0_acquire_bits_is_builtin_type => cto.acquire_bits_is_builtin_type,
		io_cached_0_acquire_bits_a_type => cto.acquire_bits_a_type,
		io_cached_0_acquire_bits_union => cto.acquire_bits_union,
		io_cached_0_acquire_bits_data => cto.acquire_bits_data,
		io_cached_0_grant_ready => cto.grant_ready,
		io_cached_0_grant_valid => cti.grant_valid,
		io_cached_0_grant_bits_addr_beat => cti.grant_bits_addr_beat,
		io_cached_0_grant_bits_client_xact_id => cti.grant_bits_client_xact_id,
		io_cached_0_grant_bits_manager_xact_id => cti.grant_bits_manager_xact_id,
		io_cached_0_grant_bits_is_builtin_type => cti.grant_bits_is_builtin_type,
		io_cached_0_grant_bits_g_type => cti.grant_bits_g_type,
		io_cached_0_grant_bits_data => cti.grant_bits_data,
		io_cached_0_probe_ready => cto.probe_ready,
		io_cached_0_probe_valid => cti.probe_valid,
		io_cached_0_probe_bits_addr_block => cti.probe_bits_addr_block,
		io_cached_0_probe_bits_p_type => cti.probe_bits_p_type,
		io_cached_0_release_ready => cti.release_ready,
		io_cached_0_grant_bits_manager_id => cti.grant_bits_manager_id,--new signal
    io_cached_0_finish_ready => cti.finish_ready, --new signal
		io_cached_0_release_valid => cto.release_valid,
		io_cached_0_release_bits_addr_beat => cto.release_bits_addr_beat,
		io_cached_0_release_bits_addr_block => cto.release_bits_addr_block,
		io_cached_0_release_bits_client_xact_id => cto.release_bits_client_xact_id,
		io_cached_0_release_bits_voluntary => cto.release_bits_voluntary,
		io_cached_0_release_bits_r_type => cto.release_bits_r_type,
		io_cached_0_release_bits_data => cto.release_bits_data,
    io_cached_0_finish_valid => cto.finish_valid,--new signal
    io_cached_0_finish_bits_manager_xact_id => cto.finish_bits_manager_xact_id,--new signal
    io_cached_0_finish_bits_manager_id => cto.finish_bits_manager_id, --new signal
		io_uncached_0_acquire_ready => uti.acquire_ready,
		io_uncached_0_acquire_valid => uto.acquire_valid,
		io_uncached_0_acquire_bits_addr_block => uto.acquire_bits_addr_block,
		io_uncached_0_acquire_bits_client_xact_id => uto.acquire_bits_client_xact_id,
		io_uncached_0_acquire_bits_addr_beat => uto.acquire_bits_addr_beat,
		io_uncached_0_acquire_bits_is_builtin_type => uto.acquire_bits_is_builtin_type,
		io_uncached_0_acquire_bits_a_type => uto.acquire_bits_a_type,
		io_uncached_0_acquire_bits_union => uto.acquire_bits_union,
		io_uncached_0_acquire_bits_data => uto.acquire_bits_data,
		io_uncached_0_grant_ready => uto.grant_ready,
		io_uncached_0_grant_valid => uti.grant_valid,
		io_uncached_0_grant_bits_addr_beat => uti.grant_bits_addr_beat,
		io_uncached_0_grant_bits_client_xact_id => uti.grant_bits_client_xact_id,
		io_uncached_0_grant_bits_manager_xact_id => uti.grant_bits_manager_xact_id,
		io_uncached_0_grant_bits_is_builtin_type => uti.grant_bits_is_builtin_type,
		io_uncached_0_grant_bits_g_type => uti.grant_bits_g_type,
		io_uncached_0_grant_bits_data => uti.grant_bits_data,
		io_hartid => CFG_HARTID,
    io_interrupts_debug  => interrupts(CFG_CORE_IRQ_DEBUG),
    io_interrupts_mtip  => interrupts(CFG_CORE_IRQ_MTIP),
    io_interrupts_msip  => interrupts(CFG_CORE_IRQ_MSIP),
    io_interrupts_meip  => interrupts(CFG_CORE_IRQ_MEIP),
    io_interrupts_seip  => interrupts(CFG_CORE_IRQ_SEIP),
    io_resetVector => CFG_RESET_VECTOR
	);
 
  cbridge0 : AxiBridge  port map (
    clk => clk_sys,
    nrst => nrst,
    --! Tile-to-AXI direction
    tloi => cto,
    msto => msto1,
    --! AXI-to-Tile direction
    msti => msti1,
    tlio => cti
  );

  ubridge0 : AxiBridge port map (
    clk => clk_sys,
    nrst => nrst,
    --! Tile-to-AXI direction
    tloi => uto,
    msto => msto2,
    --! AXI-to-Tile direction
    msti => msti2,
    tlio => uti
  );

end arch_rocket_l1only;
