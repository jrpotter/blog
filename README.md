# Blog

This is my personal blog, powered by [Jekyll](https://jekyllrb.com/) and themed
with [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy).

## Quickstart

If you have nix installed, you can use [direnv](https://direnv.net/) to launch a
dev shell upon entering this directory (refer to `.envrc`). Otherwise run via:
```bash
$ nix develop
$ bundle install
```

If you do not have nix installed, first install [rvm](https://rvm.io/rvm/install):
```bash
$ curl -sSL https://get.rvm.io | bash
$ type rvm | head -1
rvm is a function
```
Afterward, run the following sequence of commands:
```bash
$ rvm install 3.2.2
$ rvm use 3.2.2
$ gem install bundler:2.4.22
$ bundle install
```

Afterward you can launch the site locally by running:
```bash
bundle exec jekyll serve --watch
```

## Building

Dependencies are managed using [bundix](https://github.com/nix-community/bundix).
If you make any changes to the `Gemfile`, run the following:
```bash
$ bundle lock
$ bundix
```
This will update the `Gemfile.lock` and `gemset.nix` files respectively.
Afterward you can run:
```bash
$ nix build
```
Note that we need the `.bundle/config` file to workaround issues bundix has with
pre-built, platform-specific gems. Refer to
[PR #68](https://github.com/nix-community/bundix/pull/68) for more details.
