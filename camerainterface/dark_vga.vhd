library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dark_vga is
    Port (
        clk       : in  STD_LOGIC;
        x_blocker : in integer;
        y_blocker : in integer;
        brightspot_en : in std_logic;
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        red       : out STD_LOGIC_VECTOR(3 downto 0);
        green     : out STD_LOGIC_VECTOR(3 downto 0);
        blue      : out STD_LOGIC_VECTOR(3 downto 0)
    );
end dark_vga;

architecture Behavioral of dark_vga is
    -- VGA Timing Constants for 640x480 @ 60 Hz with 25.175 MHz clock
    constant H_ACTIVE       : integer := 640;
    constant H_FRONT_PORCH  : integer := 16;
    constant H_SYNC_PULSE   : integer := 96;
    constant H_BACK_PORCH   : integer := 48;
    constant H_TOTAL        : integer := H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

    constant V_ACTIVE       : integer := 480;
    constant V_FRONT_PORCH  : integer := 10;
    constant V_SYNC_PULSE   : integer := 2;
    constant V_BACK_PORCH   : integer := 33;
    constant V_TOTAL        : integer := V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    signal h_counter        : integer range 0 to H_TOTAL - 1 := 0;
    signal v_counter        : integer range 0 to V_TOTAL - 1 := 0;
    signal h_sync           : STD_LOGIC := '1';
    signal v_sync           : STD_LOGIC := '1';

    -- Circle parameters
    signal circle_center_x  : integer := H_ACTIVE / 2;
    signal circle_center_y  : integer := V_ACTIVE / 2;
    constant OUTER_CIRCLE_RADIUS : integer := 60;
    constant INNER_CIRCLE_RADIUS : integer := 40;

    signal outer_circle_on  : STD_LOGIC := '0';
    signal inner_circle_on  : STD_LOGIC := '0';

    -- Horizontal and vertical shift amounts
    constant H_SHIFT        : integer := 145;
    constant V_SHIFT        : integer := 34;

    -- Registered color signals
    signal red_reg   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal green_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal blue_reg  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    -- Compute circle centers in the clocked process
    process(clk)
    begin
        if rising_edge(clk) then
            circle_center_x <= H_ACTIVE / 2 + x_blocker * 2;
            --circle_center_y <= V_ACTIVE / 2 + y_blocker;
            circle_center_y <= V_ACTIVE / 2 + y_blocker;            
        end if;
    end process;

    -- Generate H_SYNC and V_SYNC signals
    process(clk)
    begin
        if rising_edge(clk) then
            if h_counter = H_TOTAL - 1 then
                h_counter <= 0;
                if v_counter = V_TOTAL - 1 then
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
                end if;
            else
                h_counter <= h_counter + 1;
            end if;

            -- Horizontal Sync
            if h_counter < H_SYNC_PULSE then
                h_sync <= '0';
            else
                h_sync <= '1';
            end if;

            -- Vertical Sync
            if v_counter < V_SYNC_PULSE then
                v_sync <= '0';
            else
                v_sync <= '1';
            end if;
        end if;
    end process;

    hsync <= h_sync;
    vsync <= v_sync;

    -- Circle drawing logic
    process(clk)
    begin
        if rising_edge(clk) then
            if h_counter >= H_SHIFT and h_counter < (H_ACTIVE + H_SHIFT) and 
               v_counter >= V_SHIFT and v_counter < (V_ACTIVE + V_SHIFT) then
                -- Calculate the distance from the center of the circles
                outer_circle_on <= '0';
                inner_circle_on <= '0';
                
                
                if brightspot_en = '1' then
                    if ((h_counter - H_SHIFT - circle_center_x) * (h_counter - H_SHIFT - circle_center_x) +
                        (v_counter - V_SHIFT - circle_center_y) * (v_counter - V_SHIFT - circle_center_y)) < (OUTER_CIRCLE_RADIUS * OUTER_CIRCLE_RADIUS) then
                        outer_circle_on <= '1';
                    end if;
    
                    if ((h_counter - H_SHIFT - circle_center_x) * (h_counter - H_SHIFT - circle_center_x) +
                        (v_counter - V_SHIFT - circle_center_y) * (v_counter - V_SHIFT - circle_center_y)) < (INNER_CIRCLE_RADIUS * INNER_CIRCLE_RADIUS) then
                        inner_circle_on <= '1';
                    end if;
                else
                    outer_circle_on <= '0';
                    inner_circle_on <= '0';
                        
                end if;
                
                
            else
                outer_circle_on <= '0';  -- Ensure outer_circle_on is reset outside active area
                inner_circle_on <= '0';  -- Ensure inner_circle_on is reset outside active area
            end if;
        end if;
    end process;

    -- Set pixel color based on the circle condition
    process(clk)
    begin
        if rising_edge(clk) then
            if h_counter >= H_SHIFT and h_counter < (H_ACTIVE + H_SHIFT) and 
               v_counter >= V_SHIFT and v_counter < (V_ACTIVE + V_SHIFT) then
                if inner_circle_on = '1' then
                    red_reg   <= "1010"; -- Darker color for the inner circle
                    green_reg <= "1010";
                    blue_reg  <= "1010";
                elsif outer_circle_on = '1' then
                    red_reg   <= "1100"; -- Lighter color for the outer circle
                    green_reg <= "1100";
                    blue_reg  <= "1100";
                else
                    red_reg   <= "1111"; -- White for the background
                    green_reg <= "1111";
                    blue_reg  <= "1111";
                end if;
            else
                -- Outside active area, set to black
                red_reg   <= "0000";
                green_reg <= "0000";
                blue_reg  <= "0000";
            end if;
        end if;
    end process;

    -- Assign registered colors to output
    red   <= red_reg;
    green <= green_reg;
    blue  <= blue_reg;

end Behavioral;
