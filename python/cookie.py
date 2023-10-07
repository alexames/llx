import win32api
import win32con
import time
import sys

################################################################################
################################################################################
################################################################################

mouse_threshold = 20

clicks_per_second = 100

modes = {}

modes['red'] = [
    {
        'prompt': 'Move to red cookie',
        'reps': 1
    },
    {
        'prompt': 'Move to cookie',
        'reps': 10000000000
    },
]

modes['stockup'] = [
    {
        'prompt': 'Move to time machine',
        'reps': 1
    },
    {
        'prompt': 'Move to cookie',
        'reps': 100
    },
]

modes['click'] = [
    {
        'prompt': 'Move to cookie',
        'reps': 100
    },
]

modes['each'] = [
    {
        'prompt': 'Move to Prism',
        'reps': 1
    },
    {
        'prompt': 'Move to antimatter condenser',
        'reps': 1
    },
    {
        'prompt': 'Move to time machine',
        'reps': 1
    },
    {
        'prompt': 'Move to portal',
        'reps': 1
    },
    {
        'prompt': 'Move to alchemy lab',
        'reps': 1
    },
    {
        'prompt': 'Move to shipment',
        'reps': 1
    },
    {
        'prompt': 'Move to wizard tower',
        'reps': 1
    },
    {
        'prompt': 'Move to temple',
        'reps': 1
    },
    {
        'prompt': 'Move to bank',
        'reps': 1
    },
    {
        'prompt': 'Move to factory',
        'reps': 1
    },
    {
        'prompt': 'Move to mine',
        'reps': 1
    },
    {
        'prompt': 'Move to farm',
        'reps': 1
    },
    {
        'prompt': 'Move to grandma',
        'reps': 1
    },
    {
        'prompt': 'Move to cursor',
        'reps': 1
    },
    {
        'prompt': 'Move to cookie',
        'reps': 100
    },
    {
        'prompt': 'Move to upgrades',
        'reps': 1
    },
    {
        'prompt': 'Move to cookie',
        'reps': 100
    },
]

modes['gold'] = [
    {
        'prompt': 'position 1',
        'reps': 1
    },
    {
        'prompt': 'position 2',
        'reps': 1
    },
    {
        'prompt': 'position 3',
        'reps': 1
    },
    {
        'prompt': 'position 4',
        'reps': 1
    },
    {
        'prompt': 'position 5',
        'reps': 1
    },
    {
        'prompt': 'position 6',
        'reps': 1
    },
    {
        'prompt': 'position 7',
        'reps': 1
    },
    {
        'prompt': 'position 8',
        'reps': 1
    },
    {
        'prompt': 'position 9',
        'reps': 1
    },
    {
        'prompt': 'position 10',
        'reps': 1
    },
    {
        'prompt': 'position 11',
        'reps': 1
    },
    {
        'prompt': 'position 12',
        'reps': 1
    },
    {
        'prompt': 'position 12',
        'reps': 1
    },
    {
        'prompt': 'position 13',
        'reps': 1
    },
    {
        'prompt': 'position 14',
        'reps': 1
    },
    {
        'prompt': 'position 15',
        'reps': 1
    },
    {
        'prompt': 'position 16',
        'reps': 1
    },
    {
        'prompt': 'position 17',
        'reps': 1
    },
    {
        'prompt': 'position 18',
        'reps': 1
    },
    {
        'prompt': 'position 19',
        'reps': 1
    },
    {
        'prompt': 'position 20',
        'reps': 1
    },
    {
        'prompt': 'position 21',
        'reps': 1
    },
    {
        'prompt': 'position 22',
        'reps': 1
    },
    {
        'prompt': 'position 22',
        'reps': 1
    },
    {
        'prompt': 'position 23',
        'reps': 1
    },
    {
        'prompt': 'position 24',
        'reps': 1
    },
    {
        'prompt': 'position 25',
        'reps': 1
    },
    {
        'prompt': 'position 26',
        'reps': 1
    },
    {
        'prompt': 'position 27',
        'reps': 1
    },
    {
        'prompt': 'position 28',
        'reps': 1
    },
    {
        'prompt': 'position 29',
        'reps': 1
    },
    {
        'prompt': 'position 30',
        'reps': 1
    },
    {
        'prompt': 'position 31',
        'reps': 1
    },
    {
        'prompt': 'position 32',
        'reps': 1
    },
    {
        'prompt': 'position 32',
        'reps': 1
    },
    {
        'prompt': 'position 33',
        'reps': 1
    },
    {
        'prompt': 'position 34',
        'reps': 1
    },
    {
        'prompt': 'position 35',
        'reps': 1
    },
    {
        'prompt': 'position 36',
        'reps': 1
    },
    {
        'prompt': 'position 37',
        'reps': 1
    },
    {
        'prompt': 'position 38',
        'reps': 1
    },
    {
        'prompt': 'position 39',
        'reps': 1
    },
    {
        'prompt': 'position 40',
        'reps': 1
    },
    {
        'prompt': 'position 41',
        'reps': 1
    },
    {
        'prompt': 'position 42',
        'reps': 1
    },
    {
        'prompt': 'position 43',
        'reps': 1
    },
    {
        'prompt': 'position 44',
        'reps': 1
    },
    {
        'prompt': 'position 45',
        'reps': 1
    },
    {
        'prompt': 'position 46',
        'reps': 1
    },
    {
        'prompt': 'position 47',
        'reps': 1
    },
    {
        'prompt': 'position 48',
        'reps': 1
    },
    {
        'prompt': 'position 49',
        'reps': 1
    },
    {
        'prompt': 'position 50',
        'reps': 1
    },
    {
        'prompt': 'Move to cookie',
        'reps': 1000
    },
]

################################################################################
################################################################################
################################################################################

deltas = 0
clicks = 0
next_click_allowed = 0
def click(loc):
    global deltas, clicks, clicks_per_second, next_click_allowed, mouse_threshold
    win32api.SetCursorPos(loc)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, loc[0], loc[1], 0, 0)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, loc[0], loc[1], 0, 0)

    while time.clock() < next_click_allowed:
        pass
    pos = win32api.GetCursorPos()
    next_click_allowed = time.clock() + (1.0/clicks_per_second)
    clicks += 1
    if pos != loc:
        deltas += 1
    if deltas > mouse_threshold:
        print "test"
        raise Exception('mouse moved!')

rctrl_down_prev = False
def rctrl_press_started():
    global rctrl_down_prev
    rctrl_down_now = win32api.GetAsyncKeyState(win32con.VK_RCONTROL)
    retval = rctrl_down_now and not rctrl_down_prev
    rctrl_down_prev = rctrl_down_now
    return retval

def wait_for_rctrl():
    while not rctrl_press_started():
        pass

starttime = 0
try:
    if len(sys.argv) >= 2:
        # determine the mode
        mode = modes[sys.argv[1]]

        # Gather click locations
        for click_spot in mode:
            print click_spot['prompt']
            wait_for_rctrl();
            click_spot['location'] = win32api.GetCursorPos()

        # Click forever!
        print "Start!"
        starttime = time.clock()
        while True:
            for click_spot in mode:
                i = 0
                reps = click_spot['reps']
                while i < reps:
                    click(click_spot['location'])
                    i += 1
    else:
        print "No mode selected"
except:
    # Wiggled the mouse enough
    pass
totaltime = time.clock() - starttime
print 'Total Time: %s - Clicks: %s - Clicks per Second %s' % (totaltime, clicks, clicks/totaltime)
