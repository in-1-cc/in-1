# Per-tool overrides for the install directory that in-1 reports on
# its success line.
#
# By default in-1 reports the bin directory of a tool's primary
# makes SHELL-DEPS target, which is right for almost everything.
# For a tool where that is wrong, override IN1-BIN here, keyed on
# IN1-TOOL (the tool being installed).  Any makes variable from the
# tool's <tool>.mk is in scope.
#
# Example: report rust's shim directory explicitly.
#
#   ifeq ($(IN1-TOOL),rust)
#   IN1-BIN := $(CARGO-BIN)
#   endif
