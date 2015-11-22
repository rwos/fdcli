# fdcli

# DO NOT USE

This is buggy, incomplete, and even when it works (which it doesn't very often)
almost unusable. Assume it will delete your entire hard drive, and install
Windows XP. No warranties, you're on your own here.

Work in progress.

---

A visual command-line client for [Flowdock](https://www.flowdock.com) with
vi/mutt like key bindings.

![screenshot](screenshot.png)

# Install

* `cp fdcli /bin`
* `mkdir -p ~/.config/fdcli`
* go to https://www.flowdock.com/account/tokens, copy your personal API token
  into a file called `~/.config/fdcli/TOKEN`
* put the name of your flowdock organization into `~/.config/fdcli/ORG`

Should look something like this then:

    $ pwd
    /home/richard/.config/fdcli
    $ cat TOKEN 
    b1946ac92492d2347c6235b4d2611184
    $ cat ORG 
    my-flowdock-org

# Usage

* `fdcli`, keys are indicated at the prompt at the top

# Requirements

All of this is probably already there.

* a non-ancient `bash` at `/bin/bash`
* `python` 2.x
* `perl` 5.x

# Copying

Copyright 2015 by Richard Wossal <richard@r-wos.org>

Permission to use, copy, modify, distribute, and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear in
supporting documentation.  No representations are made about the
suitability of this software for any purpose.  It is provided "as
is" without express or implied warranty.
