R := https://github.com/makeplus/makes
M := ../.cache/makes
$(shell [ -d '$M' ] || git clone -q $R '$M')

include $M/init.mk

PYTHON-VENV := $(ROOT)/venv
include $M/python.mk
include $M/perl.mk
include $M/clean.mk
include $M/shell.mk

export UV_LINK_MODE := copy
export UV_CACHE_DIR ?= $(LOCAL-CACHE)/uv
export NO_MKDOCS_2_WARNING := 1

REPO ?= git@github.com:in-1-cc/in-1

# Version to pin the served script to; when git can not describe one
# (no commits yet) the token is left in place, which the script
# treats as unpinned
IN1-VERSION := $(shell git -C .. describe --tags --always 2>/dev/null)
IN1-VERSION := $(or $(IN1-VERSION),@IN1_VERSION@)

DEPS := $(PYTHON-VENV)

# Files generated from ../rc with the version pin stamped in
GEN := docs/index.html docs/rc

MAKES-CLEAN += site $(GEN)
MAKES-REALCLEAN += $(PYTHON-VENV)

default::

site: $(DEPS) $(GEN)
	mkdocs build -d $@
	touch $@/.nojekyll

serve: $(DEPS) $(GEN) $(PERL)
	$Q port=$${PORT:-$$(perl -MIO::Socket::INET -e \
	  'print IO::Socket::INET->new( \
	     Listen => 1, LocalAddr => "127.0.0.1")->sockport')}; \
	mkdocs serve --livereload -a 127.0.0.1:$$port

publish: site
	cd $< && \
	  git init -q && \
	  git add -A && \
	  git commit -qm 'Deploy to production' && \
	  git push -f $(REPO) HEAD:gh-pages
	$(RM) -r $<

# FORCE so the pin is restamped on every build: IN1-VERSION tracks
# git HEAD, which changes on commits that never touch ../rc, so an
# mtime dependency alone would keep shipping a stale version pin
FORCE:

$(GEN): ../rc $(PERL) FORCE
	IN1_PIN='$(IN1-VERSION)' \
	  perl -pe 's/\@IN1_VERSION\@/$$ENV{IN1_PIN}/g' $< > $@
