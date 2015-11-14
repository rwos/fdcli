# fdcli

A visual command-line client for [Flowdock](https://www.flowdock.com).

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

* `fdcli`

# Requirements

All of this is probably already there.

* a non-ancient `bash` at `/bin/bash`
* `python` 2.x
* `perl` 5.x
