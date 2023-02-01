install:
	@git submodule update --init --recursive

update:
	@forge update

# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

release:
	@release.sh

test:
	forge test

clean:
	@forge clean
