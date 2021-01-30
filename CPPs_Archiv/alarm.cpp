#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <wiringPi.h>
#include <time.h>

// Use GPIO Pin 19, which is Pin 0 for wiringPi library
#define BUTTON_PIN1 21 		// GPIO5
#define BUTTON_PIN2 23		// GPIO13

// the event counter
volatile int eventCounter = 0;
volatile int checkcount = 0;

// -------------------------------------------------------------------------
// myInterrupt:  called every time an event occurs
void myInterrupt1(void) {
   eventCounter |= 0x01;
   checkcount = 1;
}

void myInterrupt2(void) {
   eventCounter |= 0x02;
}


// -------------------------------------------------------------------------
// main
int main(void) {
	
	
	int y = 0, r, x = 0;
	time_t t;
	struct tm *ts;
  // sets up the wiringPi library
  if (wiringPiSetup () < 0) {
      fprintf (stderr, "Unable to setup wiringPi: %s\n", strerror (errno));
      return 1;
  }

  // set Pin 5/0 generate an interrupt on high-to-low transitions
  // and attach myInterrupt() to the interrupt
  if ( wiringPiISR (BUTTON_PIN1, INT_EDGE_FALLING, &myInterrupt1) < 0 ) {
      fprintf (stderr, "Unable to setup ISR: %s\n", strerror (errno));
      return 1;
  }
  
  if ( wiringPiISR (BUTTON_PIN2, INT_EDGE_FALLING, &myInterrupt2) < 0 ) {
      fprintf (stderr, "Unable to setup ISR: %s\n", strerror (errno));
      return 1;
  }


  t = time(NULL);
  ts = localtime(&t);
  fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d Start\n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec);
	
  r = system("./home/pi/diverarun/monitoran 1 &");  
  // display counter value every second.
  while ( 1 ) {
	y = eventCounter;
	// fprintf (stderr, "Alarmgeberstatus %i\n", digitalRead(BUTTON_PIN1));
	if(eventCounter > 0 )
	{
		
		if((eventCounter & 0x01) && checkcount == 0 && digitalRead(BUTTON_PIN1) == 0){
			t = time(NULL);
			ts = localtime(&t);
			fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d Alarm\n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec);
			r = system("curl --data \"zugang=xyz&alarm=xyz\" https://www.mitgliedsverwaltung.net/statusgeber.php");
			if(r == 0)
			{
				eventCounter = eventCounter & ~0x01;
			}
			else 
			{
				fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d Fehler Curl\n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec);		
			}
			r = system("./home/pi/diverarun/monitoran 10 &");

		}
		else if(checkcount == 1)
		{
			t = time(NULL);
			ts = localtime(&t);
			fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d Alarm warte \n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec);
		}
		else if ((eventCounter & 0x01))
		{
			t = time(NULL);
			ts = localtime(&t);
			fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d Fehlalarm zurück\n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec);
			eventCounter = eventCounter & ~0x01;
		}

		if(eventCounter & 0x02)
		{
			t = time(NULL);
			ts = localtime(&t);
			fprintf (stdout, "%02d.%02d.%02d - %02d:%02d:%02d USER 1\n", ts->tm_mday, (1+ ts->tm_mon),  (1900 +ts->tm_year),ts->tm_hour, ts->tm_min, ts->tm_sec );
			r = system("curl --data \"zugang=xyz&user=xyz\" https://www.mitgliedsverwaltung.net/statusgeber.php");
			if(r == 0)
			{
				eventCounter = eventCounter & ~0x02;
			}
			 
		}
	}
	//fprintf (stderr, "%i %i\n", y, eventCounter);
	checkcount = 0;
	fflush(stdout);
    delay( 500 ); // wait 0,5 second
  }

  return 0;
}
