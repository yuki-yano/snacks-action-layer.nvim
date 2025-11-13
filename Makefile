STYLUA ?= stylua
LUA_DIRS ?= lua

.PHONY: format ci

format:
	$(STYLUA) $(LUA_DIRS)

ci:
	$(STYLUA) --check $(LUA_DIRS)
