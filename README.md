# WORK IN PROGRESS, DO NOT USE (yet ;))

# fdcli

A visual command-line client for [Flowdock](https://www.flowdock.com) with
roughly vi/mutt like key bindings and mouse support.

# Install

* `gem install fdcli` (maybe with sudo)
* `mkdir -p ~/.config/fdcli`
* go to https://www.flowdock.com/account/tokens, copy your personal API token
* create `~/.config/fdcli/config` and copy the token and your flowdock
  "organisation" name into it:

    org: your-flowdock-org-name
    token: b8227198b8ef6c57e2f55e34c3722706

# Usage

  fdcli

# Files

* it saves all stuff to `~/.config/fdcli`, most of it is in tab-separated
  format with a header line
* there's a log at `~/.config/fdcli/fdcli.log` (cleared on every run)

# Bugs

It will probably not work on Windows but who cares.

The normal `ncurses` works but doesn't handle UTF-8 correctly, you'll need to
link ruby to `ncursesw`. What seems to work on Debian is doing

    sudo apt-get install libncursesw5 libncursesw5-dev
    sudo apt-get install --reinstall ruby ruby-dev

# Copying

Copyright 2015-2016 by Richard Wossal <richard@r-wos.org>

Permission to use, copy, modify, distribute, and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear in
supporting documentation.  No representations are made about the
suitability of this software for any purpose.  It is provided "as
is" without express or implied warranty.
