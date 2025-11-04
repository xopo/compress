odin=odin
src=compress
out=bin
FLAGS=-o:size -vet -strict-style

.PHONY: all run clean

all:
	@mkdir -p $(out)
	$(odin) build $(src) $(FLAGS)

run: all 
	./$(out)/app

clean:
	rm -rf $(out)
