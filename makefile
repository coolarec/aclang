SUBDIRS = flex symbol_table ast pcode

.PHONY: all clean $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	$(MAKE) -C lexical clean
	$(MAKE) -C syntax clean
	$(MAKE) -C semantic clean
	$(MAKE) -C pcode clean
