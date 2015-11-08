-----------------------------------------------------------------------------
--! @file
--! @copyright  Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author     Sergey Khabarov - sergeykhbr@gmail.com
--! @brief	Package for common VHDL functions
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package types_common is


type log2arr is array(0 to 512) of integer;

constant log2   : log2arr := (
0,0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  others => 9);

constant log2x  : log2arr := (
0,1,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
  others => 9);


function "-" (d : std_logic_vector; i : integer) return std_logic_vector;
function "+" (d : std_logic_vector; i : integer) return std_logic_vector;

function conv_integer(v : std_logic_vector) return integer;
function conv_integer(v : std_logic) return integer;
function conv_std_logic_vector(i : integer; w : integer) return std_logic_vector;
function conv_std_logic_vector_signed(i : integer; w : integer) return std_logic_vector;
function conv_std_logic(b : boolean) return std_ulogic;

end;


package body types_common is


function conv_integer(v : std_logic_vector) return integer is
begin
  if not is_x(v) then return(to_integer(unsigned(v)));
  else return(0); end if;
end;

function conv_integer(v : std_logic) return integer is
begin
  if not is_x(v) then
    if v = '1' then return(1);
    else return(0); end if;
  else return(0); end if;
end;

function conv_std_logic_vector(i : integer; w : integer) return std_logic_vector is
variable tmp : std_logic_vector(w-1 downto 0);
begin
  tmp := std_logic_vector(to_unsigned(i, w));
  return(tmp);
end;

function conv_std_logic_vector_signed(i : integer; w : integer) return std_logic_vector is
variable tmp : std_logic_vector(w-1 downto 0);
begin
  tmp := std_logic_vector(to_signed(i, w));
  return(tmp);
end;

function conv_std_logic(b : boolean) return std_ulogic is
begin
  if b then return('1'); else return('0'); end if;
end;

function "+" (d : std_logic_vector; i : integer) return std_logic_vector is
variable x : std_logic_vector(d'length-1 downto 0);
begin
-- pragma translate_off
  if not is_x(d) then
-- pragma translate_on
    return(std_logic_vector(unsigned(d) + i));
-- pragma translate_off
  else x := (others =>'X'); return(x);
  end if;
-- pragma translate_on
end;

function "-" (d : std_logic_vector; i : integer) return std_logic_vector is
variable x : std_logic_vector(d'length-1 downto 0);
begin
-- pragma translate_off
  if not is_x(d) then
-- pragma translate_on
    return(std_logic_vector(unsigned(d) - i));
-- pragma translate_off
  else x := (others =>'X'); return(x); 
  end if;
-- pragma translate_on
end;


end;

