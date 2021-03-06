-----------------------------------------------------------------------------
--! @file
--! @copyright Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author    Sergey Khabarov - sergeykhbr@gmail.com
--! @brief     Interrupt controller with the AXI4 interface
--! @details   This module generates CPU interrupt emitting write message into
--!            CSR register 'send_ipi' via HostIO bus interface.
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library commonlib;
use commonlib.types_common.all;
--! AMBA system bus specific library.
library ambalib;
--! AXI4 configuration constants.
use ambalib.types_amba4.all;
--! RISCV specific funcionality.
library rocketlib;
use rocketlib.types_rocket.all;

entity nasti_irqctrl is
  generic (
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#
  );
  port 
 (
    clk    : in std_logic;
    nrst   : in std_logic;
    i_irqs : in std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);
    o_cfg  : out nasti_slave_config_type;
    i_axi  : in nasti_slave_in_type;
    o_axi  : out nasti_slave_out_type;
    o_irq_meip : out std_logic
  );
end;

architecture nasti_irqctrl_rtl of nasti_irqctrl is

  constant xconfig : nasti_slave_config_type := (
     descrtype => PNP_CFG_TYPE_SLAVE,
     descrsize => PNP_CFG_SLAVE_DESCR_BYTES,
     irq_idx => 0,
     xaddr => conv_std_logic_vector(xaddr, CFG_NASTI_CFG_ADDR_BITS),
     xmask => conv_std_logic_vector(xmask, CFG_NASTI_CFG_ADDR_BITS),
     vid => VENDOR_GNSSSENSOR,
     did => GNSSSENSOR_IRQCTRL
  );

  type local_addr_array_type is array (0 to CFG_WORDS_ON_BUS-1) 
       of integer;
       
  constant IRQ_ZERO : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1) := (others => '0');


type registers is record
  bank_axi : nasti_slave_bank_type;
  
  --! interrupt signal delay signal to detect interrupt positive edge
  irqs_z        : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);  
  irqs_zz       : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);  

  --! mask irq disabled: 1=disabled; 0=enabled
  irqs_mask     : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);
  --! irq pending bit mask
  irqs_pending  : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);
  --! interrupt handler address initialized by FW:
  isr_table     : std_logic_vector(63 downto 0);
  --! hold-on generation of interrupt.
  irq_lock      : std_logic;
  --! delayed interrupt
  irq_wait_unlock : std_logic_vector(CFG_IRQ_TOTAL-1 downto 1);
  irq_cause_idx : std_logic_vector(31 downto 0);
  --! Function trap_entry copies the values of CSRs into these two regs:
  dbg_cause    : std_logic_vector(63 downto 0);
  dbg_epc      : std_logic_vector(63 downto 0);
end record;

signal r, rin: registers;
begin

  comblogic : process(i_irqs, i_axi, r)
    variable v : registers;
    variable raddr_reg : local_addr_array_type;
    variable waddr_reg : local_addr_array_type;
    variable rdata : std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
    variable tmp : std_logic_vector(31 downto 0);
    variable wstrb : std_logic_vector(CFG_ALIGN_BYTES-1 downto 0);

    variable w_generate_ipi : std_logic;
  begin
    v := r;
    w_generate_ipi := '0';

    procedureAxi4(i_axi, xconfig, r.bank_axi, v.bank_axi);

    for n in 0 to CFG_WORDS_ON_BUS-1 loop
       raddr_reg(n) := conv_integer(r.bank_axi.raddr(n)(11 downto 2));
       tmp := (others => '0');
       case raddr_reg(n) is
         when 0      => tmp(CFG_IRQ_TOTAL-1 downto 1) := r.irqs_mask;     --! [RW]: 1=irq disable; 0=enable
         when 1      => tmp(CFG_IRQ_TOTAL-1 downto 1) := r.irqs_pending;  --! [RO]: Rised interrupts.
         when 2      => tmp := (others => '0');                           --! [WO]: Clear interrupts mask.
         when 3      => tmp := (others => '0');                           --! [WO]: Rise interrupts mask.
         when 4      => tmp := r.isr_table(31 downto 0);                  --! [RW]: LSB of the function address
         when 5      => tmp := r.isr_table(63 downto 32);                 --! [RW]: MSB of the function address
         when 6      => tmp := r.dbg_cause(31 downto 0);                  --! [RW]: Cause of the interrupt
         when 7      => tmp := r.dbg_cause(63 downto 32);                 --! [RW]: 
         when 8      => tmp := r.dbg_epc(31 downto 0);                    --! [RW]: Instruction pointer
         when 9      => tmp := r.dbg_epc(63 downto 32);                   --! [RW]: 
         when 10     => tmp(0) := r.irq_lock;
         when 11     => tmp := r.irq_cause_idx;
         when others =>
       end case;
       rdata(8*CFG_ALIGN_BYTES*(n+1)-1 downto 8*CFG_ALIGN_BYTES*n) := tmp;
    end loop;

    if i_axi.w_valid = '1' and 
       r.bank_axi.wstate = wtrans and 
       r.bank_axi.wresp = NASTI_RESP_OKAY then

      for n in 0 to CFG_WORDS_ON_BUS-1 loop
         waddr_reg(n) := conv_integer(r.bank_axi.waddr(n)(11 downto 2));
         tmp := i_axi.w_data(32*(n+1)-1 downto 32*n);
         wstrb := i_axi.w_strb(CFG_ALIGN_BYTES*(n+1)-1 downto CFG_ALIGN_BYTES*n);

         if conv_integer(wstrb) /= 0 then
           case waddr_reg(n) is
             when 0 => v.irqs_mask := tmp(CFG_IRQ_TOTAL-1 downto 1);
             when 1 =>     --! Read only
             when 2 => 
                v.irqs_pending := r.irqs_pending and (not tmp(CFG_IRQ_TOTAL-1 downto 1));
             when 3 => 
                w_generate_ipi := '1';
                v.irqs_pending := (not r.irqs_mask) and tmp(CFG_IRQ_TOTAL-1 downto 1);
             when 4 => v.isr_table(31 downto 0) := tmp;
             when 5 => v.isr_table(63 downto 32) := tmp;
             when 6 => v.dbg_cause(31 downto 0) := tmp;
             when 7 => v.dbg_cause(63 downto 32) := tmp;
             when 8 => v.dbg_epc(31 downto 0) := tmp;
             when 9 => v.dbg_epc(63 downto 32) := tmp;
             when 10 => v.irq_lock := tmp(0);
             when 11 => v.irq_cause_idx := tmp;
             when others =>
           end case;
         end if;
      end loop;
    end if;

    v.irqs_z := i_irqs;
    v.irqs_zz := r.irqs_z;
    for n in 1 to CFG_IRQ_TOTAL-1 loop
      if (r.irqs_z(n) = '1' and r.irqs_zz(n) = '0') or r.irq_wait_unlock(n) = '1' then
         if r.irq_lock = '0' then
             v.irq_wait_unlock(n) := '0';
             v.irqs_pending(n) := not r.irqs_mask(n);
             w_generate_ipi := w_generate_ipi or (not r.irqs_mask(n));
         else
             v.irq_wait_unlock(n) := '1';
         end if;
      end if;
    end loop;


    o_axi <= functionAxi4Output(r.bank_axi, rdata);
    if r.irqs_pending = IRQ_ZERO then
      o_irq_meip <= '0';
    else
      o_irq_meip <= '1';
    end if;

    rin <= v;
  end process;

  o_cfg  <= xconfig;


  -- registers:
  regs : process(clk, nrst)
  begin 
    if nrst = '0' then 
       r.bank_axi <= NASTI_SLAVE_BANK_RESET;
       r.irqs_mask <= (others => '1'); -- all interrupts disabled
       r.irqs_pending <= (others => '0');
       r.irqs_z <= (others => '0');
       r.irqs_zz <= (others => '0');
       r.isr_table <= (others => '0');
       r.irq_lock <= '0';
       r.irq_wait_unlock <= (others => '0');
       r.irq_cause_idx <= (others => '0');
       r.dbg_cause <= (others => '0');
       r.dbg_epc <= (others => '0');
    elsif rising_edge(clk) then 
       r <= rin; 
    end if; 
  end process;
end;
