class demo_test1 extends demo_base_test;
    demo_sequence   demo_seq_i;
    `uvm_component_utils(demo_test1)
    function new(string name = "demo_test1", uvm_component parent);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        demo_seq_i = demo_sequence::type_id::create("demo_seq_i");
    endfunction
    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.main_phase(phase);
        #10ns;
        demo_seq_i.start(env_i.agt.seqr);    
        phase.drop_objection(this);
        phase.phase_done.set_drain_time(this, 100000); // 控制结束结束。等效于在top层时间 $finish();
    endtask
endclass