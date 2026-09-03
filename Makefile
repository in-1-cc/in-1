R := https://github.com/makeplus/makes
M := .cache/makes
$(shell [ -d '$M' ] || git clone -q $R '$M')

include $M/init.mk

export MAKES_LOCAL_DIR := $(ROOT)/.cache/local

include $M/perl.mk
include $M/bpan.mk
include $M/shellcheck.mk
include $M/clean.mk

# md2man.mk pulls in go.mk, so only load it when building the man page
ifneq (,$(filter manpage man/man1/in-1.1,$(MAKECMDGOALS)))
include $M/md2man.mk
endif

include $M/shell.mk

MAKES-CLEAN += www/site www/docs/index.html www/docs/rc
MAKES-REALCLEAN += .cache/

SHELL-FILES := rc .rc bin/in-1 $(wildcard share/*.sh share/*.bash)

v ?=
t ?= test/*.t

test: $(PERL) $(BPAN) shellcheck
	prove -r$(if $v, -v,) $t

shellcheck: $(SHELLCHECK)
	shellcheck $(SHELL-FILES)

manpage: man/man1/in-1.1

man/man1/in-1.1: doc/in-1.md $(MD2MAN)
	@mkdir -p $(dir $@)
	go-md2man -in $< -out $@

site serve publish:
	$Q $(MAKE) -C www $@

clean realclean distclean::
	$(MAKE) -C www $@
