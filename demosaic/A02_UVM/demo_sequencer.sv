class demo_sequencer extends uvm_sequencer #(demo_transaction) ;
    `uvm_component_utils(demo_sequencer)
    function new(input string name, uvm_component parent=null);
        super.new(name, parent);
    endfunction : new
endclass : demo_sequencer