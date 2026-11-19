OUT      := out
SRC      := src
STATIC   := static
JINJA    := jinja
PYTHON   ?= python3

# All pages, excluding src/templates
PAGES     := $(shell find $(SRC) -name '*.jinja' -not -path '$(SRC)/templates/*')
TEMPLATES := $(shell find $(SRC)/templates -name '*.jinja')

# src/index.jinja       -> out/index.html
# src/a/index.jinja     -> out/a/index.html
# src/other-page.jinja  -> out/other-page/index.html
NAMES   := $(PAGES:$(SRC)/%.jinja=%)
TARGETS := $(foreach n,$(NAMES),$(if $(filter index,$(notdir $(n))),$(OUT)/$(n).html,$(OUT)/$(n)/index.html))

.PHONY: all static clean run dev

all: $(TARGETS)

# Copy static files first. Pages depend on this order-only, so it always
# runs before compiling but doesn't force a rebuild of every page.
static:
	mkdir -p $(OUT)
	cp -R $(STATIC)/. $(OUT)/

# foo.jinja -> foo/index.html
$(OUT)/%/index.html: $(SRC)/%.jinja $(TEMPLATES) | static
	mkdir -p $(@D)
	$(JINJA) -o $@ $<

# index.jinja -> index.html (also covers a/index.jinja -> a/index.html)
$(OUT)/%.html: $(SRC)/%.jinja $(TEMPLATES) | static
	mkdir -p $(@D)
	$(JINJA) -o $@ $<

clean:
	rm -rf $(OUT)

run: all
	python -m http.server -d $(OUT)

dev: all
	$(PYTHON) -c "from livereload import Server; \
	s = Server(); \
	s.watch('src', 'make'); \
	s.watch('static', 'make'); \
	s.watch('Makefile', 'make'); \
	s.serve(root='$(OUT)', port=8000, open_url_delay=1)"
