.PHONY: clean

SUBDIRS := $(shell find src -maxdepth 1 -mindepth 1 -type d | sort)
SLIDES := $(notdir $(SUBDIRS))

all: $(SLIDES)

$(foreach S,$(SLIDES), \
  $(eval FILES_$(S) := $(wildcard src/$(S)/*)) \
  $(eval $(S): $$(FILES_$(S))) \
  $(eval $(S): ; @echo "Building slides $(S)"; mkdir -p build; typst compile --root . src/$(S)/main.typ build/iso_$(S).pdf ) \
)

$(foreach S,$(SLIDES), \
  $(eval FILES_$(S) := $(wildcard src/$(S)/*)) \
  $(eval watch_$(S): $$(FILES_$(S))) \
  $(eval watch_$(S): ; @echo "Building slides $(S)"; mkdir -p build; typst watch --root . src/$(S)/main.typ build/iso_$(S).pdf ) \
)

clean:
	rm -rf build
