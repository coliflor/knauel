LUASTATIC ?= luastatic
LUA ?= lua5.1
LUA_INCLUDE ?= /usr/include/$(LUA)

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESKTOP_DIR ?= $(PREFIX)/share/applications

# important! first file is the name of the entry point
SRC = knauel.lua lib/knauel.lua lib/argparse.lua lib/file.lua

knauel:
	$(LUASTATIC) $(SRC) -l$(LUA) -I$(LUA_INCLUDE)
	@strip knauel

install:
	install -Dm775 knauel $(DESTDIR)$(BINDIR)/knauel

uninstall:
	rm -rf $(DESTDIR)$(BINDIR)/knauel

clean:
	rm -rf knauel.luastatic.c
	rm -rf knauel

.PHONY: knauel
