SUBDIRS=arttools blud2b rff sfx2wav

all:
	$(MAKE) MAKE_CMD="" recursive

clean:
	$(MAKE) MAKE_CMD="clean" recursive

recursive:
	for i in $(SUBDIRS) ; do \
		cd "$$i" && make $(MAKE_CMD) && cd .. ; \
	done
