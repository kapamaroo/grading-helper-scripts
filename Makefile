autograde:
	@mkdir -p autolab/autograde
	@cp autograde-Makefile lab2submit.tar.gz autolab

	@cp -r unpack.sh cc.sh run.py driver.sh driver-html.sh colors.conf lab.conf bin tests ansi2html.sh autolab/autograde
	@cp lab-Makefile autolab/autograde/Makefile

	@tar -C autolab --exclude=\.directory -cf autolab/autograde.tar autograde
	@rm -rf autolab/autograde

test:
	@make -s -C autolab -f autograde-Makefile |tee tmp |head -n-1
	@tail -n1 tmp |python -m json.tool
	@rm tmp

clean:
	@rm -rf autolab
