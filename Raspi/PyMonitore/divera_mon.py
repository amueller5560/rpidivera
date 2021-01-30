#!/usr/bin/env python3
import subprocess
import datetime
import requests
import time
import json
import logging
import locale
from datetime import datetime
#import os
#from envbash import load_envbash
#load_envbash('.bashrc')
ACCESSKEY="xyz"
API_URL="https://www.divera247.com/api/last-alarm?accesskey="+ACCESSKEY

#Logging Area
# create logger
logger = logging.getLogger('alarmlogger')
logger.setLevel(logging.DEBUG)

# Logger Configuration
currentdate=datetime.now()
logfilename=currentdate.strftime("%Y-%m-%d_%H-%M")
logfilename=logfilename+"_alarmlog.log"
logfilename="/home/pi/diverarun/logs/"+logfilename
#logging.basicConfig(filename=logfilename, encoding='UTF-8', level=logging.DEBUG, format='%(asctime)s %(levelname)-8s %(message)s',datefmt='%Y-%m-%d %H:%M:%S')

logging.basicConfig(handlers=[logging.FileHandler(filename=logfilename, 
                                                 encoding='utf-8', mode='a+')],
                    format="%(asctime)s %(levelname)-8s %(message)s", 
                    datefmt="%Y-%m-%d %H:%M:%S", 
                    level=logging.INFO)
# Logger Configuration End

#wrapper methode that calls the diver monitor commands from the bash script
def monitor(command):
    if(command=="on"):
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; monitor on'])
    elif(command=="off"):
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; monitor off'])

def screen(command):
    if(command=="on"):
        print("screen on")
        logger.info('Screen On')
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; screen on'])
    elif(command=="off"):
        print("screen off")
        logger.info('Screen Off')
        subprocess.Popen(['bash','-c','. ./divera_commands.sh; screen off'])

def sleeper():
    time.sleep(30)

#monitor("on")
logger.info('#############################!')
logger.info('DIVERA Alarm Skript gestartet!')
logger.info('#############################!')
screen_active=True
missionid="0"
while True:
    try:
        url = API_URL
        print("Mache Request")
        urlreq = requests.get(url)
        print("Mache JSON")
        missiondata= json.loads(urlreq.text)
        success=(missiondata['success'])
        print("Success:" + str(success))
        if(success == False):
            alarm_active = False
        if(success == True):
            closed = (missiondata['data']['closed'])
            print(closed)        
            if(closed == False):
                print("Ggfs Timecheck erforderlich")
                alarm_active = True
            else:
                print("Kein Alarm da?")
                alarm_active = False
    except:
        print("On")
        logger.error('Fehler beim Request')
        alarm_active = True

    #print("Alarm active:" + str(alarm_active))
    now=datetime.now()
    day_of_week=now.weekday()+1 #1=Montag
    hour=now.hour
    minutes=now.minute
    duty_time = False

    #case: active mission and monitor off
    # and screen_active == False
    if(alarm_active == True):
        #check time 
        url = API_URL
        urlreq = requests.get(url)
        missiondata= json.loads(urlreq.text)
        closed = (missiondata['data']['closed'])
        missionidcompare = (missiondata['data']['id'])
        if(missionid == missionidcompare):
            print("Abbruch weil alter Einsatz")
            time.sleep(30)
            continue
        date = (missiondata['data']['date'])
        deleted = (missiondata['data']['deleted'])
        closed = (missiondata['data']['closed'])
        print (date)
        #print (deleted)
        #print (closed)
        timestamp = date
        einsatzzeit = datetime.fromtimestamp(timestamp)
        currentdate=datetime.now()
        einsatzzeitstring=einsatzzeit.strftime("%Y-%m-%d %H:%M:%S")
        currentdatestring=currentdate.strftime("%Y-%m-%d %H:%M:%S")
        fmt = '%Y-%m-%d %H:%M:%S'
        d1 = datetime.strptime(einsatzzeitstring, fmt)
        d2 = datetime.strptime(currentdatestring, fmt)
        secondsDiff = (d2-d1).seconds
        minutsDiff = (d2-d1).seconds / 60
        print ("Zeitunterschied - Sekunden: "+str(secondsDiff))
        print ("Zeitunterschied - Minuten: "+str(minutsDiff))
        #600
        if(secondsDiff < 600):
            logger.info('Einsatz vorhanden und aktiv!')
            logger.info('Screen und Monitor An')
            print("Mission turning display on")
            screen("on")
            print("Mission turning DIVERA MON on")
            monitor("on")
            screen_active = True
            #sleep 
            time.sleep(600)
            #turn of after sleep
            print ("Save current missionid for next rounds!")
            logger.info('Einsatz ID speichern fuer naechste Abfrage!')
            missionid = missionidcompare
            print("Mission end turning DIVERA MON off")
            logger.info('Einsatz Ende - Screen und Monitor aus!')
            monitor("off")
            print("Turn display off")
            screen("off")
            screen_active = False
        else:
            print ("Save current missionid for next rounds!")
            logger.info('Einsatz ID speichern fuer naechste Abfrage!')
            missionid = missionidcompare
            print("Mission end turning DIVERA MON off")
            logger.info('Einsatz Ende - Screen und Monitor aus!')
            monitor("off")
            print("Turn display off")
            screen("off")
            screen_active = False
            print("No action - Einsatz erledigt - Zeitunterschied zu gross!")
            logger.info('Keine Aktion erforderlich - Einsatz erledigt - Zeitunterschied zu gross!')

        #case: duty time and mission off
    elif(duty_time == True and screen_active == False):
        print("Duty turning display on")
        screen("on")
        screen_active = True
        
    #case: no mission and no standby but monitor on
    elif(alarm_active == False and duty_time == False and screen_active == True):
        print("Turn display off")
        logger.info('Kein Alarm Screen aus!')
        screen("off")
        screen_active = False
    
	#case: monitor off an no mission and it is night time so make updates
	#elif(alarm_active == False and screen_active == False and hour == 3 and minutes == 5):
	#	print("Updating and restarting Raspberry")
		#wait a moment that he wont do two updates when he is faster then a minute with update and reboot
	#	time.sleep(45)
	#	subprocess.Popen(['sudo', 'apt', 'update']).wait()
	#	subprocess.Popen(['sudo', 'apt', '--yes', '--force-yes', 'upgrade']).wait()
	#	subprocess.Popen(['sudo', 'reboot'])
        
    #sleeps 30 seconds and starts again
    print("Kein Alarm warte 30 Sekunden")
    #print (day_of_week)
    time.sleep(30)
