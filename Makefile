.SUFFIXES:

NAME=recipe-js
BINNAME=recipe
VERSION=1.0.3
DESCRIPTION=A gulp/GNU make like task launcher with CLI tool.Supports Dependencies/Cache/Inference Rules/Promise/Child Process/Deriving/Scheduler.
KEYWORDS=make build tool gulp task launcher Promise child_process exec spawn cache CLI command-line stdin async scheduler
NODEVER=8
LICENSE=MIT

PKGKEYWORDS=$(shell echo $$(echo $(KEYWORDS)|perl -ape '$$_=join("\",\"",@F)'))
PARTPIPETAGS="_@" "VERSION@$(VERSION)" "NAME@$(NAME)" "BINNAME@$(BINNAME)" "DESCRIPTION@$(DESCRIPTION)" 'KEYWORDS@$(PKGKEYWORDS)' "NODEVER@$(NODEVER)" "LICENSE@$(LICENSE)" 
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

docs:$(DOCS)

test:test.passed

clitest:$(ALL) clitests/test.bats
	cd clitests;./test.bats

moduletest:$(ALL)
	cd moduletests;../$(TOOLS)/coffee test.coffee

pack:$(ALL) test.passed|$(DESTDIR)

clean:
	rm -r $(DESTDIR) test.passed node_modules 2>&1 ;true

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
