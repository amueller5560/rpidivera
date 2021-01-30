#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <wiringPi.h>
#include <time.h>


// -------------------------------------------------------------------------
// main

int main(int argc,char *argv[]) {
	int  r;
	r = system("vcgencmd display_power 1");	
	r = system("echo \"on 0\" | sudo cec-client -s -d 1");	
	fflush(stdout);
	for(int i = 0; i < atoi(argv[1]) ;i++)
	{
   		delay( 1000*60 ); // wait 1 min
	}
	r = system("echo \"standby 0\" | sudo cec-client -s -d 1");
	r = system("vcgencmd display_power 0");

  return 0;
}