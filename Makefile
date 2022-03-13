TARGETS?=main.asm
OBJECTS=$(TARGETS:.asm=.o)
EXECUTABLE=$(TARGETS:.asm=)

all: $(OBJECTS) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	ld -o $(EXECUTABLE) $(OBJECTS)

$(OBJECTS): $(TARGETS)
	nasm -f elf64 -g $(TARGETS) -o $(OBJECTS)

obj: $(TARGETS)
	nasm -f elf64 -g $(TARGETS) -o $(OBJECTS)