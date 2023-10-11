`timescale 1 ps/ 1 ps
import param_pkg::*;
interface demo_intf (input clk, input rst_n);

    bit                 i_data_en ;
    bit                 o_data_en ;
    bit                 i_pvsync  ;
    bit                 o_pvsync  ;
    bit                 i_phsync  ;
    bit                 o_phsync  ;
    bit                 done      ;

    logic [BITS-1:0]    i_data_0, i_data_1, i_data_2, i_data_3, i_data_4, i_data_5, i_data_6, i_data_7;

    logic [BITS-1:0]    o_data_r_0, o_data_g_0, o_data_b_0;
    logic [BITS-1:0]    o_data_r_1, o_data_g_1, o_data_b_1;
    logic [BITS-1:0]    o_data_r_2, o_data_g_2, o_data_b_2;
    logic [BITS-1:0]    o_data_r_3, o_data_g_3, o_data_b_3;
    logic [BITS-1:0]    o_data_r_4, o_data_g_4, o_data_b_4;
    logic [BITS-1:0]    o_data_r_5, o_data_g_5, o_data_b_5;
    logic [BITS-1:0]    o_data_r_6, o_data_g_6, o_data_b_6;
    logic [BITS-1:0]    o_data_r_7, o_data_g_7, o_data_b_7;


    clocking driver_cb @(posedge clk);
        default input #1 output #1;    
        output          i_data_en ;
        input           o_data_en ;
        output          i_phsync  ;
        input           o_phsync  ;
        output          i_pvsync  ;
        input           o_pvsync  ;
        output          i_data_0, i_data_1, i_data_2, i_data_3, i_data_4, i_data_5, i_data_6, i_data_7;

        input           o_data_r_0, o_data_g_0, o_data_b_0;
        input           o_data_r_1, o_data_g_1, o_data_b_1;
        input           o_data_r_2, o_data_g_2, o_data_b_2;
        input           o_data_r_3, o_data_g_3, o_data_b_3;
        input           o_data_r_4, o_data_g_4, o_data_b_4;
        input           o_data_r_5, o_data_g_5, o_data_b_5;
        input           o_data_r_6, o_data_g_6, o_data_b_6;
        input           o_data_r_7, o_data_g_7, o_data_b_7;
        input           done      ;
    endclocking
 
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input           i_data_en ;
        input           o_data_en ;
        input           i_phsync   ;
        input           o_phsync   ;
        input           i_pvsync   ;
        input           o_pvsync   ;
        input           i_data_0  , i_data_1, i_data_2, i_data_3, i_data_4, i_data_5, i_data_6, i_data_7;
        input           o_data_r_0, o_data_g_0, o_data_b_0;
        input           o_data_r_1, o_data_g_1, o_data_b_1;
        input           o_data_r_2, o_data_g_2, o_data_b_2;
        input           o_data_r_3, o_data_g_3, o_data_b_3;
        input           o_data_r_4, o_data_g_4, o_data_b_4;
        input           o_data_r_5, o_data_g_5, o_data_b_5;
        input           o_data_r_6, o_data_g_6, o_data_b_6;
        input           o_data_r_7, o_data_g_7, o_data_b_7;
        input           done      ;
    endclocking
  
  modport DRIVER  (clocking driver_cb  , input rst_n);
  modport MONITOR (clocking monitor_cb , input rst_n);

endinterface
