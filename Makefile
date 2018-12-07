LAB_PREFIX = lab
LAB_NUM ?= 0
LAB = $(LAB_PREFIX)$(LAB_NUM)

autograde:
	@mkdir -p autolab/autograde
	@cp autograde-Makefile $(LAB)submit.tar.gz autolab
	@sed -i "s/LAB_NUM = 0/LAB_NUM = $(LAB_NUM)/g" autolab/autograde-Makefile

	@cp -a unpack.sh cc.sh run.py alignment.py driver_core.py driver.py ansi2html.sh autolab/autograde
	@cp $(LAB)_conf.py autolab/autograde/labconf.py
	@cp lab-Makefile autolab/autograde/Makefile
	@sed -i "s/LAB_NUM = 0/LAB_NUM = $(LAB_NUM)/g" autolab/autograde/Makefile
	@cp -a tests_$(LAB) autolab/autograde/tests

	@tar -C autolab --exclude=\.directory -cf autolab/autograde.tar autograde
	@rm -rf autolab/autograde

test:
	@make -s -C autolab -f autograde-Makefile |tee tmp |head -n-1
	@tail -n1 tmp |python -m json.tool
	@rm tmp

clean:
	@rm -rf autolab
