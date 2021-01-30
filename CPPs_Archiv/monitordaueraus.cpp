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
	fflush(stdout);
	r = system("echo \"standby 0\" | sudo cec-client -s -d 1");
	r = system("vcgencmd display_power 0");

  return 0;
}