MAKEFLAGS+="-j $$(nprocs)"
EVENTS = push release

.PHONY: all
all: $(EVENTS)

.PHONY: watch
watch: push
	fswatch -or . | xargs -n 1 -I{} act $<

.PHONY: push release
push release:
	act $@
