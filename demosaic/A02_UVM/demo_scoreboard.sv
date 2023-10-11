// -----------------------------------------------------------------------------------
//  Using the `uvm_analysis_imp_decl() macro allows the construction of two analysis 
//  implementation ports with corresponding, uniquely named, write methods
// -----------------------------------------------------------------------------------

`uvm_analysis_imp_decl(_monitor)
`uvm_analysis_imp_decl(_model) 
import param_pkg::*;

class demo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(demo_scoreboard)

    demo_transaction    exp_que[$]     ;   // 期望队列，存的是transaction的句柄
    demo_transaction    act_que[$]     ;   // 实际队列

    demo_transaction    act_value      ;
    demo_transaction    exp_value      ;

    logic [BITS-1:0]    act_data_r[0 : h_chan*v_chan-1];    // 实际值
    logic [BITS-1:0]    act_data_g[0 : h_chan*v_chan-1];
    logic [BITS-1:0]    act_data_b[0 : h_chan*v_chan-1];

    logic [BITS-1:0]    exp_data_r[0 : h_chan*v_chan-1];
    logic [BITS-1:0]    exp_data_g[0 : h_chan*v_chan-1];
    logic [BITS-1:0]    exp_data_b[0 : h_chan*v_chan-1];

    int                 packets_passed ;
    int                 packets_failed ;
    int                 index          ;
   

    uvm_analysis_imp_monitor#(demo_transaction, demo_scoreboard) monitor_imp;
    uvm_analysis_imp_model  #(demo_transaction, demo_scoreboard)   model_imp;  

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase   (uvm_phase phase);
        super.build_phase(phase);
        monitor_imp = new("monitor_imp", this);
          model_imp = new(  "model_imp", this);  
    endfunction: build_phase

    virtual  function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
    endfunction: connect_phase

    extern function void write_monitor (demo_transaction tr);
    extern function void write_model   (demo_transaction tr);
    extern task check_output_inorder();


    virtual task run_phase(uvm_phase phase);  
        demo_transaction  act_value;
        super.run_phase(phase);
        check_output_inorder();
        $display("packets_passed = %0d, packets_failed = %0d", packets_passed, packets_failed);
        //check_output_outorder();
        
        if (packets_failed == 0) begin 
            $display( "\n\n\tresult: \t\tSUCCESS\n\n");
        end else begin
            $display( "\n\n\tresult: \t\tFAILED\n\n");
        end
    endtask

endclass

function void demo_scoreboard::write_monitor(demo_transaction tr);
    act_que.push_back(tr); // 插入元素到queue($)（队尾）
endfunction

function void demo_scoreboard::write_model(demo_transaction tr);
    exp_que.push_back(tr); // 插入元素到queue($)（队尾）
endfunction


// DUT 按照 顺序 输出
task demo_scoreboard::check_output_inorder();
        int index_total = WIDTH/h_chan * HEIGHT/v_chan; // data_en 为1区域 的宽度
        forever begin
            wait ((exp_que.size() > 0) && (act_que.size() > 0)) ;
            // 真实值
            act_value  = act_que.pop_front();
            for (integer i = 0; i < h_chan*v_chan; i++) begin 
                act_data_r[i] = act_value.o_data_r[i] ;
                act_data_g[i] = act_value.o_data_g[i] ;
                act_data_b[i] = act_value.o_data_b[i] ;
            end

            // 期望值
            exp_value   = exp_que.pop_front();

            for (integer i = 0; i < h_chan*v_chan; i++) begin 
                exp_data_r[i] = exp_value.o_data_r[i] ;
                exp_data_g[i] = exp_value.o_data_g[i] ;
                exp_data_b[i] = exp_value.o_data_b[i] ;
            end

            for (integer i = 0; i < h_chan*v_chan; i++) begin 
                if ((act_data_r[i] == exp_data_r[i]) && 
                    (act_data_g[i] == exp_data_g[i]) && 
                    (act_data_b[i] == exp_data_b[i]) ) begin 
                    
                    packets_passed = packets_passed + 1;
                end else begin
                    packets_failed = packets_failed + 1;
                    $display("Mismatch: index = %0d", index);
                    $display("act_data_r = %0d, \tact_data_g = %0d, \tact_data_b = %0d", act_data_r[i], act_data_g[i], act_data_b[i]);
                    $display("exp_data_r = %0d, \texp_data_g = %0d, \texp_data_b = %0d", exp_data_r[i], exp_data_g[i], exp_data_b[i]);
                end
            end

            index = index + 1;

            // 无法退出forever，所以增加了这个if函数
            if (index == index_total) begin 
                break;
            end
        end
    
endtask