# --- Variables ---
CC = gcc
BASE_CFLAGS = \
	-Wall -Wextra -pedantic -Wshadow -Wconversion -Wsign-compare \
	-Wformat=2 -Wundef -Wunreachable-code -Wlogical-op -Wfloat-equal \
	-Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations \
	-Wredundant-decls -Wattributes -Wbad-function-cast -Winline \
	-Wdeclaration-after-statement

# --- Build Configuration (Debug vs Release) ---
ifeq ($(DEBUG), 1)
	CFLAGS = $(BASE_CFLAGS) -g -O0 -std=c11
	BUILD_TYPE = Debug
else
	CFLAGS = $(BASE_CFLAGS) -O2 -std=c11
	BUILD_TYPE = Release
endif

# --- Optional: Treat warnings as errors ---
ifeq ($(WERROR), 1)
	CFLAGS += -Werror
endif

# --- Project Structure ---
SRCDIR = src
INCDIR = src
OBJDIR = obj
REPORTSDIR = reports
TARGET = libmonstera

# --- Output Directory ---
# 'make'呼び出し元から指定されなければ、一つ上の階層の 'libs' ディレクトリに出力
LIBSDIR_OUT ?= ../libs

# --- Auto-detection of Files ---
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SOURCES))
SHARED_LIB = lib$(TARGET).so
FINAL_LIB_PATH = $(LIBSDIR_OUT)/$(SHARED_LIB)

# --- Compiler & Linker Flags ---
CPPFLAGS = -I$(INCDIR)
# Position-Independent Code is required for shared libraries
LIB_CFLAGS = $(CFLAGS) -fPIC

# --- Rules ---
.PHONY: all clean distclean install check valgrind

# Default goal: build and install the shared library
all: $(FINAL_LIB_PATH)

# Rule to "install" (copy) the shared library to the output directory
$(FINAL_LIB_PATH): $(SHARED_LIB)
	@echo "==> Installing shared library to $(LIBSDIR_OUT)..."
	@mkdir -p $(LIBSDIR_OUT)
	@cp $< $@

# Rule to link the shared library
$(SHARED_LIB): $(OBJECTS)
	@echo "==> Creating shared library $@..."
	$(CC) $(LIB_CFLAGS) -shared -o $@ $^

# Rule to compile library source files
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@echo "==> Compiling library file $< ($(BUILD_TYPE) mode)..."
	@mkdir -p $(OBJDIR)
	$(CC) $(LIB_CFLAGS) $(CPPFLAGS) -c $< -o $@

# Rule to clean up object files
clean:
	@echo "==> Cleaning up library object files..."
	@rm -rf $(OBJDIR)

# Rule to clean up all generated files
distclean: clean
	@echo "==> Cleaning up library..."
	@rm -f $(SHARED_LIB)
	@rm -rf $(REPORTSDIR)
	# Note: This does NOT clean the installed file in LIBSDIR_OUT.
	# The top-level Makefile is responsible for that.

# --- Analysis Rules ---
check:
	@echo "==> Running static analysis on library with Cppcheck..."
	@mkdir -p $(REPORTSDIR)
	cppcheck --enable=all --inconclusive --std=c11 --suppress=missingIncludeSystem -I$(INCDIR) $(SRCDIR) 2> $(REPORTSDIR)/cppcheck.log

# Valgrind requires an executable to run.
# For a library, you'd typically have a test runner executable.
# This is a placeholder for how you might implement it.
valgrind:
	@echo "==> Valgrind for a library requires a test executable."
	@echo "==> Please create a 'test' target to build and run tests with Valgrind."
	# Example:
	# $(MAKE) test DEBUG=1
	# valgrind --leak-check=full ./test/test_runner
