# Standalone managed runtime for the Python release-installer tests.
M ?= repos/makes
include $M/init.mk
override MAKES_LOCAL_DIR := $(ROOT)/.cache/github-release-tests
include $M/github-release.mk

export PYTHONDONTWRITEBYTECODE := 1
export IN1_MAKES_REPO := $(MAKES)

test: $(PYTHON)
	$(PYTHON) $(MAKES)/test/github-release.py
	$(PYTHON) test/github-release.py
