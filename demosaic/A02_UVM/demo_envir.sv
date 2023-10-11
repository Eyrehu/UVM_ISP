class demo_env extends uvm_env;
    `uvm_component_utils(demo_env)

    demo_agent       agt;
    demo_scoreboard  scb;
    function new(string name = "demo_env", uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        agt = demo_agent::type_id::create("agt",this);  
        scb = demo_scoreboard::type_id::create("scb",this);  
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.aport_act.connect(scb.monitor_imp);
        agt.aport_exp.connect(scb.model_imp);
    endfunction: connect_phase

endclass: demo_env

 