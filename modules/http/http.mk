http_SOURCES := http.lua prometheus.lua
http_INSTALL := $(wildcard modules/http/http/*)
$(call make_lua_module,http)
