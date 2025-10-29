# -----------------------------
# Minimalistic Makefile
# -----------------------------

# Directories and files
WORKDIR = work
RTL_DIR = ../../rtl
IFACES_DIR = ../interfaces
TOP_LEVEL = ../top.sv
PKG_SRC = package.sv
CPP_SRC = frame.cpp
CPP_EXE = frame.exe
FRAME_LIB = frame

# Tools
CL = cl
PYTHON = python
VLIB = vlib
VLOG = vlog
VSIM = vsim -c
MTI_HOME ?= C:\questasim64_2024.1

# Python paths (auto-detected)
PY_INCLUDE := $(shell $(PYTHON) -c "import sysconfig; print(sysconfig.get_path('include'))")
PY_LIBDIR := $(shell $(PYTHON) -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")

# Compilation flags
CPP_FLAGS = /EHsc /W0
CPP_INCLUDES = /I "$(PY_INCLUDE)" /I "$(MTI_HOME)\include"
CPP_LINK_FLAGS = /link /LIBPATH:"$(PY_LIBDIR)" python313.lib "$(MTI_HOME)\win64\mtipli.lib"

VLOG_FLAGS = -sv +acc -lint +define+UVM_REPORT_DISABLE_FILE_LINE
VSIM_FLAGS = -classdebug -uvmcontrol=all -voptargs=+acc +UVM_NO_RELNOTES +UVM_NO_MSG=PHASESEQ +UVM_NO_MSG=PH_READY_TO_END +UVM_VERBOSITY=UVM_LOW
TEST_NAME = +UVM_TESTNAME=variable_handshake_test
# udp_xgmii_parallel_test
# handshake_test
# udp_test
# xgmii_test
# udp_back_to_back_test
# -----------------------------
# Targets
# -----------------------------
.PHONY: all sim cbuild clean

all: sim

# C++ build
cbuild: 
	@echo "Building C++ frame executable..."
	$(CL) $(CPP_SRC) /LD /Fe:frame.dll $(CPP_FLAGS) $(CPP_INCLUDES) $(CPP_LINK_FLAGS)
	@del /Q frame.obj frame.lib frame.exp 2>nul

# Questa/UVM simulation
VSIM_ARGS ?=
sim: 
	@echo "Creating work library..."
	$(VLIB) $(WORKDIR)
	@echo "Compiling package..."
	$(VLOG) $(VLOG_FLAGS) $(PKG_SRC)
	@echo "Compiling RTL, interfaces, and top..."
	$(VLOG) $(VLOG_FLAGS) $(RTL_DIR)/*.v $(IFACES_DIR)/*.sv $(TOP_LEVEL)
	@echo "Running simulation..."
	@cls
	$(VSIM) -sv_lib $(FRAME_LIB) $(VSIM_FLAGS) $(VSIM_ARGS) $(TEST_NAME) $(WORKDIR).top -do "run -all"

# Clean all generated files
clean:
	@echo "Cleaning C++ artifacts..."
	del /Q $(CPP_EXE) frame.obj frame.lib frame.exp 2>nul
	@echo "Cleaning QuestaSim artifacts..."
	rmdir /S /Q $(WORKDIR) 2>nul
	del /Q w* *.log *.vcd *.wlf 2>nul
