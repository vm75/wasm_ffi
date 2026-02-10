.PHONY: version build run test

version:
	bash ./tool/update-version.sh

build:
	cd example_flutter && make clean && make build

run-dart:
	cd example && make run

run-flutter:
	cd example_flutter && make run

test:
	dart run build_runner test -- -p chrome