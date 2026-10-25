NAME     := my-linux-t248r-panel
APP_ID   := io.github.tapuuk.T248RPanel
VERSION  := $(shell sed -n 's/^VERSION = "\(.*\)"/\1/p' t248rpanel/__init__.py)

PREFIX     ?= /usr
BINDIR     ?= $(PREFIX)/bin
LIBDIR     ?= $(PREFIX)/lib/$(NAME)
DATADIR    ?= $(PREFIX)/share
POLKITDIR  ?= $(DATADIR)/polkit-1/actions
LICENSEDIR ?= $(DATADIR)/licenses/$(NAME)
DESTDIR    ?=

PYTHON  ?= python3
QMLLINT ?= $(firstword $(wildcard /usr/lib/qt6/bin/qmllint /usr/lib64/qt6/bin/qmllint /usr/lib/x86_64-linux-gnu/qt6/bin/qmllint /usr/libexec/qt6/qmllint) $(shell command -v qmllint6 pyside6-qmllint 2>/dev/null))

# The QML reads context properties set from Python, which qmllint can't see.
QMLLINT_FLAGS ?= --unqualified disable

DISTDIR   := dist
DISTNAME  := $(NAME)-$(VERSION)
DISTFILES := launcher.py Makefile LICENSE t248rpanel helper/t248r-panel-helper data packaging
SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct 2>/dev/null || date +%s)

.PHONY: all install uninstall dist run check clean arch deb rpm

all:
	@echo "Targets: install, uninstall, dist, run, check, arch, deb, rpm, clean"

install:
	@test -n "$(VERSION)" || { echo "could not read VERSION from t248rpanel/__init__.py"; exit 1; }
	install -d "$(DESTDIR)$(LIBDIR)/t248rpanel"
	cd t248rpanel && find . -name __pycache__ -prune -o -type f ! -name '*.py[co]' -print \
		| while IFS= read -r f; do install -Dm644 "$$f" "$(DESTDIR)$(LIBDIR)/t248rpanel/$$f" || exit 1; done
	install -Dm644 launcher.py "$(DESTDIR)$(LIBDIR)/launcher.py"
	install -Dm755 helper/t248r-panel-helper "$(DESTDIR)$(LIBDIR)/t248r-panel-helper"
	install -d "$(DESTDIR)$(BINDIR)"
	printf '#!/bin/sh\nexec python3 %s/launcher.py "$$@"\n' "$(LIBDIR)" > "$(DESTDIR)$(BINDIR)/$(NAME)"
	chmod 755 "$(DESTDIR)$(BINDIR)/$(NAME)"
	install -Dm644 data/$(APP_ID).desktop "$(DESTDIR)$(DATADIR)/applications/$(APP_ID).desktop"
	install -Dm644 data/$(APP_ID).svg "$(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(APP_ID).svg"
	install -Dm644 data/$(APP_ID).metainfo.xml "$(DESTDIR)$(DATADIR)/metainfo/$(APP_ID).metainfo.xml"
	install -d "$(DESTDIR)$(POLKITDIR)"
	sed 's|/usr/lib/$(NAME)/|$(LIBDIR)/|' data/$(APP_ID).policy > "$(DESTDIR)$(POLKITDIR)/$(APP_ID).policy"
	chmod 644 "$(DESTDIR)$(POLKITDIR)/$(APP_ID).policy"
	install -Dm644 LICENSE "$(DESTDIR)$(LICENSEDIR)/LICENSE"

uninstall:
	rm -rf "$(DESTDIR)$(LIBDIR)" "$(DESTDIR)$(LICENSEDIR)"
	rm -f "$(DESTDIR)$(BINDIR)/$(NAME)" \
		"$(DESTDIR)$(DATADIR)/applications/$(APP_ID).desktop" \
		"$(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(APP_ID).svg" \
		"$(DESTDIR)$(DATADIR)/metainfo/$(APP_ID).metainfo.xml" \
		"$(DESTDIR)$(POLKITDIR)/$(APP_ID).policy"

# Reproducible source tarball. Leaves out notes/ and windows-driver/ on purpose.
dist:
	@test -n "$(VERSION)" || { echo "could not read VERSION from t248rpanel/__init__.py"; exit 1; }
	mkdir -p $(DISTDIR)
	tar --exclude=__pycache__ --exclude='*.py[co]' \
		--sort=name --owner=0 --group=0 --numeric-owner --mtime=@$(SOURCE_DATE_EPOCH) \
		--mode='u+rwX,go+rX,go-w' --transform 's,^,$(DISTNAME)/,' \
		-cf - $(DISTFILES) | gzip -9n > $(DISTDIR)/$(DISTNAME).tar.gz
	@echo $(DISTDIR)/$(DISTNAME).tar.gz

run:
	$(PYTHON) launcher.py

check:
	PYTHONPYCACHEPREFIX="$$(mktemp -d)" $(PYTHON) -m py_compile launcher.py helper/t248r-panel-helper $$(find t248rpanel -name '*.py')
	@if [ -n "$(QMLLINT)" ]; then \
		echo "$(QMLLINT)"; find t248rpanel/qml -name '*.qml' -print0 | xargs -0 -r "$(QMLLINT)" $(QMLLINT_FLAGS); \
	else echo "qmllint not found, skipping QML check"; fi

arch: dist
	cd packaging/arch && SRCDEST="$(abspath $(DISTDIR))" PKGDEST="$(abspath $(DISTDIR))" \
		BUILDDIR="$(abspath $(DISTDIR))/archbuild" makepkg -f --cleanbuild

deb:
	packaging/deb/build-deb.sh $(DISTDIR)

rpm: dist
	rpmbuild -bb packaging/rpm/$(NAME).spec \
		--define "_sourcedir $(abspath $(DISTDIR))" --define "_rpmdir $(abspath $(DISTDIR))"

clean:
	rm -rf $(DISTDIR)
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
