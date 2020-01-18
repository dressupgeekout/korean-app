vocab.lua: vocab.txt make_vocab.awk
	awk -f make_vocab.awk $< > $@
