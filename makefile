SUBDIRS = flex symbol_table ast pcode acc

.PHONY: all clean $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	$(MAKE) -C flex clean
	$(MAKE) -C symbol_table clean
	$(MAKE) -C ast clean
	$(MAKE) -C pcode clean
	$(MAKE) -C acc clean
