
#行    覆盖率 line coverage 要求百分之99-100
#状态机覆盖率 FSM coverage
#条件  覆盖率 conditional coverage
#翻转  覆盖率 Toggle coverage ：0->1 ,1->0
#路径  覆盖率 Path coverage ：initial 和always里的语句
#分支  覆盖率 branch coverage
#-cm line+cond+fsm+branch+tgl为生成什么条件的覆盖率

casename   = demo_test1
CM_NAME    =-cm_name simv
CM_DIR     =-cm_dir ./covdir.vdb  # coverage report

FILE       = patlist.txt
TEST_NAMES =`cat $(FILE)`

all1: clean compile1_1 run
#all2: clean compile1_2 run

compile1_1:
	@echo "Compiling Design"
	vcs -fsdb +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv \
	$(UVM_HOME)/src/dpi/uvm_dpi.cc -CFLAGS -DVCS \
	-sverilog -ntb_opts uvm-1.1d  -debug_access+all -f flist.f -timescale=1ns/1ps \
	+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
	-cm line+tgl+cond+branch+assert+fsm -assert -full64 -LDFLAGS '-Wl,--no-as-needed' \
	${CM_NAME} \
	${CM_DIR} 

compile1_2:
	@echo "Compiling Design"
	vcs -sverilog -ntb_opts uvm-1.2 -debug_access+all -f flist.f -timescale=1ns/1ps \
	-cm line+tgl+cond+branch+assert+fsm -assert -full64 -LDFLAGS '-Wl,--no-as-needed' \
	${CM_NAME} \
	${CM_DIR} 
run:
	./simv -l ${casename}.log +UVM_TIMEOUT=900000000 +UVM_TESTNAME=${casename} +notimingcheck +nospecify \
	-cm line+tgl+cond+branch+assert+fsm \
	${CM_NAME} \
	${CM_DIR} 

test-list:
	@for i in $(covfiles); do \
		echo $$i; \
	done

run_cov_all:		
	@echo "Running Tests with Coverage"
	rm -rf ${TEST_NAMES} ; mkdir ${TEST_NAMES}
	@for i in $(TEST_NAMES); do \
		./simv -l $$i.log +UVM_TIMEOUT=900000000 +UVM_TESTNAME=$$i -cm line+tgl+cond+branch+assert+fsm; \
		cp -rf simv.vdb $$i/; \
		mv $$i.log $$i/; \
	done
	urg -dir *_test/*.vdb -elfile exclusion.el -excl_bypass_checks	


dve: 		
	dve -covdir *_test/*.vdb &

verdi:
	verdi ${casename} \
	-ssf ./*.fsdb &

cov:
	dve -full64 -covdir *.vdb &

clean:
	@echo "Cleaning up...."
	rm -rf csrc DVEfiles urgReport simv.vdb ${casename} *.vpd *.vcd *.bin  simv simv.daidir ucli.key vc_hdrs.h vcs.log .inter.vpd.uvm *.log covdir.vdb novas.conf novas.rc verdiLog





