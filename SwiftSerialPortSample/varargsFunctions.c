//
//  varargsFunctions.c
//  SwiftSerialPortSample
//
//  Created by Daniel Pink on 16/09/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

#include "varargsFunctions.h"

int ioctl_va_list(int fildes, unsigned long request, va_list args) {
    //va_list arguments;
    //va_start(arguments, request);
    //va_end(arguments);
    return ioctl(fildes, request);
}

int ioctlTIOCEXCL(int fildes) {
    return ioctl(fildes, TIOCEXCL);
}

int ioctlIOSSIOSPEED(int fildes, speed_t *speed) {
    
    int result = ioctl(fildes, IOSSIOSPEED, speed);
    printf("%d result:%d\n", (int)speed, result);
    return result;
}

int fcntlF_SETFL(int fildes, int flags) {
    return fcntl(fildes, F_SETFL, flags);
}

