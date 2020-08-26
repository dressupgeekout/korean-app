.PHONY: all
all: vocab.lua

vocab.lua: vocab.txt make_vocab.awk
	awk -f make_vocab.awk $< > $@

.PHONY: clean
clean:
	rm -f vocab.lua
