.PHONY: help check smoke shellcheck install test

help:
	@echo "targets: check smoke shellcheck install test"

check: shellcheck smoke

smoke:
	chmod +x bin/pk install.sh tests/smoke.sh
	./tests/smoke.sh

shellcheck:
	shellcheck -x -e SC1091,SC2015,SC2016,SC2001,SC2012 bin/pk install.sh lib/*.sh tests/smoke.sh

install:
	./install.sh

test: check
