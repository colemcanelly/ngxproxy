# ── App discovery, top-level target, and includes ───────────────────────────────
CONFIG_OUT ?= dist/conf.d
CUSTOM_OUT ?= dist/custom
CONFIG ?= config
CONFIG_FILE := $(CONFIG)/proxy.yaml

export CONFIG_OUT
export CUSTOM_OUT

ENVSUBST_VARS := $${APP_HOST} $${APP_UPSTREAM} $${CUSTOM_NGINX_INCLUDE}

APPS != yq -r '[.[]?.[]?] | flatten | map(.name) | join(" ")' <$(CONFIG_FILE)
CONFS := $(patsubst %,$(CONFIG_OUT)/%.conf,$(APPS))
ENVS := $(patsubst %,dist/env/%.env,$(APPS))
DEPS := $(patsubst %,dist/deps/%.d,$(APPS))


.PHONY: all validate clean help
.SECONDARY: $(ENVS) $(DEPS)

all: $(CONFS)

-include $(DEPS)


# ── Compile rule ────────────────────────────────────────────────────
$(CONFIG_OUT)/%.conf: dist/env/%.env | $(CONFIG_OUT)
	@set -a; . ./$<; set +a; \
	 envsubst '$(ENVSUBST_VARS)' < $(filter templates/%,$^) > $@

# ── Dependencies ────────────────────────────────────────────────────
dist/deps/%.d: dist/env/%.env
	@test -s $@ || { \
	  echo "ERROR: $@ is missing or empty." >&2; \
	  exit 1; \
	}

dist/env/%.env &: $(CONFIG_FILE) | dist/env dist/deps
	@yq -r scripts/parse-config.yq $< | sh


$(CUSTOM_OUT)/%: $(CONFIG)/% | $(CUSTOM_OUT)
	@cp $< $@


dist: ; @mkdir -p dist
dist/env:		| dist ; @mkdir -p dist/env
dist/deps:		| dist ; @mkdir -p dist/deps
$(CONFIG_OUT):	| dist ; @mkdir -p $(CONFIG_OUT)
$(CUSTOM_OUT):	| dist ; @mkdir -p $(CUSTOM_OUT)

validate: all
	@sudo nginx -t -c $$(pwd)/nginx.conf
	@echo "Config OK."

clean:
	@rm -rf dist
	@echo "Cleaned dist."

help:
	@echo "Targets:"
	@echo "  all       Build conf.d/ from $(CONFIG_FILE)"
	@echo "  validate  Build + run nginx -t"
	@echo "  clean     Remove generated conf.d/"