`define DRV_IF vif.DRIVER.driver_cb
//import param_pkg::*;
typedef readbin#(.BITS(BITS), .HEIGHT(HEIGHT), .WIDTH(WIDTH)) pic;
class demo_driver extends uvm_driver #(demo_transaction);
    `uvm_component_utils(demo_driver)
    virtual demo_intf   vif       ;
            integer     rows  = 0 ;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        if( !uvm_config_db #(virtual demo_intf)::get(this, "", "demo_intf", vif) )
            `uvm_error("", "uvm_config_db::get failed")
    endfunction 
    extern virtual task drive_rx(demo_transaction req);
    task run_phase(uvm_phase phase);
        demo_transaction req;
        drive_rx(req);
    endtask
endclass: demo_driver
  
task demo_driver::drive_rx(demo_transaction req);
    logic [BITS-1:0] data[0:h_chan*v_chan-1]; // 一次取1cycle个数据
    readbin#(.BITS(BITS), .HEIGHT(HEIGHT), .WIDTH(WIDTH), .h_chan(h_chan), .v_chan(v_chan)) pic;
    pic = new();
    pic.set(IMAGE_IN);
    forever begin
        @(posedge vif.rst_n);
        @(posedge vif.clk);
        seq_item_port.get_next_item(req);
        foreach(req.i_data_en[i]) begin 
            `DRV_IF.i_data_en    <= req.i_data_en[i];
            `DRV_IF.i_pvsync     <= req.i_pvsync[i];
            `DRV_IF.i_phsync     <= req.i_phsync[i];
            /*  1cycle 向DUT 传递 h_chan*v_chan 个 pixels*/
            if (req.i_data_en[i]) begin
                pic.gen_pic(data); 
                `DRV_IF.i_data_0 <= data[0];
                `DRV_IF.i_data_1 <= data[1];
                `DRV_IF.i_data_2 <= data[2];
                `DRV_IF.i_data_3 <= data[3];
                `DRV_IF.i_data_4 <= data[4];
                `DRV_IF.i_data_5 <= data[5];
                `DRV_IF.i_data_6 <= data[6];
                `DRV_IF.i_data_7 <= data[7];
            end else begin
                `DRV_IF.i_data_0 <= {BITS{1'b0}};
                `DRV_IF.i_data_1 <= {BITS{1'b0}};
                `DRV_IF.i_data_2 <= {BITS{1'b0}};
                `DRV_IF.i_data_3 <= {BITS{1'b0}};
                `DRV_IF.i_data_4 <= {BITS{1'b0}};
                `DRV_IF.i_data_5 <= {BITS{1'b0}};
                `DRV_IF.i_data_6 <= {BITS{1'b0}};
                `DRV_IF.i_data_7 <= {BITS{1'b0}};
            end
            if (req.i_phsync[i]) begin // 等价于 @ (posedge req.i_data_en)
                $display("[%0d]Image visiable area: the current rows is %0d ...", $time, rows);
                rows  = rows + 1;
            end
            @(posedge vif.clk);
        end
        seq_item_port.item_done();
    end
endtask