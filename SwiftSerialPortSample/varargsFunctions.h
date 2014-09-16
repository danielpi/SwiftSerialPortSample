//
//  varargsFunctions.h
//  SwiftSerialPortSample
//
//  Created by Daniel Pink on 16/09/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

#ifndef __SwiftSerialPortSample__varargsFunctions__
#define __SwiftSerialPortSample__varargsFunctions__

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/serial/ioss.h>
#include <IOKit/IOBSD.h>

int ioctl_va_list(int fildes, unsigned long request, va_list args);

int ioctlTIOCEXCL(int fildes);
int ioctlIOSSIOSPEED(int fildes, speed_t *speed);

int fcntlF_SETFL(int fildes, int flags);

#endif /* defined(__SwiftSerialPortSample__varargsFunctions__) */
