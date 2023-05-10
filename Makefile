all:
	@echo "You must specify a specific build task."

bookshelf:
	git -C _bookshelf pull
	-rm -r {lean,_bookshelf/build/doc}
	(cd _bookshelf && lake build Bookshelf:docs)
	cp -r _bookshelf/build/doc lean
