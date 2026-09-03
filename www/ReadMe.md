in-1 Website
============

This directory is the source for [in-1.cc](https://in-1.cc), the
website for the in-1 project.


## Built With

- [MkDocs](https://www.mkdocs.org/) static site generator
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
  theme
- [Makes](https://github.com/makeplus/makes) to auto-install Python
  and the tools

No prerequisites beyond a working `make` and `git`; Makes installs
everything else under `../.cache/`.


## Local Development

```bash
make serve
```

Auto-installs Python, sets up a venv, installs MkDocs, and starts a
livereload dev server on a random free port (set `PORT` to pick one).


## Build

```bash
make site
```

Output goes to `site/`.

The site root (`site/index.html`) is the sourceable `../rc` script
with its `@IN1_VERSION@` token stamped to the current
`git describe`, so `curl -sL in-1.cc` returns the installer while
browsers follow the meta-refresh comment to the docs.


## Publish

```bash
make publish
```

Builds the site and force-pushes it to the `gh-pages` branch of
`git@github.com:in-1-cc/in-1`, which GitHub Pages serves at
in-1.cc.
Push `main` first so the stamped version pin is reachable on the
remote.


## Copyright and License

Copyright 2026 by Ingy döt Net

This is free software, licensed under the MIT (X11) License.
See the [License](License) file.
