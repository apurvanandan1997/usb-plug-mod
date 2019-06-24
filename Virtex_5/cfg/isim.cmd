onerror {resume}
wave add /
#vcd dumpfile top_tb.vcd
#vcd dumpvars -m top_tb -l 0
run 3000 ns;
#vcd dumpflush

