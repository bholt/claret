.PHONY: all
all: claret.pdf

dolphins.pdf: dolphins.tex	
	sed -i.bak 's/\\includegraphics{}//' $^
	rm $^.bak
	pdflatex $^

claret.tex: claret.md
	pandoc --filter pandoc-citeproc -S --standalone --template=resources/plos-one.latex -o $@ $<

%.pdf: %.tex
	pdflatex $^
	bibtex $(basename $^)
	pdflatex $^
	pdflatex $^

