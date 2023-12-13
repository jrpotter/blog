---
title: BoardWise
tags: [nixos, elixir, react]
github: https://github.com/boardwise-gg/website
---

A website for finding chess coaches across multiple chess sites. The
[coach-scraper](https://github.com/boardwise-gg/coach-scraper) project is
responsible for scraping coach data and streaming it into a Postgres instance
hosted alongside the website. The machine the site is hosted on is configured
from within [nixos-configuration](https://github.com/jrpotter/nixos-configuration).
