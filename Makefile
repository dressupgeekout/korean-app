data.lua: data.txt make_data.awk
	awk -f make_data.awk $< > $@
