.PHONY: all clean

# each build_NN.py writes website/static/courses/<lecture>/index.html,
# then build_index.py writes the main page website/static/courses/index.html
BUILDS := $(sort $(wildcard build_[0-9][0-9].py)) build_index.py
# uv (pyproject.toml + uv.lock) when installed, else the system python3 with Pillow
PYTHON ?= $(if $(shell command -v uv),uv run python,python3)

all:
	@for b in $(BUILDS); do echo "Building interactive $$b"; $(PYTHON) $$b || exit 1; done

clean:
	rm -f ../website/static/courses/*/index.html ../website/static/courses/index.html
