autograde:
	mkdir -p autolab/autograde
	cp autograde-Makefile lab2submit.tar.gz autolab

	cp -r unpack.sh run.sh driver.sh colors.conf lab.conf bin tests autolab/autograde
	cp lab-Makefile autolab/autograde/Makefile

	tar -C autolab -cvf autolab/autograde.tar autograde --exclude=\.directory
	rm -rf autolab/autograde

test:
	make -C autolab -f autograde-Makefile

clean:
	rm -rf autolab
