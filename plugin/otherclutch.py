#!/usr/bin/env python
# vim: set tabstop=4 shiftwidth=4 textwidth=79 cc=72,79:
"""
    otherclutch.py: Server part of otherclutch.vim.
    Spawned automatically by otherclutch.vim when it's needed.
    Shared between instances of otherclutch.vim.

    Owain Jones [github.com/erinaceous]
"""
from __future__ import print_function
import argparse
import asyncore
import atexit
import evdev
import time
import os


CLUTCH_NAME = 'footswitch'
STATE = os.path.join('/tmp', '%s-clutch-server' % os.getlogin())


def state_write(statefile, string):
    state = open(statefile, 'w+')
    state.write(string)
    state.close()


class PedalDispatcher(asyncore.file_dispatcher):
    def __init__(self, device, state=STATE):
        self.device = device
        asyncore.file_dispatcher.__init__(self, device)
        #try:
        #    os.mkstate(state)
        #except OSError:
        #    print(state, 'already exists...')
        self.state = state

    def recv(self, ign=None):
        return self.device.read()

    def handle_read(self):
        for event in self.recv():
            if event.type == evdev.ecodes.EV_KEY:
                event = evdev.categorize(event)

                if event.keystate == event.key_down:
                    self.engaged(event)
                elif event.keystate == event.key_up:
                    self.released(event)

    def engaged(self, event=None):
        state_write(self.state, '1')
        #print('clutch engaged')

    def released(self, event=None):
        state_write(self.state, '0')
        #print('clutch released')


def get_pedals(name='footswitch'):
    devices = [evdev.InputDevice(dev) for dev in evdev.list_devices()]
    return [dev for dev in devices if name in dev.name.lower()]


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--state', default=STATE)
    parser.add_argument('--clutch_name', default=CLUTCH_NAME)
    return parser.parse_args()


def exit_handler(statefile):
    #print('Removing', statefile)
    os.unlink(statefile)


if __name__ == '__main__':
    args = parse_arguments()
    name = args.clutch_name
    state = args.state
    state_write(state, '0')
    pedals = list(get_pedals(name))
    dispatchers = dict()
    atexit.register(exit_handler, state)
    while True:
        for pedal in pedals:
            #print('Grabbing pedal', pedal.name)
            pedal.grab()
            if pedal not in dispatchers:
                dispatchers[pedal] = PedalDispatcher(pedal, state)
        asyncore.loop()
        time.sleep(2)
