# jrpotter.github.io

This is my personal blog, powered by [Jekyll](https://jekyllrb.com/) and themed
with [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme.

## Quickstart

To run, first install [rvm](https://rvm.io/rvm/install) and confirm the
installation was successful:

```bash
> curl -sSL https://get.rvm.io | bash
> type rvm | head -1
rvm is a function
```

Afterward, run the following sequence of commands:

```bash
> rvm install 2.7.8
> rvm use 2.7.8
> bundle install
> gem install jekyll
> jekyll serve --watch
```

## Bookshelf

This project also hosts an instance of [bookshelf](https://github.com/jrpotter/bookshelf).
To replace the current collection of static files comprising a version of
`bookshelf`, run the following:

```bash
> rm -r {bookshelf,_bookshelf/build/doc}
> (cd _bookshelf && lake build Bookshelf:docs)
> cp -r _bookshelf/build/doc bookshelf
> rm -r bookshelf/LaTeX/preamble
```
