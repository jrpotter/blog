all:
	@echo "You must specify a specific build task."

bookshelf:
	git -C _bookshelf pull
	-rm -r lean
	${MAKE} -C _bookshelf docs!
	cp -r _bookshelf/build/doc lean
