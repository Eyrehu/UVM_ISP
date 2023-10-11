//typedef uvm_sequencer #(demo_transaction) demo_sequencer;
import param_pkg::*;
typedef demo_env;
class Portsignal ;

    integer width  = WIDTH;
    integer height = HEIGHT;

    bit      data_en[0:totalcycle -1] ;
    bit      phsync [0:totalcycle -1] ;
    bit      pvsync [0:totalcycle -1] ;

    function void init();
        foreach(data_en[i]) begin
            data_en[i] = 0;
            phsync [i] = 0;
            pvsync [i] = 0;
        end
    endfunction

    function void gen_ports();

        integer line_cnt = 0;
        integer pix_cnt  = 0;
        for (integer i = 0 ; i < totalcycle; i++ ) begin
            if (pix_cnt < H_totalcycle - 1) begin
                pix_cnt = pix_cnt + 1;
            end else if (pix_cnt == H_totalcycle - 1) begin
                pix_cnt = 0;
                if (line_cnt < V_totalline - 1)
                    line_cnt = line_cnt + 1;
                else
                    line_cnt = 0;
            end
            pvsync[i]  =  (line_cnt >= V_frontporch && line_cnt < V_frontporch + V_PULSE) ? 1 : 0; 
            phsync[i]  =  (pix_cnt  >= H_frontporch && pix_cnt  < H_frontporch + H_PULSE) ? 1 : 0;
            data_en[i] =  (pix_cnt  >= H_totalcycle - H_transfercycle) && (line_cnt >= V_totalline - V_transferline);
            //$display("index = %0d, pvsync[i] = %0d, phsync[i] = %0d, data_en[i] = %0d", i, pvsync[i], phsync[i], data_en[i]);
        end
    endfunction
endclass

class demo_sequence extends uvm_sequence #(demo_transaction);
    `uvm_object_utils(demo_sequence)
    demo_transaction    req;        // 待配置的 transaction，交给driver
    Portsignal          pic;
    function new (string name = ""); 
        super.new(name);
    endfunction
    task body;
        if (starting_phase != null) begin starting_phase.raise_objection(this); end 
        repeat(1) begin
            req      = demo_transaction::type_id::create("req");
            start_item(req);
            direct_item();     // 不能使用 assert(xxx.random_mize()), 必须用定向case
            finish_item(req);
        end
        if (starting_phase != null) begin starting_phase.drop_objection(this); end 
    endtask: body
   
    function void direct_item();
        pic = new()                  ;
        pic.init()                   ;
        pic.gen_ports()              ;
        req.i_data_en = pic.data_en ;
        req.i_pvsync  = pic.pvsync  ;
        req.i_phsync  = pic.phsync  ;
    endfunction
endclass: demo_sequence


/*module testOverride;
    Portsignal  pic;
    initial begin
        pic = new();
        pic.init();
        pic.gen_ports();
        $display("height = %0d, width = %0d", pic.height, pic.width);
    end
endmodule*/