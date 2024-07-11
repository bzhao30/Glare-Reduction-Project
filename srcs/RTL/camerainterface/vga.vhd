----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity VGA is
    Port ( CLK25 : in  STD_LOGIC;                                    -- 25 MHz input clock
           clkout : out  STD_LOGIC;                                  -- Output clock to the ADV7123 and TFT screen
           Hsync, Vsync : out  STD_LOGIC;                            -- Horizontal and vertical sync signals for the VGA screen
           Nblank : out  STD_LOGIC;                                  -- Control signal for the D/A converter ADV7123
           activeArea : out  STD_LOGIC;
           Nsync : out  STD_LOGIC);                                  -- Sync and control signals for the TFT screen
end VGA;

architecture Behavioral of VGA is
signal Hcnt: STD_LOGIC_VECTOR(9 downto 0) := "0000000000";           -- Column counter
signal Vcnt: STD_LOGIC_VECTOR(9 downto 0) := "1000001000";           -- Row counter
signal video: STD_LOGIC := '0';
constant HM: integer :=799;                                          -- Maximum horizontal size considered 800
constant HD: integer :=640;                                          -- Screen width (horizontal)
constant HF: integer :=16;                                           -- Front porch
constant HB: integer :=48;                                           -- Back porch
constant HR: integer :=96;                                           -- Sync time
constant VM: integer :=524;                                          -- Maximum vertical size considered 525
constant VD: integer :=480;                                          -- Screen height (vertical)
constant VF: integer :=10;                                           -- Front porch
constant VB: integer :=33;                                           -- Back porch
constant VR: integer :=2;                                            -- Retrace

begin

-- Initializing a counter from 0 to 799 (800 pixels per line):
-- Incrementing the column counter at each clock edge,
-- i.e., from 0 to 799.
    process(CLK25)
        begin
            if (CLK25'event and CLK25='1') then
                if (Hcnt = HM) then
                    Hcnt <= "0000000000";
                    if (Vcnt = VM) then
                        Vcnt <= "0000000000";
                        activeArea <= '1';
                    else
                        if Vcnt < 12-1 then
                            activeArea <= '1';
                        end if;
                        Vcnt <= Vcnt + 1;
                    end if;
                else
                    if Hcnt = 16-1 then
                        activeArea <= '0';
                    end if;
                    Hcnt <= Hcnt + 1;
                end if;
            end if;
        end process;
----------------------------------------------------------------

-- Generating the horizontal sync signal Hsync:
    process(CLK25)
        begin
            if (CLK25'event and CLK25='1') then
                if (Hcnt >= (HD + HF) and Hcnt <= (HD + HF + HR - 1)) then   --- Hcnt >= 32 and Hcnt <= 127
                    Hsync <= '0';
                else
                    Hsync <= '1';
                end if;
            end if;
        end process;
----------------------------------------------------------------

-- Generating the vertical sync signal Vsync:
    process(CLK25)
        begin
            if (CLK25'event and CLK25='1') then
                if (Vcnt >= (VD + VF) and Vcnt <= (VD + VF + VR - 1)) then  --- Vcnt >= 22 and Vcnt <= 23
                    Vsync <= '0';
                else
                    Vsync <= '1';
                end if;
            end if;
        end process;
----------------------------------------------------------------

-- Nblank and Nsync to control the converter ADV7123:
Nsync <= '1';
video <= '1' when (Hcnt < HD) and (Vcnt < VD)            -- This is to use the full 16 x 12 resolution
          else '0';
Nblank <= video;
clkout <= CLK25;

end Behavioral;
