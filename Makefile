# $Id$

HTML	= 	help.html history.html widget-helper.html

TOHTML	=	./tohtml.rb
TOHTML_JA=	$(TOHTML) ./tohtml.conf.ja ./template.html.ja
TOHTML_EN=	$(TOHTML) ./tohtml.conf.en ./template.html.en

all: $(HTML)

%.html: %.hikidoc links.hikidoc $(TOHTML_JA)
	$(TOHTML) $< > $@

%.html.ja: %.hikidoc.ja $(TOHTML_JA)
	$(TOHTML) $< > $@

%.html.en: %.hikidoc.en $(TOHTML_EN)
	$(TOHTML) $< > $@
