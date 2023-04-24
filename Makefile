all:
	@make test
	@make lint

test:
	nvim --headless -c "PlenaryBustedDirectory tests/"

lint:
	luacheck --globals vim -- lua/
