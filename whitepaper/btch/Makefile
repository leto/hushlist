protocol.pdf: protocol.tex hush.bib
	$(MAKE) pdf

LATEX=pdflatex

.PHONY: pdf
pdf:
	printf '\\renewcommand{\\docversion}{Version %s}' "$$(git describe --tags --abbrev=6)" |tee protocol.ver
	# If $(LATEX) fails, touch an input so that 'make' won't think it is up-to-date next time.
	rm -f protocol.aux protocol.bbl protocol.blg protocol.brf protocol.bcf
	$(LATEX) protocol.tex
	biber protocol
	$(LATEX) protocol.tex
	$(LATEX) protocol.tex
	$(LATEX) protocol.tex 
.PHONY: clean
clean:
	rm -f protocol.dvi protocol.pdf protocol.bbl protocol.blg protocol.brf protocol.toc protocol.aux protocol.out protocol.log protocol.bcf protocol.run.xml protocol.ver
