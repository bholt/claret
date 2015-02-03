
PDFLATEX	?= pdflatex -halt-on-error -file-line-error
BIBTEX		?= bibtex
PANDOC    ?= pandoc --natbib -S --standalone

ifneq ($(QUIET),)
PDFLATEX	+= -interaction=batchmode
ERRFILTER	:= > /dev/null || (egrep ':[[:digit:]]+:' *.log && false)
BIBTEX		+= -terse
else
PDFLATEX	+= -interaction=nonstopmode
ERRFILTER=
endif


.PHONY: all
all: claret.pdf

claret.tex: claret.md resources/template.tex Makefile
	$(PANDOC) --template=resources/template.tex -o $@ $<

%.pdf: %.tex
	$(PDFLATEX) $^
	$(BIBTEX) $(basename $^)
	$(PDFLATEX) $^
	$(PDFLATEX) $^
