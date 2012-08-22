BINARY=rff
MINGW_BINARY=$(BINARY).exe
FLAGS=-Wall -O2
SRC_FILE=rff.c

all:
	gcc $(FLAGS) -o $(BINARY) $(SRC_FILE)

mingw:
	i686-w64-mingw32-gcc $(FLAGS) -DWIN32 -o $(MINGW_BINARY) $(SRC_FILE)

clean:
	rm -f $(BINARY) $(MINGW_BINARY)
