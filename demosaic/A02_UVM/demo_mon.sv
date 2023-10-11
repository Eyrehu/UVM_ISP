`define MONAPB_IF intf.MONITOR.monitor_cb
import param_pkg::*;
class demo_mon extends uvm_monitor;
    virtual demo_intf          intf;
            demo_transaction   act_item;  // 真实值 构成的transaction，交给scoreboard
            demo_transaction   exp_item;  // 预期值 构成的transaction，交给scoreboard
            uvm_analysis_port #(demo_transaction) act_port;
            uvm_analysis_port #(demo_transaction) exp_port;
    `uvm_component_utils(demo_mon)
    
    logic [BITS-1:0] exp_data_r[0:h_chan*v_chan-1]; 
    logic [BITS-1:0] exp_data_g[0:h_chan*v_chan-1]; 
    logic [BITS-1:0] exp_data_b[0:h_chan*v_chan-1]; 
    readbin#(.BITS(BITS), .HEIGHT(HEIGHT), .WIDTH(WIDTH), .h_chan(h_chan), .v_chan(v_chan))  img_exp_r, img_exp_g, img_exp_b;

    function new(string name="", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        act_port = new("act_port", this);
        exp_port = new("exp_port", this);
        act_item = demo_transaction::type_id::create("act_item");
        //exp_item = demo_transaction::type_id::create("exp_item");

        if(!uvm_config_db #(virtual demo_intf)::get(this, "", "demo_intf", intf))  begin
            `uvm_error("ERROR::", "UVM_CONFIG_DB FAILED in demo_mon")
        end
        img_exp_r  = new();
        img_exp_g  = new();
        img_exp_b  = new();
    endfunction

 virtual task run_phase(uvm_phase phase);

        img_exp_r.set(EXP_R );    // 设置预期值输出图像
        img_exp_g.set(EXP_G );    // 设置预期值输出图像
        img_exp_b.set(EXP_B );    // 设置预期值输出图像

        fork
            // 1.根据 i_data_en  处理 预期 pixel
            forever begin
                @(posedge intf.clk);
                if (`MONAPB_IF.i_data_en) begin  // data_en为1，则读取数据
                    exp_item = demo_transaction::type_id::create("exp_item");
                    img_exp_r.gen_pic(exp_data_r );  // data_en上升沿时，从预期图形中加载1cycle个数据
                    img_exp_g.gen_pic(exp_data_g );  // data_en上升沿时，从预期图形中加载1cycle个数据
                    img_exp_b.gen_pic(exp_data_b );  // data_en上升沿时，从预期图形中加载1cycle个数据
                    for (integer i = 0; i < h_chan*v_chan; i++) begin 
                        exp_item.o_data_r[i] = exp_data_r[i];
                        exp_item.o_data_g[i] = exp_data_g[i];
                        exp_item.o_data_b[i] = exp_data_b[i];
                    end
                    // data_en 为高，则通过TLM把数据交给 scoreboard
                    exp_port.write(exp_item);       
                end
            end
            // 2.根据 o_data_en 处理 真实 pixel，同时把 输出pixel 写入到 对应路径下。
            forever begin
                @(posedge intf.clk);
                if (`MONAPB_IF.o_data_en) begin
                    act_item.o_data_en   = `MONAPB_IF.o_data_en;

                    act_item.o_data_r[0] = `MONAPB_IF.o_data_r_0;
                    act_item.o_data_r[1] = `MONAPB_IF.o_data_r_1;
                    act_item.o_data_r[2] = `MONAPB_IF.o_data_r_2;
                    act_item.o_data_r[3] = `MONAPB_IF.o_data_r_3;
                    act_item.o_data_r[4] = `MONAPB_IF.o_data_r_4;
                    act_item.o_data_r[5] = `MONAPB_IF.o_data_r_5;
                    act_item.o_data_r[6] = `MONAPB_IF.o_data_r_6;
                    act_item.o_data_r[7] = `MONAPB_IF.o_data_r_7;
                    
                    act_item.o_data_g[0] = `MONAPB_IF.o_data_g_0;
                    act_item.o_data_g[1] = `MONAPB_IF.o_data_g_1;
                    act_item.o_data_g[2] = `MONAPB_IF.o_data_g_2;
                    act_item.o_data_g[3] = `MONAPB_IF.o_data_g_3;
                    act_item.o_data_g[4] = `MONAPB_IF.o_data_g_4;
                    act_item.o_data_g[5] = `MONAPB_IF.o_data_g_5;
                    act_item.o_data_g[6] = `MONAPB_IF.o_data_g_6;
                    act_item.o_data_g[7] = `MONAPB_IF.o_data_g_7;
                    
                    act_item.o_data_b[0] = `MONAPB_IF.o_data_b_0;
                    act_item.o_data_b[1] = `MONAPB_IF.o_data_b_1;
                    act_item.o_data_b[2] = `MONAPB_IF.o_data_b_2;
                    act_item.o_data_b[3] = `MONAPB_IF.o_data_b_3;
                    act_item.o_data_b[4] = `MONAPB_IF.o_data_b_4;
                    act_item.o_data_b[5] = `MONAPB_IF.o_data_b_5;
                    act_item.o_data_b[6] = `MONAPB_IF.o_data_b_6;
                    act_item.o_data_b[7] = `MONAPB_IF.o_data_b_7;             
                    act_port.write(act_item);
                end
            end
        join
    endtask    
endclass
