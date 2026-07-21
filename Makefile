CC = gcc
CFLAGS = -Wall -c

# Define source and object files
SRC = libft/cc.c
OBJ = program.o

# Default target
program: $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o program

# Pattern rule for compiling .c to .o
%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

# Clean target
clean:
	rm -f program *.o
