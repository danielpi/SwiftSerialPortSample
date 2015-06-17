//
//  main.swift
//  SwiftSerialPortSample
//
//  Created by Daniel Pink on 4/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

/*
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
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/serial/ioss.h>
#include <IOKit/IOBSD.h>
*/

import Cocoa
import CoreFoundation
import IOKit
import IOKit.serial




// Default to local echo being on. If your modem has local echo disabled, undefine the following macro.
//#define LOCAL_ECHO
let LOCAL_ECHO = true

// Find the first device that matches the callout device path MATCH_PATH.
// If this is undefined, return the first device found.
//#define MATCH_PATH "/dev/tty.usbserial-FTFWP23E"
let MATCH_PATH = "/dev/tty.usbserial-FTFWP23E"

//#define kATCommandString	"AT\r"
let kATCommandString = "AT\r\n"

//#ifdef LOCAL_ECHO
//#define kOKResponseString	"AT\r\r\nOK\r\n"
//#else
//#define kOKResponseString	"\r\nOK\r\n"
//#endif
var kOKResponseString = "\r\nOK\r\n"
if LOCAL_ECHO {
    kOKResponseString = "AT\r\r\nOK\r\n"
}


//const int kNumRetries = 3;
let kNumRetries = 3

// Hold the original termios attributes so we can reset them
//static struct termios gOriginalTTYAttrs;

var gOriginalTTYAttrs: termios = termios()
//struct gOriginalTTYAttrs:termios

// Function prototypes
//static kern_return_t findModems(io_iterator_t *matchingServices);
//static kern_return_t getModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize);
//static int openSerialPort(const char *bsdPath);
//static char *logString(char *str);
//static Boolean initializeModem(int fileDescriptor);
//static void closeSerialPort(int fileDescriptor);

/*
// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
static kern_return_t findModems(io_iterator_t *matchingServices)
{
    kern_return_t			kernResult;
    CFMutableDictionaryRef	classesToMatch;
    
    // Serial devices are instances of class IOSerialBSDClient.
    // Create a matching dictionary to find those instances.
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL) {
        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        // Look for devices that claim to be modems.
        CFDictionarySetValue(classesToMatch,
            CFSTR(kIOSerialBSDTypeKey),
            CFSTR(kIOSerialBSDModemType));
        
        // Each serial device object has a property with key
        // kIOSerialBSDTypeKey and a value that is one of kIOSerialBSDAllTypes,
        // kIOSerialBSDModemType, or kIOSerialBSDRS232Type. You can experiment with the
        // matching by changing the last parameter in the above call to CFDictionarySetValue.
        
        // As shipped, this sample is only interested in modems,
        // so add this property to the CFDictionary we're matching on.
        // This will find devices that advertise themselves as modems,
        // such as built-in and USB modems. However, this match won't find serial modems.
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, matchingServices);
    if (KERN_SUCCESS != kernResult) {
        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
        goto exit;
    }
    
    exit:
    return kernResult;
}
*/

// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
func findModems(inout serialPortIterator: io_iterator_t ) -> kern_return_t {
    var kernResult: kern_return_t = KERN_FAILURE
    
    // Serial devices are instances of class IOSerialBSDClient.
    // Create a matching dictionary to find those instances."IOSerialBSDClient"
    let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
    if (classesToMatch.count == 0) { // Not sure about this. IOServiceMatching(kIOSerialBSDServiceValue) could return NULL which would be 0 in Swift but I'm not sure what "as NSMutableDictionary" would do with that. I can't think of how to force IOServiceMatching to fail in order to test this out.
        print("IOServiceMatching returned a NULL dictionary.");
    } else {
        // Look for devices that claim to be modems.
        classesToMatch[kIOSerialBSDTypeKey] = kIOSerialBSDRS232Type
        
        // Each serial device object has a property with key
        // kIOSerialBSDTypeKey and a value that is one of kIOSerialBSDAllTypes,
        // kIOSerialBSDModemType, or kIOSerialBSDRS232Type. You can experiment with the
        // matching by changing the last parameter in the above call to CFDictionarySetValue.
        
        // As shipped, this sample is only interested in modems,
        // so add this property to the CFDictionary we're matching on.
        // This will find devices that advertise themselves as modems,
        // such as built-in and USB modems. However, this match won't find serial modems.
    }
    
    // Get an iterator across all matching devices.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &serialPortIterator)
    if (KERN_SUCCESS != kernResult) {
        print("IOServiceGetMatchingServices returned \(kernResult)")
    }

    return kernResult
}


// Given an iterator across a set of modems, return the BSD path to the first one with the callout device
// path matching MATCH_PATH if defined.
// If MATCH_PATH is not defined, return the first device found.
// If no modems are found the path name is set to an empty string.
func getModemPath(serialPortIterator: io_iterator_t) -> String? {
    var modemService: io_object_t
    var modemFound = false
    var bsdPath: String? = nil
    
    // Iterate across all modems found. Use the last one
    repeat {
        modemService = IOIteratorNext(serialPortIterator)
        guard modemService != 0 else { continue }
        
        if let aPath = IORegistryEntryCreateCFProperty(modemService, "IOCalloutDevice", kCFAllocatorDefault, 0).takeUnretainedValue() as? String {
            print("Found \(aPath)")
            bsdPath = aPath
            if (aPath == MATCH_PATH) { modemFound = true }
        }
    
    } while (modemService != 0 && !modemFound)
    
    return bsdPath
}

/*
static kern_return_t getModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize)
{
    io_object_t		modemService;
    kern_return_t	kernResult = KERN_FAILURE;
    Boolean			modemFound = false;
    
    // Initialize the returned path
    *bsdPath = '\0';
    
    // Iterate across all modems found. In this example, we bail after finding the first modem.
    
    while ((modemService = IOIteratorNext(serialPortIterator)) && !modemFound) {
        CFTypeRef	bsdPathAsCFString;
        
        // Get the callout device's path (/dev/cu.xxxxx). The callout device should almost always be
        // used: the dialin device (/dev/tty.xxxxx) would be used when monitoring a serial port for
        // incoming calls, e.g. a fax listener.
        
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
            CFSTR(kIOCalloutDeviceKey),
            kCFAllocatorDefault,
            0);
        if (bsdPathAsCFString) {
            Boolean result;
            
            // Convert the path from a CFString to a C (NUL-terminated) string for use
            // with the POSIX open() call.
            
            result = CFStringGetCString(bsdPathAsCFString,
                bsdPath,
                maxPathSize,
                kCFStringEncodingUTF8);
            CFRelease(bsdPathAsCFString);
            
            #ifdef MATCH_PATH
            if (strncmp(bsdPath, MATCH_PATH, strlen(MATCH_PATH)) != 0) {
                result = false;
        }
        #endif
        
        if (result) {
            printf("Modem found with BSD path: %s", bsdPath);
            modemFound = true;
            kernResult = KERN_SUCCESS;
        }
    }
    
    printf("\n");
    
    // Release the io_service_t now that we are done with it.
    
    (void) IOObjectRelease(modemService);
}

return kernResult;
}
*/

func openSerialPort(bsdPath: String) -> Int {
    //var fileDescriptor: Int = -1
    var options: termios
    
    // Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
    // The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
    // See open(2) <x-man-page://2/open> for details.
    
    let fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fileDescriptor == -1) {
        print("Error opening port")
    }
    
    
    // Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
    // unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
    // processes.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    var result = ioctlTIOCEXCL(fileDescriptor)
    if (result == -1) {
        print("Error setting TIOXCL")
    }
    
    // Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
    // See fcntl(2) <x-man-page//2/fcntl> for details.
    
    result = fcntlF_SETFL(fileDescriptor, 0)
    if (result == -1) {
        //printf("Error clearing O_NONBLOCK %s - %s(%d).\n", bsdPath, strerror(errno), errno);
        print("Error clearing O_NONBLOCK")
        //goto error;
    }
    
    // Get the current options and save them so we can restore the default settings later.
    result = tcgetattr(fileDescriptor, &gOriginalTTYAttrs)
    if (result == -1) {
        print("Error getting attributes")
    }
    
    // The serial port attributes such as timeouts and baud rate are set by modifying the termios
    // structure and then calling tcsetattr() to cause the changes to take effect. Note that the
    // changes will not become effective without the tcsetattr() call.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    options = gOriginalTTYAttrs;
    
    // Print the current input and output baud rates.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    print("Current input baud rate is \(cfgetispeed(&options))")
    print("Current output baud rate is \(cfgetospeed(&options))")
    
    // Set raw input (non-canonical) mode, with reads blocking until either a single character
    // has been received or a one second timeout expires.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> and termios(4) <x-man-page://4/termios> for details.
    
    cfmakeraw(&options);
    //options.c_cc[VMIN] = 0;
    //options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    
    cfsetspeed(&options, 57600);		// Set 19200 baud
    //options.c_cflag |= (CS7 	   | 	// Use 7 bit words
    //                    PARENB	   | 	// Parity enable (even parity if PARODD not also set)
    //                    CCTS_OFLOW | 	// CTS flow control of output
    //                    CRTS_IFLOW);	// RTS flow control of input
    
    // The IOSSIOSPEED ioctl can be used to set arbitrary baud rates
    // other than those specified by POSIX. The driver for the underlying serial hardware
    // ultimately determines which baud rates can be used. This ioctl sets both the input
    // and output speed.
    
    //let speed: speed_t = 2400; // Set 14400 baud
    //result = ioctlIOSSIOSPEED(fileDescriptor, UnsafeMutablePointer(bitPattern: speed))
    //if (result == -1) {
        //printf("Error calling ioctl(..., IOSSIOSPEED, ...) %s - %s(%d).\n" bsdPath, strerror(errno), errno);
    //    print("Error calling ioctl(..., IOSSIOSPEED, ...) \(strerror(errno)) \(errno)")
    //}
    
    // Print the new input and output baud rates. Note that the IOSSIOSPEED ioctl interacts with the serial driver
    // directly bypassing the termios struct. This means that the following two calls will not be able to read
    // the current baud rate if the IOSSIOSPEED ioctl was used but will instead return the speed set by the last call
    // to cfsetspeed.
    
    print("Input baud rate changed to \(cfgetispeed(&options))")
    print("Output baud rate changed to \(cfgetospeed(&options))")
    
    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1) {
        print("Error setting attributes")
    }

    /*

    // To set the modem handshake lines, use the following ioctls.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.

    // Assert Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCSDTR) == -1) {
    printf("Error asserting DTR %s - %s(%d).\n",
    bsdPath, strerror(errno), errno);
    }

    // Clear Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCCDTR) == -1) {
    printf("Error clearing DTR %s - %s(%d).\n",
    bsdPath, strerror(errno), errno);
    }

    // Set the modem lines depending on the bits set in handshake
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1) {
    printf("Error setting handshake lines %s - %s(%d).\n",
    bsdPath, strerror(errno), errno);
    }

    // To read the state of the modem lines, use the following ioctl.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.

    // Store the state of the modem lines in handshake
    if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1) {
    printf("Error getting handshake lines %s - %s(%d).\n",
    bsdPath, strerror(errno), errno);
    }

    printf("Handshake lines currently set to %d\n", handshake);

    unsigned long mics = 1UL;

    // Set the receive latency in microseconds. Serial drivers use this value to determine how often to
    // dequeue characters received by the hardware. Most applications don't need to set this value: if an
    // app reads lines of characters, the app can't do anything until the line termination character has been
    // received anyway. The most common applications which are sensitive to read latency are MIDI and IrDA
    // applications.

    if (ioctl(fileDescriptor, IOSSDATALAT, &mics) == -1) {
    // set latency to 1 microsecond
    printf("Error setting read latency %s - %s(%d).\n",
    bsdPath, strerror(errno), errno);
    goto error;
    }

    // Success
    return fileDescriptor;

    */

    return Int(fileDescriptor)
}

/*
// Given the path to a serial device, open the device and configure it.
// Return the file descriptor associated with the device.
static int openSerialPort(const char *bsdPath)
{
    int				fileDescriptor = -1;
    int				handshake;
    struct termios	options;

    // Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
    // The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
    // See open(2) <x-man-page://2/open> for details.
    
    fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fileDescriptor == -1) {
        printf("Error opening serial port %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
    // unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
    // processes.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    if (ioctl(fileDescriptor, TIOCEXCL) == -1) {
        printf("Error setting TIOCEXCL on %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
    // See fcntl(2) <x-man-page//2/fcntl> for details.
    
    if (fcntl(fileDescriptor, F_SETFL, 0) == -1) {
        printf("Error clearing O_NONBLOCK %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // Get the current options and save them so we can restore the default settings later.
    if (tcgetattr(fileDescriptor, &gOriginalTTYAttrs) == -1) {
        printf("Error getting tty attributes %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // The serial port attributes such as timeouts and baud rate are set by modifying the termios
    // structure and then calling tcsetattr() to cause the changes to take effect. Note that the
    // changes will not become effective without the tcsetattr() call.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    options = gOriginalTTYAttrs;
    
    // Print the current input and output baud rates.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    printf("Current input baud rate is %d\n", (int) cfgetispeed(&options));
    printf("Current output baud rate is %d\n", (int) cfgetospeed(&options));
    
    // Set raw input (non-canonical) mode, with reads blocking until either a single character
    // has been received or a one second timeout expires.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> and termios(4) <x-man-page://4/termios> for details.
    
    cfmakeraw(&options);
    options.c_cc[VMIN] = 0;
    options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    
    cfsetspeed(&options, B19200);		// Set 19200 baud
    options.c_cflag |= (CS7 	   | 	// Use 7 bit words
        PARENB	   | 	// Parity enable (even parity if PARODD not also set)
        CCTS_OFLOW | 	// CTS flow control of output
        CRTS_IFLOW);	// RTS flow control of input
    
    // The IOSSIOSPEED ioctl can be used to set arbitrary baud rates
    // other than those specified by POSIX. The driver for the underlying serial hardware
    // ultimately determines which baud rates can be used. This ioctl sets both the input
    // and output speed.
    
    speed_t speed = 14400; // Set 14400 baud
    if (ioctl(fileDescriptor, IOSSIOSPEED, &speed) == -1) {
        printf("Error calling ioctl(..., IOSSIOSPEED, ...) %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
    }
    
    // Print the new input and output baud rates. Note that the IOSSIOSPEED ioctl interacts with the serial driver
    // directly bypassing the termios struct. This means that the following two calls will not be able to read
    // the current baud rate if the IOSSIOSPEED ioctl was used but will instead return the speed set by the last call
    // to cfsetspeed.
    
    printf("Input baud rate changed to %d\n", (int) cfgetispeed(&options));
    printf("Output baud rate changed to %d\n", (int) cfgetospeed(&options));
    
    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1) {
        printf("Error setting tty attributes %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // To set the modem handshake lines, use the following ioctls.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    // Assert Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCSDTR) == -1) {
        printf("Error asserting DTR %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
    }
    
    // Clear Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCCDTR) == -1) {
        printf("Error clearing DTR %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
    }
    
    // Set the modem lines depending on the bits set in handshake
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1) {
        printf("Error setting handshake lines %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
    }
    
    // To read the state of the modem lines, use the following ioctl.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    // Store the state of the modem lines in handshake
    if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1) {
        printf("Error getting handshake lines %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
    }
    
    printf("Handshake lines currently set to %d\n", handshake);
    
    unsigned long mics = 1UL;
    
    // Set the receive latency in microseconds. Serial drivers use this value to determine how often to
    // dequeue characters received by the hardware. Most applications don't need to set this value: if an
    // app reads lines of characters, the app can't do anything until the line termination character has been
    // received anyway. The most common applications which are sensitive to read latency are MIDI and IrDA
    // applications.
    
    if (ioctl(fileDescriptor, IOSSDATALAT, &mics) == -1) {
        // set latency to 1 microsecond
        printf("Error setting read latency %s - %s(%d).\n",
            bsdPath, strerror(errno), errno);
        goto error;
    }
    
    // Success
    return fileDescriptor;
    
    // Failure path
    error:
    if (fileDescriptor != -1) {
        close(fileDescriptor);
    }
    
    return -1;
}

// Replace non-printable characters in str with '\'-escaped equivalents.
// This function is used for convenient logging of data traffic.
static char *logString(char *str)
{
    static char     buf[2048];
    char            *ptr = buf;
    int             i;
    
    *ptr = '\0';
    
    while (*str) {
        if (isprint(*str)) {
            *ptr++ = *str++;
        }
        else {
            switch(*str) {
            case ' ':
            *ptr++ = *str;
            break;
                
            case 27:
                *ptr++ = '\\';
                *ptr++ = 'e';
                break;
                
            case '\t':
            *ptr++ = '\\';
            *ptr++ = 't';
            break;
                
            case '\n':
            *ptr++ = '\\';
            *ptr++ = 'n';
            break;
                
            case '\r':
            *ptr++ = '\\';
            *ptr++ = 'r';
            break;
                
            default:
                i = *str;
                (void)sprintf(ptr, "\\%03o", i);
                ptr += 4;
                break;
            }
            
            str++;
        }
        
        *ptr = '\0';
    }
    
    return buf;
}
*/

// Given the file descriptor for a modem device, attempt to initialize the modem by sending it
// a standard AT command and reading the response. If successful, the modem's response will be "OK".
// Return true if successful, otherwise false.
func initializeModem(fileDescriptor: Int) -> Bool {
    var result = false
    var buffer: Array<CChar> = Array(count: 256, repeatedValue: 0)
    //var bufPtr: UnsafePointer<Character> = UnsafePointer<Character>(buffer)
    var bufPtr: Int = 0
    
    for tries in 1...kNumRetries {
        print("Try #\(tries)")
        
        var numBytes = write(Int32(fileDescriptor), kATCommandString, kATCommandString.characters.count)
        if (numBytes == -1) {
            print("Error writing to modem - \(strerror(errno))(\(errno)).")
            continue
        } else {
            print("Wrote \(numBytes) bytes \"\(kATCommandString)\"")
        }
        
        if (numBytes < kATCommandString.characters.count) {
            continue
        }
        
        print("Looking for \"\(kOKResponseString)\"\n")
        
        // Read characters into our buffer until we get a CR or LF
        //bufPtr = UnsafePointer<Character>(buffer)
        bufPtr = 0
        repeat {
            numBytes = read(Int32(fileDescriptor), &buffer, buffer.count)
            
            if (numBytes == -1) {
                print("Error reading from modem - \(strerror(errno))(\(errno)).\n")
            } else if (numBytes > 0) {
                bufPtr += numBytes
                if (buffer[bufPtr - 1] == 10 || buffer[bufPtr - 1] == 13) {
                    break
                }
                if let returned = String.fromCString(buffer) {
                    print("Received: \(returned)")
                }
            }
            else {
                print("Nothing read.");
            }
        } while (numBytes > 0);
    }
    
    return result
}

/*
static Boolean initializeModem(int fileDescriptor)
{
    char		buffer[256];	// Input buffer
    char		*bufPtr;		// Current char in buffer
    ssize_t		numBytes;		// Number of bytes read or written
    int			tries;			// Number of tries so far
    Boolean		result = false;
    
    for (tries = 1; tries <= kNumRetries; tries++) {
        printf("Try #%d\n", tries);
        
        // Send an AT command to the modem
        numBytes = write(fileDescriptor, kATCommandString, strlen(kATCommandString));
        
        if (numBytes == -1) {
            printf("Error writing to modem - %s(%d).\n", strerror(errno), errno);
            continue;
        }
        else {
            printf("Wrote %ld bytes \"%s\"\n", numBytes, logString(kATCommandString));
        }
        
        if (numBytes < strlen(kATCommandString)) {
            continue;
        }
        
        printf("Looking for \"%s\"\n", logString(kOKResponseString));
        
        // Read characters into our buffer until we get a CR or LF
        bufPtr = buffer;
        do {
            numBytes = read(fileDescriptor, bufPtr, &buffer[sizeof(buffer)] - bufPtr - 1);
            
            if (numBytes == -1) {
                printf("Error reading from modem - %s(%d).\n", strerror(errno), errno);
            }
            else if (numBytes > 0)
            {
                bufPtr += numBytes;
                if (*(bufPtr - 1) == '\n' || *(bufPtr - 1) == '\r') {
                    break;
                }
            }
            else {
                printf("Nothing read.\n");
            }
        } while (numBytes > 0);
        
        // NUL terminate the string and see if we got an OK response
        *bufPtr = '\0';
        
        printf("Read \"%s\"\n", logString(buffer));
        
        if (strncmp(buffer, kOKResponseString, strlen(kOKResponseString)) == 0) {
            result = true;
            break;
        }
    }
    
    return result;
}
*/
// Given the file descriptor for a serial device, close that device.
func closeSerialPort(fileDescriptor: Int) {
    // Block until all written output has been sent from the device.
    // Note that this call is simply passed on to the serial device driver.
    // See tcsendbreak(3) <x-man-page://3/tcsendbreak> for details.
    if (tcdrain(Int32(fileDescriptor)) == -1) {
        print("Error waiting for drain - \(strerror(errno))(\(errno)).")
    }
    
    // Traditionally it is good practice to reset a serial port back to
    // the state in which you found it. This is why the original termios struct
    // was saved.
    if (tcsetattr(Int32(fileDescriptor), TCSANOW, &gOriginalTTYAttrs) == -1) {
        print("Error resetting tty attributes - \(strerror(errno))(\(errno)).\n")
    }
    
    close(Int32(fileDescriptor));
}

/*
void closeSerialPort(int fileDescriptor)
{
    // Block until all written output has been sent from the device.
    // Note that this call is simply passed on to the serial device driver.
    // See tcsendbreak(3) <x-man-page://3/tcsendbreak> for details.
    if (tcdrain(fileDescriptor) == -1) {
        printf("Error waiting for drain - %s(%d).\n",
            strerror(errno), errno);
    }
    
    // Traditionally it is good practice to reset a serial port back to
    // the state in which you found it. This is why the original termios struct
    // was saved.
    if (tcsetattr(fileDescriptor, TCSANOW, &gOriginalTTYAttrs) == -1) {
        printf("Error resetting tty attributes - %s(%d).\n",
            strerror(errno), errno);
    }
    
    close(fileDescriptor);
}
*/


func main() -> Int {
    var fileDescriptor: Int
    var kernResult: kern_return_t
    var serialPortIterator:io_iterator_t = io_iterator_t()
    //var basePath: char
    
    kernResult = findModems(&serialPortIterator)
    if (KERN_SUCCESS != kernResult) {
        print("No modems were found.")
    }
    
    let bsdPath = getModemPath(serialPortIterator)
    if let path = bsdPath {
        print("Using port at parth \(path)")
    } else {
        print("No modems were found.")
    }
    
    fileDescriptor = openSerialPort(bsdPath!);
    if (-1 == fileDescriptor) {
        print("Error opening serial port")
    }
    
    if (initializeModem(fileDescriptor)) {
        print("Modem initialized successfully.");
    } else {
        print("Could not initialize modem.");
    }
    
    closeSerialPort(fileDescriptor);
    print("Modem port closed.");
    
    return Int(EX_OK)
}

/*
int main(int argc, const char * argv[])
{
    int             fileDescriptor;
    kern_return_t	kernResult;
    io_iterator_t	serialPortIterator;
    char            bsdPath[MAXPATHLEN];
    
    kernResult = findModems(&serialPortIterator);
    if (KERN_SUCCESS != kernResult) {
        printf("No modems were found.\n");
    }
    
    kernResult = getModemPath(serialPortIterator, bsdPath, sizeof(bsdPath));
    if (KERN_SUCCESS != kernResult) {
        printf("Could not get path for modem.\n");
    }
    
    IOObjectRelease(serialPortIterator);	// Release the iterator.
    
    // Now open the modem port we found, initialize the modem, then close it
    if (!bsdPath[0]) {
        printf("No modem port found.\n");
        return EX_UNAVAILABLE;
    }
    
    fileDescriptor = openSerialPort(bsdPath);
    if (-1 == fileDescriptor) {
        return EX_IOERR;
    }
    
    if (initializeModem(fileDescriptor)) {
        printf("Modem initialized successfully.\n");
    }
    else {
        printf("Could not initialize modem.\n");
    }
    
    closeSerialPort(fileDescriptor);
    printf("Modem port closed.\n");
    
    return EX_OK;
}
*/

print("Hello, World!")
main()










