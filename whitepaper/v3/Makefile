hush-v3.pdf: hush-v3.tex hush.bib
	$(MAKE) pdf

LATEX=pdflatex

.PHONY: pdf
pdf:
	printf '\\renewcommand{\\docversion}{Version %s}' "$$(git describe --tags --abbrev=6)" |tee hush-v3.ver
	# If $(LATEX) fails, touch an input so that 'make' won't think it is up-to-date next time.
	rm -f hush-v3.aux hush-v3.bbl hush-v3.blg hush-v3.brf hush-v3.bcf
	$(LATEX) hush-v3.tex
	biber hush-v3
	$(LATEX) hush-v3.tex
	$(LATEX) hush-v3.tex
	$(LATEX) hush-v3.tex 
.PHONY: clean
clean:
	rm -f hush-v3.dvi hush-v3.pdf hush-v3.bbl hush-v3.blg hush-v3.brf hush-v3.toc hush-v3.aux hush-v3.out hush-v3.log hush-v3.bcf hush-v3.run.xml hush-v3.ver
