#!/usr/bin/env python3
import time
import RPi.GPIO as GPIO
import subprocess
import datetime
from datetime import datetime

GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.IN)
#GPIO.input(17) = 1
screen_active=False
def monitor(command):
    if(command=="on"):
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; monitor on'])
    elif(command=="off"):
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; monitor off'])

def screen(command):
    if(command=="on"):
        print("screen on")
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; screen on'])
    elif(command=="off"):
        print("screen off")
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; screen off'])

# Endlosschleife
while True:
	#print GPIO.input(5)
    if GPIO.input(17) == 1:
        time.sleep(0.25)
    else:
        print ("gedrueckt")
        if (screen_active==False):
            screen_active=True
            print("Mission turning DIVERA MON on")
            monitor("on")
            print("Mission turning display on")
            screen("on")            
            time.sleep(10)
        else:
            screen_active=False
            print("Mission turning DIVERA MON off")
            monitor("off")
            print("Mission turning display off")
            screen("off")            
            time.sleep(10)
            
        
