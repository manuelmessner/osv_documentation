#
# Makefile
#
# This makefile helps you building the document and testing the sources.
#

MAKE_FLAGS=--no-print-directory
export MAKE_FLAGS

#
# The latex compiler
#
LATEX=$(shell which pdflatex)
export LATEX

#
# The bibtex compiler
#
BIBTEXC=$(shell which bibtex)
export BIBTEXC

#
# Flags for the latex compilre
#
LATEX_FLAGS=-halt-on-error
export LATEX_FLAGS

#
# The latex source directory
#
LATEX_SOURCE=./main.tex

#
# The bibtex source
#
BIBTEX_SOURCE=./main

#
# The directory where scripts are located
#
SCRIPTS=$(PWD)/scripts
export SCRIPTS

#
# The directory where are the GRAPHICs
#
GRAPHIC_DIR=$(SCRIPTS)/graphic
export GRAPHIC_DIR

#
# The directory where are the generator scripts
#
GEN_DIR=$(SCRIPTS)/gen
export GEN_DIR

#
# removeable latex temporary files
#
LATEX_TMPFILES=aux log nav out snm toc vrb bbl blg idx lof lot

#
# Destination of the log from the make files
#
MAKELOG=$(PWD)/make.log
export MAKELOG

#
# The standard task, compiling the graphics and then compiling the latex source to a
# pdf document.
#
# We compile the sources three times, to be sure everything compiled correctly
#
all: graphics
	@echo -e "\t[LATEX]"
	@$(LATEX) $(LATEX_FLAGS) $(LATEX_SOURCE) >> $(MAKELOG)

	@echo -e "\t[BIBTEXC]"
	@$(BIBTEXC) $(BIBTEX_SOURCE) >> $(MAKELOG)

	@echo -e "\t[LATEX]"
	@$(LATEX) $(LATEX_FLAGS) $(LATEX_SOURCE) >> $(MAKELOG)

	@echo -e "\t[LATEX]"
	@$(LATEX) $(LATEX_FLAGS) $(LATEX_SOURCE) >> $(MAKELOG)

test: graphics
	@echo -e "\t[LATEX]"
	@$(LATEX) $(LATEX_FLAGS) $(LATEX_SOURCE) >> $(MAKELOG)

#
# Test the graphics by compiling them into several pdf files
#
test_graphics:
	@echo -e "\t[MAKE]\t$(GRAPHIC_DIR) test_graphic"
	@$(MAKE) $(MAKE_FLAGS) -C $(GRAPHIC_DIR) test_graphic

#
# Build the graphics
#
graphics: clean_graphics
	@echo -e "\t[MAKE] $(GRAPHIC_DIR)"
	@$(MAKE) $(MAKE_FLAGS) -C $(GRAPHIC_DIR)

#
# Remove everything except the target pdf file
#
nearly_clean: clean_graphics
	@for tmp in $(LATEX_TMPFILES);do	\
		echo -e "\t[RM] *.$$tmp";		\
		rm -f $$(find -name *.$$tmp);	\
	done
	@echo -e "\t[RM] $(MAKELOG)"
	@rm -f $(MAKELOG)

#
# Cleanup the graphics
#
clean_graphics:
	@echo -e "\t[MAKE]\t$(GRAPHIC_DIR) clean"
	@$(MAKE) $(MAKE_FLAGS) -C $(GRAPHIC_DIR) clean

#
# Clean everything
#
clean: nearly_clean
	@echo -e "\t[RM] *.pdf"
	@rm -f *.pdf
