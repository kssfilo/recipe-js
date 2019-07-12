.SUFFIXES:

NAME=recipe-js
BINNAME=recipe
VERSION=1.0.0
DESCRIPTION=A gulp/GNU make like task launcher.Supports Dependencies/Inference Rules/Promise/Child Process/Cache/Deriving/CLI.
KEYWORDS=make build tool gulp task launcher Promise child_process cache CLI command-line stdin async async.js
NODEVER=8
LICENCE=MIT

PKGKEYWORDS=$(shell echo $$(echo $(KEYWORDS)|perl -ape '$$_=join("\",\"",@F)'))
PARTPIPETAGS="_@" "VERSION@$(VERSION)" "NAME@$(NAME)" "DESCRIPTION@$(DESCRIPTION)" 'KEYWORDS@$(PKGKEYWORDS)' "NODEVER@$(NODEVER)" "LICENSE@$(LICENSE)" 
#=

#=

DESTDIR=dist
COFFEES=$(wildcard *.coffee)
TARGETNAMES=$(patsubst %.coffee,%.js,$(COFFEES)) 
TARGETS=$(patsubst %,$(DESTDIR)/%,$(TARGETNAMES))
DOCNAMES=LICENSE README.md package.json
DOCS=$(patsubst %,$(DESTDIR)/%,$(DOCNAMES))
ALL=$(TARGETS) $(DOCS)
SDK=node_modules/.gitignore
TOOLS=node_modules/.bin

#=

COMMANDS=build help pack test clean clitest moduletests

.PHONY:$(COMMANDS)

default:build

build:$(TARGETS)

test:test.passed

clitest:$(ALL) clitests/test.bats
	cd clitests;./test.bats

moduletest:$(ALL)
	cd moduletests;../$(TOOLS)/coffee test.coffee

pack:$(ALL) test.passed|$(DESTDIR)

clean:
	rm -r $(DESTDIR) node_modules 2>&1 ;true

help:
	@echo "Targets:$(COMMANDS)"

#=

test.passed:clitest moduletest
	touch $@

$(DESTDIR):
	mkdir -p $@

$(DESTDIR)/%:% $(TARGETS) Makefile|$(SDK) $(DESTDIR)
	cat $<|$(TOOLS)/partpipe -c $(PARTPIPETAGS)  >$@

$(DESTDIR)/%.js:%.coffee $(SDK) |$(DESTDIR)
ifndef NC
	$(TOOLS)/coffee-jshint -o node $< 
endif
	head -n1 $<|grep '^#!'|sed 's/coffee/node/'  >$@ 
	cat $<|$(TOOLS)/partpipe $(PARTPIPETAGS) |$(TOOLS)/coffee -bcs >> $@
	chmod +x $@

$(SDK):package.json
	npm install
	@touch $@
