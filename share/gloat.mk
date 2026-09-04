# The wrapper tells gloat where it lives, so gloat knows the shell is
# set up and skips its "source .../.rc" hint
GLOAT_ROOT := $(GLOAT-DIR)
export GLOAT_ROOT
