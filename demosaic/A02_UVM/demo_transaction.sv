
`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;
class demo_transaction extends uvm_sequence_item;
    
    rand bit                i_data_en[0:totalcycle    -1] ;
    rand bit                i_pvsync [0:totalcycle    -1] ;
    rand bit                i_phsync [0:totalcycle    -1] ;
    rand logic  [BITS-1:0]  i_data   [0:h_chan*v_chan -1] ;
    bit                     o_data_en ;
    bit                     done      ;
    logic [BITS-1:0]        o_data_r[0:h_chan*v_chan -1];
    logic [BITS-1:0]        o_data_g[0:h_chan*v_chan -1];
    logic [BITS-1:0]        o_data_b[0:h_chan*v_chan -1];
    function  new (string name = "demo_transaction");
        super.new(name);
    endfunction
    `uvm_object_utils_begin (demo_transaction)
        `uvm_field_sarray_int (i_data_en ,  UVM_ALL_ON)
        `uvm_field_sarray_int (i_pvsync  ,  UVM_ALL_ON)
        `uvm_field_sarray_int (i_phsync  ,  UVM_ALL_ON)
        `uvm_field_sarray_int (i_data    ,  UVM_ALL_ON)
        `uvm_field_sarray_int (o_data_r  ,  UVM_ALL_ON)
        `uvm_field_sarray_int (o_data_g  ,  UVM_ALL_ON)
        `uvm_field_sarray_int (o_data_b  ,  UVM_ALL_ON)
        `uvm_field_int        (o_data_en ,  UVM_ALL_ON)
        `uvm_field_int        (done      ,  UVM_ALL_ON)
    `uvm_object_utils_end

endclass 