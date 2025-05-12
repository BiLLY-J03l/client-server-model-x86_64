# Compiler and flags
NASM = nasm
GCC = gcc
NASMFLAGS = -f elf64
GCCFLAGS = -no-pie

# File names
ASM_SRC = client.asm
OBJ_FILE = client.o
EXEC_FILE = client

# Targets
all: $(EXEC_FILE)

# Rule to assemble the assembly file
$(OBJ_FILE): $(ASM_SRC)
	$(NASM) $(NASMFLAGS) $(ASM_SRC) -o $(OBJ_FILE)

# Rule to link the object file into the executable
$(EXEC_FILE): $(OBJ_FILE)
	$(GCC) $(GCCFLAGS) $(OBJ_FILE) -o $(EXEC_FILE)

# Clean up the generated files
clean:
	rm -f $(OBJ_FILE) $(EXEC_FILE)

# Phony targets (these aren't real files)
.PHONY: all clean

