LAB_NUM ?= 0
HW_NUM ?= 0

has_num=$(shell echo $(LAB_NUM) + $(HW_NUM) | bc)
ifeq ($(has_num), 0)
    $(error missing LAB_NUM or HW_NUM)
else ifeq ($(HW_NUM), 0)
    PREFIX = lab
    NUM = $(LAB_NUM)
else ifeq ($(LAB_NUM), 0)
    PREFIX = hw
    NUM = $(HW_NUM)
else
    $(error define either LAB_NUM or HW_NUM)
endif

LAB = $(PREFIX)$(NUM)

autograde:
	@mkdir -p autolab/autograde
	@cp autograde-Makefile autolab
	@sed -i "s/NUM = 0/NUM = $(NUM)/g" autolab/autograde-Makefile
	@sed -i "s/PREFIX = none/PREFIX = $(PREFIX)/g" autolab/autograde-Makefile

	@cp -a unpack.sh cc.sh run.py alignment.py driver_core.py driver.py ansi2html.sh autolab/autograde
	@cp $(LAB)_conf.py autolab/autograde/labconf.py
	@cp lab-Makefile autolab/autograde/Makefile
	@sed -i "s/NUM = 0/NUM = $(NUM)/g" autolab/autograde/Makefile
	@sed -i "s/PREFIX = none/PREFIX = $(PREFIX)/g" autolab/autograde/Makefile
	@cp -a tests_$(LAB) autolab/autograde/tests

	@tar -C autolab --exclude=\.directory -cf autolab/autograde.tar autograde
	@rm -rf autolab/autograde

prep:
	@cp $(LAB)submit.tar.gz autolab

test: autograde prep
	@make -s -C autolab -f autograde-Makefile |tee tmp |head -n-1
	@tail -n1 tmp |python -m json.tool
	@rm tmp

clean:
	@rm -rf autolab
