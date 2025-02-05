TESTDIR ?= "prime/"

.PHONY: all
all: check

.PHONY: install
install:
	# install base
	set -ex; if [ -z "$(DESTDIR)" ]; then \
		echo "no DESTDIR set"; \
		exit 1; \
	fi
	mkdir -p $(DESTDIR)/install-data
	# customize
	set -eux; for f in ./hooks/[0-9]*.sh; do		\
		base="$$(basename "$${f}")";			\
		cp -a "$${f}" $(DESTDIR)/install-data/;		\
		sh -c "cd $(DESTDIR) && ./install-data/$${base}";	\
		rm "$(DESTDIR)/install-data/$${base}";		\
	done
	rm -rf $(DESTDIR)/install-data

.PHONY: check
check:
	# exclude "useless cat" from checks, while useless they also make
	# some code more readable
	shellcheck -e SC2002 hooks/*

.PHONY: test
test:
	# run tests - each hook should have a matching ".test" file
	set -ex; if [ ! -d $(TESTDIR) ]; then \
		echo "no $(TESTDIR) found, please build the tree first "; \
		exit 1; \
	fi
	set -ex; for f in $$(pwd)/hook-tests/[0-9]*.test; do \
			if !(cd $(TESTDIR) && $$f); then \
				exit 1; \
			fi; \
	    	done; \

