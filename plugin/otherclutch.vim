" vim: set tabstop=4 shiftwidth=4 textwidth=79 cc=72,79:
"
" otherclutch.vim: Talk to an external python script, figure out whether any
" foot pedals are being pressed or not on system, control vim with that info.
" You'll have to have read permissions to the input devices you want to use as
" pedals in /dev/input/. Lazy solution is chmod 777 /dev/input/eventX, where X
" == id(s) of pedal(s). Proper solution is a udev rule file.
"
" Owain Jones [github.com/doomcat]
" Thanks to these people/articles:
" http://brainacle.com/how-to-write-vim-plugins-with-python.html
" https://pythonhosted.org/evdev/tutorial.html
"
" NOTE: Whilst this listens to any footpedals discovered, it doesn't
" differentiate between them. Any footpedal engaged runs the clutch_engaged
" function, any released runs the clutch_released function.
" It also doesn't handle pedals with multiple buttons. Just listening to
" keydown and keyup events globally -- no checking what keys were pressed.
" Someone want to do me a pull request with these things in them? :)

if !has('python')
    echo 'Error: Requires vim compiled with +python'
    finish
endif

if !exists('g:clutch_name')
    let g:clutch_name='footswitch'
endif
if !exists('g:clutch_engaged')
    let g:clutch_engaged='let &insertmode=1'
endif
if !exists('g:clutch_released')
    let g:clutch_released='let &insertmode=0'
endif
if !exists('g:clutch_state')
    let g:clutch_state='/tmp/clutch_state'
endif
let s:plugindir = expand('<sfile>:p:h:h')


function! otherclutch#init()
python << EOF
from __future__ import print_function
import subprocess
import os
try:
    import vim
    vim_mode = True
except ImportError:
    print("Couldn't import vim module. Weird :(")
    vim_mode = False


proc = None
global last_state
last_state = '0'


def check_clutch(name, statefile):
    if os.path.exists(statefile) is False:
        try:
            global plugindir
            proc = subprocess.Popen([
                os.path.join(plugindir, 'plugin', 'otherclutch.py'),
                '--state', statefile,
                '--clutch_name', name
            ])
        except subprocess.CalledProcessError:
            return '0'
    try:
        state = open(statefile, 'r').read()
    except:
        state = '0'
    return state


def respond_to_clutch(state):
    global last_state
    if state == last_state:
        return
    if state == '0':
        action = vim.eval('g:clutch_released')
    elif state == '1':
        action = vim.eval('g:clutch_engaged')
    vim.command(action)
    last_state = state


CLUTCH_NAME = 'footswitch'
CLUTCH_STATE = '/tmp/clutch_state'
if vim_mode:
    name = vim.eval('g:clutch_name')
    statefile = vim.eval('g:clutch_state')
    plugindir = vim.eval('s:plugindir')
else:
    name = CLUTCH_NAME
    statefile = '/tmp/clutch_state'
    plugindir = os.getcwd()
state = check_clutch(name, statefile)
last_state = state
EOF
endfunction

" Process queued evdev events once
function! otherclutch#pump()
py respond_to_clutch(check_clutch(name, statefile))
endfunction

" Process evdev events every time a suitable vim event happens
function! otherclutch#loop()
    augroup clutch
    au clutch VimResized * call otherclutch#pump()
    au clutch FocusGained * call otherclutch#pump()
    au clutch FocusLost * call otherclutch#pump()
    au clutch CursorHold * call otherclutch#pump()
    au clutch CursorHoldI * call otherclutch#pump()
    au clutch CursorMoved * call otherclutch#pump()
    au clutch CursorMovedI * call otherclutch#pump()
    au clutch WinEnter * call otherclutch#pump()
    au clutch WinLeave * call otherclutch#pump()
    au clutch InsertChange * call otherclutch#pump()
endfunction

function! otherclutch#end()
    augroup clutch
    autocmd!
:endfunction

" Make sure that the python threads are terminated when Vim exits.
function! otherclutch#kill()
python << EOF
if proc is not None:
    proc.terminate()
EOF
endfunction
au VimLeave * call otherclutch#kill()

" Initialize otherclutch once everything else has been done.
call otherclutch#init()

command ClutchInit call otherclutch#init()
command ClutchPump call otherclutch#pump()
command ClutchStart call otherclutch#loop()
command ClutchEnd call otherclutch#end()
command ClutchKill call otherclutch#kill()
