LAB ?= 0
HW ?= 0

has_num=$(shell echo $(LAB) + $(HW) | bc)
ifeq ($(has_num), 0)
    $(error missing LAB or HW)
else ifeq ($(HW), 0)
    PREFIX = lab
    NUM = $(LAB)
else ifeq ($(LAB), 0)
    PREFIX = hw
    NUM = $(HW)
else
    $(error define either LAB or HW)
endif

NAME = $(PREFIX)$(NUM)

autograde:
	@mkdir -p autolab/autograde
	@cp autograde-Makefile autolab
	@sed -i "s/NUM = 0/NUM = $(NUM)/g" autolab/autograde-Makefile
	@sed -i "s/PREFIX = none/PREFIX = $(PREFIX)/g" autolab/autograde-Makefile

	@cp -a unpack.sh colors.conf cc.sh ansi2html.sh autolab/autograde
	@cp -a run.py alignment.py driver_core.py driver.py autolab/autograde
	@cp $(NAME)_conf.py autolab/autograde/labconf.py
	@cp lab-Makefile autolab/autograde/Makefile
	@sed -i "s/NUM = 0/NUM = $(NUM)/g" autolab/autograde/Makefile
	@sed -i "s/PREFIX = none/PREFIX = $(PREFIX)/g" autolab/autograde/Makefile
	@cp -a tests_$(NAME) autolab/autograde/tests

	@tar -C autolab --exclude=\.directory -cf autolab/autograde.tar autograde
	@rm -rf autolab/autograde

prep:
	@cp $(NAME)submit.tar.gz autolab

test: autograde prep
	@make -s -C autolab -f autograde-Makefile |tee tmp |head -n-1
	@tail -n1 tmp |python -m json.tool
	@rm tmp

clean:
	@rm -rf autolab
