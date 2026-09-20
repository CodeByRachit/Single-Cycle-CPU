# Makefile for CPU Verification using Synopsys VCS

VCS = vcs
VCS_FLAGS = -sverilog -full64 -debug_access+all +v2k -timescale=1ns/1ps

RTL_DIR = ../RTL
VERIF_DIR = .

# Source files
RTL_FILES = \
    $(RTL_DIR)/alu.sv \
    $(RTL_DIR)/control_unit.sv \
    $(RTL_DIR)/imm_gen.sv \
    $(RTL_DIR)/memory.sv \
    $(RTL_DIR)/reg_file.sv \
    $(RTL_DIR)/cpu_top.sv

VERIF_FILES = \
    $(VERIF_DIR)/tb_top.sv

INC_DIRS = +incdir+$(VERIF_DIR)

UNIT_DIR = unit

.PHONY: all compile run clean unit_test test_alu test_cu test_imm test_mem test_rf

all: compile run

compile:
	$(VCS) $(VCS_FLAGS) $(INC_DIRS) $(RTL_FILES) $(VERIF_FILES) -o simv

SEED ?= random

run:
	mkdir -p results
	./simv +ntb_random_seed=$(SEED)

unit_test: test_alu test_cu test_imm test_mem test_rf

test_alu:
	mkdir -p results
	$(VCS) $(VCS_FLAGS) $(RTL_DIR)/alu.sv $(UNIT_DIR)/tb_alu.sv -o simv_alu
	./simv_alu

test_cu:
	mkdir -p results
	$(VCS) $(VCS_FLAGS) $(RTL_DIR)/control_unit.sv $(UNIT_DIR)/tb_control_unit.sv -o simv_cu
	./simv_cu

test_imm:
	mkdir -p results
	$(VCS) $(VCS_FLAGS) $(RTL_DIR)/imm_gen.sv $(UNIT_DIR)/tb_imm_gen.sv -o simv_imm
	./simv_imm

test_mem:
	mkdir -p results
	$(VCS) $(VCS_FLAGS) $(RTL_DIR)/memory.sv $(UNIT_DIR)/tb_memory.sv -o simv_mem
	./simv_mem

test_rf:
	mkdir -p results
	$(VCS) $(VCS_FLAGS) $(RTL_DIR)/reg_file.sv $(UNIT_DIR)/tb_reg_file.sv -o simv_rf
	./simv_rf

clean:
	rm -rf simv simv_* simv.daidir simv_*.daidir csrc ucli.key vc_hdrs.h DVEfiles *.vpd *.vcd *.fsdb results flex*.log
