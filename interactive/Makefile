.PHONY: all clean

# each build_NN.py writes website/static/courses/<lecture>/index.html
BUILDS := $(sort $(wildcard build_*.py))
PYTHON ?= python3

all:
	@for b in $(BUILDS); do echo "Building interactive $$b"; $(PYTHON) $$b || exit 1; done

clean:
	rm -f ../website/static/courses/*/index.html
