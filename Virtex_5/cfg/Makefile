# TOP, SRC, TEMPLATES are passed in
SRCS := $(shell find $(SRC) -type f -name '*.vhd')
UCF := $(wildcard $(SRC)/$(TOP).ucf)

PART := xc5vlx110t-1-ff1136

default: all

#XST
XST_TMPDIR := xst/tmp
XST_PRJ := $(TOP).prj
XST_BATCH := $(TOP).xst
XST_OUT := $(TOP).ngc

$(XST_PRJ): $(SRCS) | $(XST_TMPDIR)
	for src in $(SRCS); do\
		echo "vhdl work \"$$src\"";\
	done > $@

$(XST_TMPDIR):
	mkdir -p $@

$(XST_BATCH): $(TEMPLATES)/xst.batch $(XST_PRJ)
	sed "s/##TOPMODULE##/$(TOP)/g" < $< > $@

$(XST_OUT): $(XST_BATCH)
	xst -ifn $(TOP).xst -ofn $(TOP).syr

synth xst: $(XST_OUT)


#NGDBUILD
NGDBUILD_OUT := $(TOP).ngd
UCF_FLAG := $(if $(UCF),-uc $(UCF))
NGC_DIRS := $(shell find $(SRC) -type d -exec echo -n "-sd {} " \;)

$(NGDBUILD_OUT): $(XST_OUT) $(UCF)
	ngdbuild -dd _ngo $(NGC_DIRS) -nt timestamp $(UCF_FLAG) -p $(PART) $(XST_OUT) $@



#MAP
MAP_OUT := $(TOP)_map.ncd
MAP_OPTS := $(shell cat $(TEMPLATES)/map.opts | tr '\n' ' ')

$(MAP_OUT) : $(NGDBUILD_OUT)
	map $(MAP_OPTS) -p $(PART) -o $@ $< $(TOP).pcf

map: $(MAP_OUT)

#PAR
PAR_OUT := $(TOP).ncd

$(PAR_OUT): $(MAP_OUT)
	par -w -ol high -xe n -mt off $(MAP_OUT) $@ $(TOP).pcf

par: $(PAR_OUT)

#TRCE
TRCE_OUT := $(TOP).twr

$(TRCE_OUT): $(PAR_OUT)
	trce -v 3 -s 3 -n 3 -fastpaths -xml $(TOP).twx $< -o $(TRCE_OUT) $(TOP).pcf

timing: $(TRCE_OUT)

#NETGEN
TIMESIM_DIR := netgen/par
NETGEN_OUT := $(TOP)_timesim.vhd

$(NETGEN_OUT): $(TRCE_OUT)
	netgen -s 3 -pcf $(TOP).pcf -rpw 100 -tpw 0 -ar Structure -tm $(TOP) -insert_pp_buffers  true -dir $(TIMESIM_DIR) -w -ofmt vhdl -sim $(PAR_OUT) $(NETGEN_OUT)

netgen: $(NETGEN_OUT)

#FUSE
PAR_PRJ := $(TOP)_tb_par.prj
FUSE_OUT := $(TOP)_tb_isim_par.exe

$(FUSE_OUT): $(NETGEN_OUT)
	echo -e "vhdl work \"$(TIMESIM_DIR)/$(NETGEN_OUT)\"\nvhdl work \"$(SRC)/$(TOP)_tb.vhd\"" > $(PAR_PRJ)
	fuse -incremental -lib secureip -o $(FUSE_OUT) -prj $(PAR_PRJ) $(TOP)_tb

fuse: $(FUSE_OUT)

#SIM
SIM_OUT := $(TOP)_tb_isim_par.wdb
SIM_OPTS := $(TEMPLATES)/isim.cmd

$(SIM_OUT): $(FUSE_OUT)
	./$(FUSE_OUT) -gui -sdfmax "/uut/=$(TIMESIM_DIR)/$(TOP)_timesim.sdf" -sdfroot /uut -tclbatch $(SIM_OPTS) -wdb $(SIM_OUT)

sim: $(SIM_OUT) 

#MISC
report:
	xreport $(TOP)

ise:
	ise ../../ise_proj/virtex_gearwork/virtex_gearwork.xise

all: sim

.PHONY = all synth xst map par timing netgen report fuse sim ise clean
