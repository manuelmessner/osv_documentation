#
# Which mpost program
#
MP=$(shell which mpost)

#
# The graphic objects we have to compile
#
GRAPHICS=$(shell find $(GRAPHIC_DIR) -name '*.mp' -type f)

#
# The Objects which should be result from compiling the graphics
#
OBJS=$(foreach x, $(basename $(GRAPHICS)), $(x).1)

#
# The location of the graphic-to-tex script
#
GEN_TEST_PDF=$(GEN_DIR)/graphic_test_pdf.gen.sh

#
# Removeables
#
REMOVEABLE_EXT=1 log aux pdf graphic.tex

#
# Standard task
#
all: $(OBJS)

#
# Compiling one graphic to .1 file
#
%.1: %.mp
	@echo -e "\t[MP]\t$^"
	@$(MP) $^ >> $(MAKELOG)

#
# Test the graphics
#
test_graphic: $(OBJS)
	@$(GEN_TEST_PDF) $(OBJS)

#
# Clean this directory
#
clean:
	@for x in $(REMOVEABLE_EXT); do \
		echo -e "\t[RM] *.$$x";	\
		rm -f *.$$x;				\
	done
