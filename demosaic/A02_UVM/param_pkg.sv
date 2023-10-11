package param_pkg;
    parameter BITS            = 8  ; //支持8/16/24/32
    parameter H_frontporch    = 50 ;
    parameter H_PULSE         = 1  ;
    parameter H_backporch     = 50 ;
    parameter WIDTH           = 768;
    parameter V_frontporch    = 10 ;
    parameter V_PULSE         = 1  ;
    parameter V_backporch     = 10 ;
    parameter HEIGHT          = 512;
    // 每个cycle内交给DUT的是 2行4列共8个pixel
    parameter h_chan          = 4  ;
    parameter v_chan          = 2  ;
 
    parameter H_transfercycle = WIDTH  / h_chan;
    parameter V_transferline  = HEIGHT / v_chan;
    parameter H_totalcycle    = H_frontporch + H_PULSE + H_transfercycle + H_backporch;
    parameter V_totalline     = V_frontporch + V_PULSE + V_transferline  + V_backporch;
    parameter totalcycle      = H_totalcycle * V_totalline;
    
    parameter string  BAYER     = "rggb";
    parameter string  IMAGE_IN  = "../D01_input_img/raw_512x768_rggb.bin";
    // 期望值图像路径
    parameter string  EXP_R     = "../D02_exp_img/v2h4_dem_r.bin";
    parameter string  EXP_G     = "../D02_exp_img/v2h4_dem_g.bin";
    parameter string  EXP_B     = "../D02_exp_img/v2h4_dem_b.bin";
    // DUT输出图像路径
    parameter string  ACT_R     = "../D03_act_img/v2h4_dem_r.bin";
    parameter string  ACT_G     = "../D03_act_img/v2h4_dem_g.bin";
    parameter string  ACT_B     = "../D03_act_img/v2h4_dem_b.bin";

endpackage
