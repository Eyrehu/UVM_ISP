class demo_agent extends uvm_agent;
            demo_sequencer  seqr;
            demo_driver     driv;
            demo_mon        mon ;
    virtual demo_intf       vif ;

    uvm_analysis_port#(demo_transaction) aport_act;
    uvm_analysis_port#(demo_transaction) aport_exp;

    `uvm_component_utils(demo_agent)

    function new(string name="demo_agent",uvm_component parent=null);  
        super.new(name, parent);
        aport_act = new("aport_act", this);
        aport_exp = new("aport_exp", this);
    endfunction:new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual demo_intf)::get(this, "", "demo_intf", vif)) begin
            `uvm_fatal("interface", "No virtual interface specified for this env instance")
        end
        if(!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
            `uvm_fatal("demo_agent", "No is_active")

        if(is_active == UVM_ACTIVE) begin    
            seqr = demo_sequencer::type_id::create("seqr", this);
            driv = demo_driver::type_id::create("driv", this);
        end
        mon      = demo_mon::type_id::create("mon",this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            driv.seq_item_port.connect( seqr.seq_item_export);
        end
        mon.act_port.connect(aport_act);
        mon.exp_port.connect(aport_exp);
    endfunction
endclass
