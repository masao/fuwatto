# $Id$

HTML	= 	help.html history.html widget-helper.html

TOHTML =	./tohtml.rb
TOHTML_JA=$(TOHTML) ./tohtml.conf.ja ./template.html.ja
TOHTML_EN=$(TOHTML) ./tohtml.conf.en ./template.html.en

all: $(HTML)

%.html: %.hikidoc $(TOHTML_JA)
	./tohtml.rb $< > $@

%.shtml: %.hikidoc $(TOHTML_JA)
	./tohtml.rb $< > $@

%.html.ja: %.hikidoc.ja $(TOHTML_JA)
	./tohtml.rb $< > $@

%.html.en: %.hikidoc.en $(TOHTML_EN)
	./tohtml.rb $< > $@
