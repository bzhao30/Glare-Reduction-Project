library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Brightspot is
    Port (
        clk         : in  STD_LOGIC;
        vsync       : in  STD_LOGIC;  -- Vertical sync from the camera module
        href        : in  STD_LOGIC;  -- Horizontal reference from the camera module
        we_reg      : in  STD_LOGIC;  -- Write enable signal from the camera module
        addrb       : in  STD_LOGIC_VECTOR(14 downto 0); 
        doutb       : in  STD_LOGIC_VECTOR(3 downto 0);
        brightspot_en : out std_logic;
        avg_x       : out integer;
        avg_y       : out integer;
        brightspot_done : out std_logic
    );
end Brightspot;

architecture Behavioral of Brightspot is
    signal x_sum        : unsigned(15 downto 0) := (others => '0');
    signal y_sum        : unsigned(15 downto 0) := (others => '0');
    signal white_count  : unsigned(15 downto 0) := (others => '0');
    signal current_addr : std_logic_vector(14 downto 0) := (others => '0');
    type statetype is (init, read, calc, assess, done);
    signal cs, ns       : statetype := init;
    signal rst, calcen  : std_logic := '0';
    signal brightspot_en_sig : std_logic := '1';
    signal xsig         : integer := 80;
    signal ysig         : integer := -60;
    signal href_count   : integer := 0;
begin
    brightspot_en <= brightspot_en_sig;

    -- Coordinate calculation based on address
    process(clk)
    variable x_coord : unsigned(14 downto 0);
    variable y_coord : unsigned(6 downto 0);
    begin
        if rising_edge(clk) then
            if vsync = '1' then
                -- Reset all sums and counters at the start of a new frame
                x_sum <= (others => '0');
                y_sum <= (others => '0');
                white_count <= (others => '0');
            elsif we_reg = '1' and href = '1' then
                -- Capture pixel data when we_reg is asserted and href is active
                x_coord := unsigned(addrb) mod 160;    -- X-coordinate (8 bits)
                y_coord := unsigned(addrb(14 downto 8));   -- Y-coordinate (7 bits)

                if doutb >= "1100" then  -- Broaden threshold for testing
                    x_sum <= x_sum + ("0" & x_coord);
                    y_sum <= y_sum + ("000000000" & y_coord);
                    white_count <= white_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Calculate average position at the end of the frame
    process(clk)
    begin
        if rising_edge(clk) then
            if vsync = '0' and calcen = '1' then  -- Calculate when not in vertical sync and calcen is set
                if white_count > "0000000000001000" then
                    xsig <= to_integer((x_sum + (white_count / 2)) / white_count);
                    ysig <= to_integer((y_sum + (white_count / 2)) / white_count);
                else
                end if;
            end if;
        end if;
    end process;
    
    
    process(href)
    begin
    if falling_edge(href) then
        if white_count > "0000000000001000" then
            brightspot_en_sig <= '1';
            href_count <= 0;
        else
            href_count <= href_count + 1;
            if href_count = 2000 then
                href_count <= 0;
                brightspot_en_sig <= '1'; 
            end if;
        end if;
    end if;
    end process;     
        

    -- Output average coordinates
    avg_x <= xsig;
    avg_y <= ysig;

    -- State machine to control calculation and reset
    stateupdate : process(clk)
    begin
        if rising_edge(clk) then
            cs <= ns;
        end if;
    end process;

    nextstate: process(cs, vsync)
    begin
        rst <= '0';
        calcen <= '0';
        brightspot_done <= '0';

        case cs is
            when init =>
                rst <= '1';
                if vsync = '0' then  -- Start reading when not in vertical sync
                    ns <= read;
                end if;
            when read =>
                if vsync = '1' then  -- Move to calc state at the start of vertical sync
                    ns <= calc;
                end if;
            when calc =>
                calcen <= '1';
                ns <= done;
            when done => 
                brightspot_done <= '1';
                ns <= init;
                
            when others =>
                ns <= init;
        end case;
    end process;
end Behavioral;
