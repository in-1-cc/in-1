# in-1 additions for clojure: keep the CLI's config, its classpath
# cache and the Maven repo (~/.clojure, ~/.m2) inside the install so
# a session install never touches the user's home directory.
# LOCAL-HOME is $(LOCAL-PREFIX)/home, set by makes' local.mk.

CLJ_CONFIG ?= $(LOCAL-HOME)/.clojure
CLJ_CACHE ?= $(CLJ_CONFIG)/.cpcache
CLJ_JVM_OPTS ?= -Duser.home=$(LOCAL-HOME)

export CLJ_CONFIG CLJ_CACHE CLJ_JVM_OPTS
