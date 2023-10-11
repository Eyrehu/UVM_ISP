`timescale 1ns/1ns
`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;
module uvm_demosaic_top;
    reg        xclk  = 0 ;
    reg        rst_n = 0 ;
    demo_intf  vifdem(xclk, rst_n);
        isp_demosaic  #(
	        .BITS         (BITS         ),
	        .H_frontporch (H_frontporch ),
	        .H_PULSE      (H_PULSE      ),
	        .H_backtporch (H_backporch  ),
	        .HEIGHT       (HEIGHT       ),
	        .V_frontporch (V_frontporch ),
	        .V_PULSE      (V_PULSE      ),
	        .V_backtporch (V_backporch  ),
	        .WIDTH        (WIDTH        ),
            .h_chan       (h_chan       ),
            .v_chan       (v_chan       ),
            .BAYER        (BAYER        ))
        demosaic_i0 (
            .xclk         (xclk            ),
            .rst_n        (rst_n           ),
            .i_data_en    (vifdem.i_data_en),
            .i_phsync     (vifdem.i_phsync ),
            .i_pvsync     (vifdem.i_pvsync ),
            .i_data_0     (vifdem.i_data_0 ),
            .i_data_1     (vifdem.i_data_1 ),
            .i_data_2     (vifdem.i_data_2 ),
            .i_data_3     (vifdem.i_data_3 ),
            .i_data_4     (vifdem.i_data_4 ),
            .i_data_5     (vifdem.i_data_5 ),
            .i_data_6     (vifdem.i_data_6 ),
            .i_data_7     (vifdem.i_data_7 ),
            .o_data_en    (vifdem.o_data_en),
            .o_phsync     (vifdem.o_phsync ),
            .o_pvsync     (vifdem.o_pvsync ),
            
            .o_data_r_0(vifdem.o_data_r_0), .o_data_g_0(vifdem.o_data_g_0), .o_data_b_0(vifdem.o_data_b_0),
            .o_data_r_1(vifdem.o_data_r_1), .o_data_g_1(vifdem.o_data_g_1), .o_data_b_1(vifdem.o_data_b_1),
            .o_data_r_2(vifdem.o_data_r_2), .o_data_g_2(vifdem.o_data_g_2), .o_data_b_2(vifdem.o_data_b_2),
            .o_data_r_3(vifdem.o_data_r_3), .o_data_g_3(vifdem.o_data_g_3), .o_data_b_3(vifdem.o_data_b_3),
            .o_data_r_4(vifdem.o_data_r_4), .o_data_g_4(vifdem.o_data_g_4), .o_data_b_4(vifdem.o_data_b_4),
            .o_data_r_5(vifdem.o_data_r_5), .o_data_g_5(vifdem.o_data_g_5), .o_data_b_5(vifdem.o_data_b_5),
            .o_data_r_6(vifdem.o_data_r_6), .o_data_g_6(vifdem.o_data_g_6), .o_data_b_6(vifdem.o_data_b_6),
            .o_data_r_7(vifdem.o_data_r_7), .o_data_g_7(vifdem.o_data_g_7), .o_data_b_7(vifdem.o_data_b_7),
            .done      (vifdem.done     ));
    save2bin #( .FILE0(ACT_R), .FILE1(ACT_G), .FILE2(ACT_B), .BITS(BITS), .WIDTH(WIDTH) )
        save2bin_t (
            .xclk      (xclk            ),
            .rst_n     (rst_n           ),
            .data_en   (vifdem.o_data_en),
            .done      (vifdem.done     ),
            .i_data_r_0(vifdem.o_data_r_0), .i_data_g_0(vifdem.o_data_g_0), .i_data_b_0(vifdem.o_data_b_0) ,
            .i_data_r_1(vifdem.o_data_r_1), .i_data_g_1(vifdem.o_data_g_1), .i_data_b_1(vifdem.o_data_b_1) ,
            .i_data_r_2(vifdem.o_data_r_2), .i_data_g_2(vifdem.o_data_g_2), .i_data_b_2(vifdem.o_data_b_2) ,
            .i_data_r_3(vifdem.o_data_r_3), .i_data_g_3(vifdem.o_data_g_3), .i_data_b_3(vifdem.o_data_b_3) ,
            .i_data_r_4(vifdem.o_data_r_4), .i_data_g_4(vifdem.o_data_g_4), .i_data_b_4(vifdem.o_data_b_4) ,
            .i_data_r_5(vifdem.o_data_r_5), .i_data_g_5(vifdem.o_data_g_5), .i_data_b_5(vifdem.o_data_b_5) ,
            .i_data_r_6(vifdem.o_data_r_6), .i_data_g_6(vifdem.o_data_g_6), .i_data_b_6(vifdem.o_data_b_6) ,
            .i_data_r_7(vifdem.o_data_r_7), .i_data_g_7(vifdem.o_data_g_7), .i_data_b_7(vifdem.o_data_b_7) 
        );

    // Clock generator
    always #5 xclk <= ~xclk;

    initial begin
        rst_n  <= 0;
        #10   
        rst_n  <= 1;
        //#84_245;
        //$finish();
    end

    initial begin
        $dumpfile("dump.vcd"); 
        $dumpvars;
    end
    initial begin
        uvm_config_db #(virtual demo_intf)::set(null, "*", "demo_intf", vifdem);
        uvm_config_db #(uvm_active_passive_enum)::set(null, "*", "is_active", UVM_ACTIVE);
        run_test("demo_test1");
    end

endmodule