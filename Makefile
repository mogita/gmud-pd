# Playdate SDK Makefile for gmud-pd

# Variables
PRODUCT = gmud-pd.pdx
SOURCE_DIR = source
BUILD_DIR = builds
MAIN_FILE = $(SOURCE_DIR)/main.lua
OUTPUT = $(BUILD_DIR)/$(PRODUCT)

# Detect Playdate SDK path
PLAYDATE_SDK_PATH ?= $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)

# Playdate compiler
PDC = "$(PLAYDATE_SDK_PATH)/bin/pdc"

# Playdate Simulator (macOS)
SIMULATOR = "$(PLAYDATE_SDK_PATH)/bin/Playdate Simulator.app"

# Detect OS for simulator launch
OS := $(shell uname)

# Default target
.PHONY: all
all: build

# Build the game
.PHONY: build
build:
	@echo "Compiling..."
	@mkdir -p $(BUILD_DIR)
	$(PDC) --main -sdkpath "$(PLAYDATE_SDK_PATH)" "$(MAIN_FILE)" "$(OUTPUT)"

# Build and run the game
.PHONY: run
run: build
	@echo "Starting Playdate Simulator..."
ifeq ($(OS), Darwin)
	@/usr/bin/open -a $(SIMULATOR) "$(OUTPUT)"
else ifeq ($(OS), Linux)
	@$(PLAYDATE_SDK_PATH)/bin/PlaydateSimulator $(OUTPUT)
else
	@$(PLAYDATE_SDK_PATH)/bin/PlaydateSimulator.exe $(OUTPUT)
endif

# Build for debugging (same as build, debugging is handled by VSCode extension)
.PHONY: debug
debug: build
	@echo "Build ready for debugging"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete"

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build  - Build the game to $(OUTPUT)"
	@echo "  run    - Build and run the game in Playdate Simulator"
	@echo "  debug  - Build the game for debugging (use with VSCode debugger)"
	@echo "  clean  - Remove build artifacts"
	@echo "  help   - Show this help message"
