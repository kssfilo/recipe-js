.SUFFIXES:

VERSION=0.5.4

#=

COMMANDS=help pack test clean moduletests

#=

DESTDIR=dist
COFFEES=$(wildcard *.coffee)
TARGETNAMES=package.json LICENSE $(patsubst %.coffee,%.js,$(COFFEES)) 
TARGETS=$(patsubst %,$(DESTDIR)/%,$(TARGETNAMES))
ALL=$(TARGETS) $(DESTDIR)/README.md
SDK=node_modules/.gitignore
TOOLS=node_modules/.bin

#=

.PHONY:$(COMMANDS)

test:clitest moduletest

clitest:$(ALL) clitests/test.bats
	cd clitests;./test.bats

moduletest:$(ALL)
	cd moduletests;./test.coffee

pack:$(ALL)|$(DESTDIR)

clean:
	-rm -r $(DESTDIR) node_modules

help:
	@echo "Targets:$(COMMANDS)"

#=

$(DESTDIR):
	mkdir -p $@

$(DESTDIR)/README.md:README.md $(TARGETS) $(SDK)
	cat README.md|$(TOOLS)/partpipe >$@

$(DESTDIR)/package.json:package.json $(SDK) Makefile|$(DESTDIR)
	cat $<|$(TOOLS)/partpipe VERKEY@version VERSION@$(VERSION) >$@

$(DESTDIR)/%.js:%.coffee $(SDK) |$(DESTDIR)
ifndef NC
	$(TOOLS)/coffee-jshint -o node $< 
endif
	head -n1 $<|grep '^#!'|sed 's/coffee/node/'  >$@ 
	cat $<|$(TOOLS)/partpipe VERSION@$(VERSION) |$(TOOLS)/coffee -bcs >> $@
	chmod +x $@

$(DESTDIR)/%:%|$(DESTDIR)
	cp $< $@

$(SDK):package.json
	npm install
	@touch $@
