
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity StereoCam is
    Port ( clk100          : in  STD_LOGIC;
           RxExtPort        : in std_logic;
           btnl            : in  STD_LOGIC;
           btnc            : in  STD_LOGIC;
           btnr            : in  STD_LOGIC;
           config_finished_l : out STD_LOGIC;
           config_finished_r : out STD_LOGIC;
           
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_r     : out  STD_LOGIC_vector(3 downto 0);
           vga_g     : out  STD_LOGIC_vector(3 downto 0);
           vga_b     : out  STD_LOGIC_vector(3 downto 0);
           
           ov7670_pclk_l  : in  STD_LOGIC;
           ov7670_xclk_l  : out STD_LOGIC;
           ov7670_vsync_l : in  STD_LOGIC;
           ov7670_href_l  : in  STD_LOGIC;
           ov7670_data_l  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc_l  : out STD_LOGIC;
           ov7670_siod_l  : inout STD_LOGIC;
           ov7670_pwdn_l  : out STD_LOGIC;
           ov7670_reset_l : out STD_LOGIC;
           
           ov7670_pclk_r  : in  STD_LOGIC;
           ov7670_xclk_r  : out STD_LOGIC;
           ov7670_vsync_r : in  STD_LOGIC;
           ov7670_href_r  : in  STD_LOGIC;
           ov7670_data_r  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc_r  : out STD_LOGIC;
           ov7670_siod_r  : inout STD_LOGIC;
           ov7670_pwdn_r  : out STD_LOGIC;
           ov7670_reset_r : out STD_LOGIC
           );
end StereoCam;

architecture Behavioral of StereoCam is

    -- dark spot output vga
    component dark_vga
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
    end component;
    
    
    -- camera output vga
	COMPONENT VGA
	PORT(
		CLK25 : IN std_logic;    
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		Hsync : OUT std_logic;
		Vsync : OUT std_logic;
		Nblank : OUT std_logic;      
		clkout : OUT std_logic;
		activeArea : OUT std_logic;
		Nsync : OUT std_logic
		);
	END COMPONENT;

	COMPONENT ov7670_controller
	PORT(
		clk : IN std_logic;
		resend : IN std_logic;    
		siod : INOUT std_logic;      
		config_finished : OUT std_logic;
		sioc : OUT std_logic;
		reset : OUT std_logic;
		pwdn : OUT std_logic;
		xclk : OUT std_logic
		);
	END COMPONENT;
	
    COMPONENT brightspot
    Port (
        clk         : in  STD_LOGIC;
        vsync       : in  STD_LOGIC;  -- Vertical sync from the camera module
        href        : in  STD_LOGIC;  -- Horizontal reference from the camera module
        we_reg      : in  STD_LOGIC;  -- Write enable signal from the camera module
        addrb       : in  STD_LOGIC_VECTOR(14 downto 0); 
        doutb       : in  STD_LOGIC_VECTOR(3 downto 0);
        avg_x       : out integer;
        brightspot_en : out std_logic;
        avg_y       : out integer
    );
    end component;
    
    component lightblocker
    port(
    clk : in std_logic;
    en : in std_logic;
    x_l : in integer;
    x_r : in integer;
    y_l : in integer;
    y_r : in integer;
    x_rpi : in integer;
    y_rpi : in integer;
    x_blocker : out integer;
    y_blocker : out integer);
    end component;	
    
    COMPONENT receiver
    port(
    Rx : in std_logic;
    clk : in std_logic;
    x_rpi : out integer;
    y_rpi : out integer;
    rpi_done : out std_logic);
    end component;

	COMPONENT debounce
	PORT(
		clk : IN std_logic;
		i : IN std_logic;          
		o : OUT std_logic
		);
	END COMPONENT;

	COMPONENT frame_buffer
  PORT (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      clkb : IN STD_LOGIC;
      enb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
	END COMPONENT;

	COMPONENT ov7670_capture
	PORT(
--      rez_160x120 : IN std_logic;
--      rez_320x240 : IN std_logic;
		pclk : IN std_logic;
		vsync : IN std_logic;
		href : IN std_logic;
		d : IN std_logic_vector(7 downto 0);          
		addr : OUT std_logic_vector(14 downto 0);
		dout : OUT std_logic_vector(11 downto 0);
		we : OUT std_logic
		);
	END COMPONENT;

	COMPONENT RGB
	PORT(
		Din_l : IN std_logic_vector(3 downto 0);
		Din_r : IN std_logic_vector(3 downto 0);
		Nblank : IN std_logic;          
		R : OUT std_logic_vector(7 downto 0);
		G : OUT std_logic_vector(7 downto 0);
		B : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	component clocking
	port (
    CLK_100         : in     std_logic;
    -- Clock out ports
    CLK_50          : out    std_logic;
    CLK_25          : out    std_logic);
	end component;
	 

	COMPONENT Address_Generator
	PORT(
		CLK25       : IN  std_logic;
--      rez_160x120 : IN std_logic;
--      rez_320x240 : IN std_logic;
		enable      : IN  std_logic;       
      vsync       : in  STD_LOGIC;
		address     : OUT std_logic_vector(14 downto 0)
		);
	END COMPONENT;



   signal clk_camera : std_logic;
   signal clk_vga    : std_logic;
   signal wren_l,wren_r       : std_logic_vector(0 downto 0);
   signal resend     : std_logic;
   signal nBlank     : std_logic;
   signal vSync      : std_logic;
   signal nSync      : std_logic;
   
   signal wraddress_l  : std_logic_vector(14 downto 0);
   signal wrdata_l     : std_logic_vector(11 downto 0);
   signal wraddress_r  : std_logic_vector(14 downto 0);
   signal wrdata_r     : std_logic_vector(11 downto 0);
   
   signal rdaddress_l  : std_logic_vector(14 downto 0);
   signal rddata_l     : std_logic_vector(3 downto 0);
   signal rdaddress_r  : std_logic_vector(14 downto 0);
   signal rddata_r     : std_logic_vector(3 downto 0);
   
   signal red,green,blue : std_logic_vector(7 downto 0);
   signal activeArea : std_logic;
   
   signal rez_160x120 : std_logic;
   signal rez_320x240 : std_logic;
   signal size_select: std_logic_vector(1 downto 0);
   signal rd_addr_l,wr_addr_l,rd_addr_r,wr_addr_r  : std_logic_vector(14 downto 0);
   signal avg_x_r, avg_x_l, avg_y_r, avg_y_l, x_blocker, y_blocker : integer := 0;
   
   signal rpi_done : std_logic := '0';
   signal x_rpi, y_rpi : integer := 0;
   signal brightspot_en : std_logic := '1';
   
   -- VGA TOGGLE SIGNALS
   
   signal vga_hsync_cam, vga_vsync_cam, vga_hsync_dark, vga_vsync_dark : std_logic := '0';
   signal vga_r_cam, vga_r_dark, vga_g_cam, vga_g_dark, vga_b_cam, vga_b_dark : std_logic_vector(3 downto 0) := "0000";
   
   SIGNAL VGA_TOGGLE_DARK : STD_LOGIC := '1'; -- 0 IS CAM, 1 IS DARK
   
begin
   vga_r_cam <= red(7 downto 4);
   vga_g_cam <= green(7 downto 4);
   vga_b_cam <= blue(7 downto 4);
   
   rez_160x120 <= '1';
   rez_320x240 <= '0';--btnr;
   
 your_instance_name : clocking
     port map
      (-- Clock in ports
       CLK_100 => CLK100,
       -- Clock out ports
       CLK_50 => CLK_camera,
       CLK_25 => CLK_vga);

   -- VGA TOGGLE
   process(clk100) begin
   if vga_toggle_dark = '1' then
    vga_hsync <= vga_hsync_dark;
    vsync <= vga_vsync_dark;
    vga_r <= vga_r_dark;
    vga_g <= vga_g_dark;
    vga_b <= vga_b_dark;
   else
    vga_hsync <= vga_hsync_cam;
    vsync <= vga_vsync_cam;
    vga_r <= vga_r_cam;
    vga_g <= vga_g_cam;
    vga_b <= vga_b_cam;
   end if;
   end process;
   vga_vsync <= vsync;
    
	Inst_VGA: VGA PORT MAP(
		CLK25      => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		clkout     => open,
		Hsync      => vga_hsync_CAM,
		Vsync      => vga_vsync_cam,
		Nblank     => nBlank,
		Nsync      => nsync,
      activeArea => activeArea
	);
	
	inst_darkvga : dark_vga port map(
	   clk => clk_vga,
	   x_blocker => x_blocker,
	   y_blocker => y_blocker,
	   hsync => vga_hsync_dark,
	   vsync => vga_vsync_dark,
	   red => vga_r_dark,
	   brightspot_en => brightspot_en,
	   green => vga_g_dark,
	   blue => vga_b_dark);

	Inst_debounce: debounce PORT MAP(
		clk => clk_vga,
		i   => btnc,
		o   => resend
	);

	Inst_ov7670_controller_left: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished_l,
		sioc            => ov7670_sioc_l,
		siod            => ov7670_siod_l,
		reset           => ov7670_reset_l,
		pwdn            => ov7670_pwdn_l,
		xclk            => ov7670_xclk_l
	);
	
	Inst_ov7670_controller_right: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished_r,
		sioc            => ov7670_sioc_r,
		siod            => ov7670_siod_r,
		reset           => ov7670_reset_r,
		pwdn            => ov7670_pwdn_r,
		xclk            => ov7670_xclk_r
	);
	--size_select <= btnl&btnr;
	
    --with size_select select 
    rd_addr_l <= --rdaddress_l(18 downto 2) when "00",
        rdaddress_l(14 downto 0);-- when "01",
--        rdaddress_l(16 downto 0) when "10",
--        rdaddress_l(16 downto 0) when "11";
--    with size_select select
    rd_addr_r <= --rdaddress_r(18 downto 2) when "00",
        rdaddress_r(14 downto 0);-- when "01",
--        rdaddress_r(16 downto 0) when "10",
--        rdaddress_r(16 downto 0) when "11";
  -- with size_select select 
    wr_addr_r <= --wraddress_r(18 downto 2) when "00",
            wraddress_r(14 downto 0);-- when "01",
--            wraddress_r(16 downto 0) when "10",
--            wraddress_r(16 downto 0) when "11";
   --with size_select select 
    wr_addr_l <= --wraddress_l(18 downto 2) when "00",
            wraddress_l(14 downto 0);-- when "01",
--            wraddress_l(16 downto 0) when "10",
--            wraddress_l(16 downto 0) when "11";

    inst_brightspot_r : brightspot PORT MAP(
        clk         => clk_vga,
        vsync       => ov7670_vsync_r,
        href        => ov7670_href_r,
        we_reg      => wren_r(0),
        addrb       => rd_addr_r,
        brightspot_en => brightspot_en,
        doutb       => rddata_r,
        avg_x       => avg_x_r,
        avg_y       => avg_y_r);
        
    inst_brightspot_l : brightspot PORT MAP(
        clk         => clk_vga,
        vsync       => ov7670_vsync_l,
        href        => ov7670_href_l,
        we_reg      => wren_l(0),
        addrb       => rd_addr_l,
        doutb       => rddata_l,
        brightspot_en => open,
        avg_x       => avg_x_l,
        avg_y       => avg_y_l);  
    
    inst_lightblocker : lightblocker port map(
        clk => clk_vga,
        en => rpi_done,
        x_l => avg_x_r,
        x_r => avg_x_l,
        y_l => avg_y_r,
        y_r => avg_y_l,
        x_rpi => x_rpi,
        y_rpi => y_rpi,
        x_blocker => x_blocker,
        y_blocker => y_blocker);
        
            
	Inst_frame_buffer_l: frame_buffer PORT MAP(
		addrb => rd_addr_l,
		clkb   => clk_vga,
		doutb        => rddata_l,
		enb    =>'1',
		clka   => ov7670_pclk_l,
		addra => wr_addr_l,
		dina      => wrdata_l(7 downto 4),
		wea      => wren_l
	);
	
	Inst_frame_buffer_r: frame_buffer PORT MAP(
		addrb => rd_addr_r,
		clkb   => clk_vga,
		doutb        => rddata_r,
		enb    =>'1',
		clka   => ov7670_pclk_r,
		addra => wr_addr_r,
		dina      => wrdata_r(7 downto 4),
		wea      => wren_r
	);
	
	
	Inst_ov7670_capture_l: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk_l,
--      rez_160x120 => rez_160x120,
--      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync_l,
		href  => ov7670_href_l,
		d     => ov7670_data_l,
		addr  => wraddress_l,
		dout  => wrdata_l,
		we    => wren_l(0)
	);
	
	Inst_ov7670_capture_r: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk_r,
--      rez_160x120 => rez_160x120,
--      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync_r,
		href  => ov7670_href_r,
		d     => ov7670_data_r,
		addr  => wraddress_r,
		dout  => wrdata_r,
		we    => wren_r(0)
	); 

	Inst_RGB: RGB PORT MAP(
		Din_l => rddata_l,
		Din_r => rddata_r,
		Nblank => activeArea,
		R => red,
		G => green,
		B => blue
	);

	Inst_Address_Generator_l: Address_Generator PORT MAP(
		CLK25 => clk_vga,
--      rez_160x120 => rez_160x120,
--      rez_320x240 => rez_320x240,
		enable => activeArea,
      vsync  => vsync,
		address => rdaddress_l
	);
Inst_Address_Generator_r: Address_Generator PORT MAP(
		CLK25 => clk_vga,
--      rez_160x120 => rez_160x120,
--      rez_320x240 => rez_320x240,
		enable => activeArea,
      vsync  => vsync,
		address => rdaddress_r
	);
	
inst_rx : receiver  port map(
    clk => clk_vga,
    rx => rxextport,
    x_rpi => x_rpi,
    y_rpi => y_rpi,
    rpi_done => rpi_done);
end Behavioral;