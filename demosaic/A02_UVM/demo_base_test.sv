import uvm_pkg::*;
`include "uvm_macros.svh"
class demo_base_test extends uvm_test;

    demo_env         env_i;
    `uvm_component_utils(demo_base_test)
    extern          function        new(string name = "demo_base_test", uvm_component parent);
    extern virtual  function void   build_phase(uvm_phase phase);
    extern virtual  function void   start_of_simulation_phase(uvm_phase phase);
    extern virtual  task            main_phase(uvm_phase phase);
    extern virtual  function void   report_phase(uvm_phase phase);
    extern          function int    num_uvm_errors();
endclass

//Constructor
function demo_base_test::new(string name = "demo_base_test", uvm_component parent);
    super.new(name, parent);
endfunction

//Build_Phase
function void demo_base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_i = demo_env::type_id::create("env_i", this);
endfunction

//start_of_simulation_phase
function void demo_base_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    uvm_top.print_topology();
endfunction
    
//Main_Phase
task demo_base_test::main_phase(uvm_phase phase);
    phase.phase_done.set_drain_time(this, 15ms);
endtask

function void demo_base_test::report_phase(uvm_phase phase);
    super.report_phase(phase);
    if(num_uvm_errors == 0)begin
        `uvm_info(get_type_name(), "Simulation Passed!", UVM_NONE)
    end else begin
        `uvm_info(get_type_name(), "Simulation Failed!", UVM_NONE)
    end
endfunction

function int demo_base_test::num_uvm_errors();
    uvm_report_server server;
    if(server == null)
        server = get_report_server();
    return server.get_severity_count(UVM_ERROR);
endfunction
