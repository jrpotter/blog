# jrpotter.github.io

## Quickstart

Personal Github Pages repository. The project is managed using nix. You can run
this project locally using:

```bash
$ nix develop
$ jekyll
...
$ exit
```

Alternatively, if you have [direnv](https://direnv.net/) installed and nix
[flakes](https://nixos.wiki/wiki/Flakes) enabled, you can run:

```bash
$ direnv allow  # one time only
...
$ jekyll
```

If making changes to the `Gemfile`, make sure to run `bundix -l` to update the
`gemset.nix` file. For reasons I'm not sure about yet, you may also need to run
`nix-collect-garbage` once beforehand.

## Notes

We can remove the `.bundle/config` file once this
[bundix PR](https://github.com/nix-community/bundix/pull/68) is merged.
