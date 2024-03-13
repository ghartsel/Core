# Project Settings
debug ?= 0
SRC_DIR := ./src
BUILD_DIR := ./build
INCLUDE_DIR := ./include
TESTS_DIR := ./tests
BIN_DIR := ./bin

# Executable settings
CORE := core
CORE_ARGS_0 := --help
CORE_ARGS_1 := -u 0 -m / -c "/bin/bash -c" -a exit
CORE_ARGS_2 := -u 0 -m / -c "/bin/bash -c" -a exit -v

# Core object files
OBJS := $(CORE).o

# Compiler settings
CC := clang-18
LINTER := clang-tidy-18
DEBUGGER := lldb-18
DISASSEMBLER := llvm-objdump-18

# Compiler and Linker flags Settings:
#   -std=gnu17: Use the GNU17 standard
#   -D _GNU_SOURCE: Use GNU extensions
#   -D __STDC_WANT_LIB_EXT1__: Use C11 extensions
#   -Wall: Enable all warnings
#   -Wextra: Enable extra warnings
#   -pedantic: Enable pedantic warnings
#   -I$(INCLUDE_DIR): Include the include directory
#   -lcap: Link to libcap
#   -lseccomp: Link to libseccomp
#   -lm: Link to libm
CFLAGS := -std=gnu17 -D _GNU_SOURCE -D __STDC_WANT_LIB_EXT1__ -Wall -Wextra -pedantic -I$(INCLUDE_DIR)
LFLAGS := -lcap -lseccomp -lm

ifeq ($(debug), 1)
    CFLAGS := $(CFLAGS) -g -O0
else
    CFLAGS := $(CFLAGS) -Oz
endif

# Targets

# Build core executable
$(CORE): lint dir $(OBJS)
	$(CC) $(CFLAGS) $(LFLAGS) -o $(BIN_DIR)/$(CORE) $(foreach file,$(OBJS),$(BUILD_DIR)/$(file))

# Build object files
%.o: dir $(SRC_DIR)/%.c
	@$(CC) $(CFLAGS) -o $(BUILD_DIR)/$*.o -c $(SRC_DIR)/$*.c

# Run CUnit tests
test: dir
	@$(CC) $(CFLAGS) -lcunit -o $(BIN_DIR)/$(CORE)_test $(TESTS_DIR)/$(CORE)_test.c
	@$(BIN_DIR)/$(CORE)_test

# Run linter on source directories
lint:
	@$(LINTER) --config-file=.clang-tidy $(SRC_DIR)/* $(INCLUDE_DIR)/* -- $(CFLAGS)

# Run valgrind memory checker on executable
check: $(CORE)
	@sudo valgrind -s --leak-check=full --show-leak-kinds=all $(BIN_DIR)/$(CORE) $(CORE_ARGS_0)
	@sudo valgrind -s --leak-check=full --show-leak-kinds=all $(BIN_DIR)/$(CORE) $(CORE_ARGS_1)
	@sudo valgrind -s --leak-check=full --show-leak-kinds=all $(BIN_DIR)/$(CORE) $(CORE_ARGS_2)

# Setup dependencies for build and development
setup:
	# Update apt and upgrade packages
	@sudo apt update
	@sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

	# Install OS dependencies
	@sudo apt install -y bash libarchive-tools lsb-release wget software-properties-common gnupg

	# Install LLVM tools required for building the project
	@wget https://apt.llvm.org/llvm.sh
	@chmod +x llvm.sh
	@sudo ./llvm.sh 18
	@rm llvm.sh

	# Install Clang development tools
	@sudo apt install -y clang-format-18 clang-tidy-18 clang-tools clangd valgrind

	# Install non-standard system libraries
	@sudo apt install -y libseccomp-dev libcap-dev

	# Install CUnit testing framework
	@sudo apt install -y libcunit1 libcunit1-doc libcunit1-dev

	# Cleanup
	@sudo apt autoremove -y

# Setup build and bin directories
dir:
	@mkdir -p $(BUILD_DIR) $(BIN_DIR)

# Clean build and bin directories
clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR)

.PHONY: lint check setup dir clean deps
