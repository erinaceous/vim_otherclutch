vim-otherclutch
===============

An altnerative way of getting foot pedals to work in vim.

Inspired by:
https://github.com/alevchuk/vim-clutch

This aims to bypass the "put two footpedals into one box" and "run windows programs to reconfigure the pedals to hit i and Esc" hacks by assuming direct control of any foot pedals plugged into the system and allowing you to run any vim command when the pedals are pushed down and released.

Dependencies
------------
* Python 2.6+ (Tested on Python 3)
* Vim compiled with Python support
* Python library for evdev (`sudo easy_install evdev` should work)

Installation
------------
Use pathogen:

    cd ~/.vim/bundle && git clone https://github.com/erinaceous/vim_otherclutch.git

Configuration
-------------
To enable vim-otherclutch, add `ClutchStart` at the end of your vimrc.
If you want to disable vim-otherclutch for a single instance of vim, call `ClutchEnd`.
The plugin defines the following configurable variables:
* `g:clutch_name`: Select evdev input devices which contain this string in their (lowercased) name
* `g:clutch_engaged`: Vim command to run when the clutch has been pressed down
* `g:clutch_released`: Vim command to run when the clutch has been released
* `g:clutch_state`: Path to file which stores pedal state information (default is somewhere in `/tmp`)

Usage
-----
* Open up vim
* Press down foot pedal, either wait a second or hit space or an arrow key to trigger an event in vim
* Now in insert mode. Start typing :)
* Let go of pedal, wait a second or hit some nondestructive keys
* Now back in normal mode :)

Bugs / Flaws
------------
* Lots
* Relies on UI events in vim in order to handle pedal input. No way of running asynchronous threads in Python; that would block. Had to spawn an external process instead and communicate with it using a normal file. Ugly.
* Doesn't keep track of the spawned Python process - one of your open vims is in charge of spawning the process. If you close the wrong one too soon, the python process will be killed and any other opened vims won't respond to pedals anymore.
* Since it relies on evdev/udev, by default you probably can't read input from the pedals in the first place.
    + Simple fix: `sudo chmod 666 /dev/input/eventX`, where X == id of your foot pedal (you can find this with `xinput list`)
    + Better fix: Create a udev rule that gives normal users read permissions for devices matching the pedal device IDs
