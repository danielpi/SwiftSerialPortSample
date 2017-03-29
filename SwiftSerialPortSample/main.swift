//
//  main.swift
//  SwiftSerialPortSample
//
//  Created by Daniel Pink on 4/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//


import Cocoa
import CoreFoundation
import IOKit
import IOKit.serial



// Default to local echo being on. If your modem has local echo disabled, undefine the following macro.
let LOCAL_ECHO = true

// Find the first device that matches the callout device path MATCH_PATH.
// If this is undefined, return the first device found.
let MATCH_PATH = "/dev/tty.usbserial-FTFWP23E"

let kATCommandString = "AT\r\n"

var kOKResponseString = "\r\nOK\r\n"
if LOCAL_ECHO {
    kOKResponseString = "AT\r\r\nOK\r\n"
}

let kNumRetries = 3

// Hold the original termios attributes so we can reset them
var gOriginalTTYAttrs: termios = termios()


// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
func findModems(_ serialPortIterator: inout io_iterator_t ) -> kern_return_t {
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
func getModemPath(_ serialPortIterator: io_iterator_t) -> String? {
    var modemService: io_object_t
    var modemFound = false
    var bsdPath: String? = nil
    
    // Iterate across all modems found. Use the last one
    repeat {
        modemService = IOIteratorNext(serialPortIterator)
        guard modemService != 0 else { continue }
        
        if let aPath = IORegistryEntryCreateCFProperty(modemService,
                                                       "IOCalloutDevice" as CFString,
                                                       kCFAllocatorDefault, 0).takeUnretainedValue() as? String {
            print("Found \(aPath)")
            bsdPath = aPath
            if (aPath == MATCH_PATH) {
                modemFound = true
            }
        }
    
    } while (modemService != 0 && !modemFound)
    
    return bsdPath
}

struct FCNTLOptions : OptionSet {
    let rawValue: CInt
    init(rawValue: CInt) { self.rawValue = rawValue }
    
    static let  O_RDONLY        = FCNTLOptions(rawValue: 0x0000)
    static let  O_WRONLY        = FCNTLOptions(rawValue: 0x0001)
    static let  O_RDWR          = FCNTLOptions(rawValue: 0x0002)
    static let  O_ACCMODE       = FCNTLOptions(rawValue: 0x0003)
    static let  O_NONBLOCK      = FCNTLOptions(rawValue: 0x0004)
    static let  O_APPEND        = FCNTLOptions(rawValue: 0x0008)
    static let 	O_SHLOCK        = FCNTLOptions(rawValue: 0x0010)		/* open with shared file lock */
    static let 	O_EXLOCK        = FCNTLOptions(rawValue: 0x0020)		/* open with exclusive file lock */
    static let 	O_ASYNC         = FCNTLOptions(rawValue: 0x0040)		/* signal pgrp when data ready */
    //static let 	O_FSYNC     = FCNTLOptions(rawValue: O_SYNC         /* source compatibility: do not use */
    static let  O_NOFOLLOW      = FCNTLOptions(rawValue: 0x0100)        /* don't follow symlinks */
    static let 	O_CREAT         = FCNTLOptions(rawValue: 0x0200)		/* create if nonexistant */
    static let 	O_TRUNC         = FCNTLOptions(rawValue: 0x0400)		/* truncate to zero length */
    static let 	O_EXCL          = FCNTLOptions(rawValue: 0x0800)		/* error if already exists */
    static let	O_EVTONLY       = FCNTLOptions(rawValue: 0x8000)		/* descriptor requested for event notifications only */
    
    static let	O_NOCTTY        = FCNTLOptions(rawValue: 0x20000)		/* don't assign controlling terminal */
    static let  O_DIRECTORY     = FCNTLOptions(rawValue: 0x100000)
    static let  O_SYMLINK       = FCNTLOptions(rawValue: 0x200000)      /* allow open of a symlink */
    static let	O_CLOEXEC       = FCNTLOptions(rawValue: 0x1000000)     /* implicitly set FD_CLOEXEC */
    //static let BoxOrBag: PackagingOptions = [Box, Bag]
    //static let BoxOrCartonOrBag: PackagingOptions = [Box, Carton, Bag]
}


func openSerialPort(_ bsdPath: String) -> Int {
    //var fileDescriptor: Int = -1
    var options: termios
    
    // Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
    // The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
    // See open(2) <x-man-page://2/open> for details.
    
    let openOptions: FCNTLOptions = [.O_RDWR, .O_NOCTTY, .O_NONBLOCK]
    let fileDescriptor = open(bsdPath, openOptions.rawValue);
    if (fileDescriptor == -1) {
        print("Error opening port")
    }
    
    // Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
    // unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
    // processes.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    var result = ioctl(fileDescriptor, TIOCEXCL)
    if (result == -1) {
        print("Error setting TIOCEXCL")
    }
    
    // Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
    // See fcntl(2) <x-man-page//2/fcntl> for details.
    
    result = fcntl(fileDescriptor, F_SETFL, 0)
    if (result == -1) {
        print("Error clearing O_NONBLOCK \(bsdPath) - \(strerror(errno))(\(errno))")
        //goto error
    }
    
    // Get the current options and save them so we can restore the default settings later.
    result = tcgetattr(fileDescriptor, &gOriginalTTYAttrs)
    if (result == -1) {
        print("Error getting attributes \(bsdPath) - \(strerror(errno))(\(errno))")
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
    
    cfmakeraw(&options)
    //options.c_cc[VMIN] = 0
    //options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    
    cfsetspeed(&options, 57600);		// Set 19200 baud
    options.c_cflag |= UInt(CS7          |   // Use 7 bit words
                            PARENB       |   // Parity enable (even parity if PARODD not also set)
                            CCTS_OFLOW   |   // CTS flow control of output
                            CRTS_IFLOW)      // RTS flow control of input
    
    // The IOSSIOSPEED ioctl can be used to set arbitrary baud rates
    // other than those specified by POSIX. The driver for the underlying serial hardware
    // ultimately determines which baud rates can be used. This ioctl sets both the input
    // and output speed.
    
    //let speed: speed_t = 2400; // Set 14400 baud
    //result = ioctlIOSSIOSPEED(fileDescriptor, UnsafeMutablePointer(bitPattern: speed))
    //result = ioctl(fileDescriptor, IOSSIOSPEED, 2400)
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
    
    // To set the modem handshake lines, use the following ioctls.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.

    // Assert Data Terminal Ready (DTR)
    if(ioctl(fileDescriptor, TIOCSDTR) == -1) {
        print("Error asserting DTR \(bsdPath) - \(strerror(errno))(\(errno)).")
    }
    
    // Clear Data Terminal Ready (DTR)
    if(ioctl(fileDescriptor, TIOCCDTR) == -1) {
        print("Error clearing DTR \(bsdPath) - \(strerror(errno))(\(errno))")
    }
    
    // Set the modem lines depending on the bits set in handshake
    var handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR
    if(ioctl(fileDescriptor, TIOCMSET, &handshake) == -1) {
        print("Error setting handshake lines \(bsdPath) - \(strerror(errno))(\(errno))")
    }
    
    // To read the state of the modem lines, use the following ioctl.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.

    // Store the state of the modem lines in handshake
    if(ioctl(fileDescriptor, TIOCMGET, &handshake) == -1){
        print("Error getting handshake lines \(bsdPath) - \(strerror(errno))(\(errno))")
    }
    print("Handshake lines currently set to \(handshake)")
    
    /*
    // Set the receive latency in microseconds. Serial drivers use this value to determine how often to
    // dequeue characters received by the hardware. Most applications don't need to set this value: if an
    // app reads lines of characters, the app can't do anything until the line termination character has been
    // received anyway. The most common applications which are sensitive to read latency are MIDI and IrDA
    // applications.
    var mics = 1
    
    if(ioctl(fileDescriptor, IOSSDATALAT, &mics) == -1) {
        // set latency to 1 microsecond
        print("Error setting read latency \(bsdPath) - \(strerror(errno))(\(errno))")
        //goto error
    }
    */
    // Success
    return Int(fileDescriptor)
}

/*
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
func initializeModem(_ fileDescriptor: Int) -> Bool {
    var result = false
    var buffer: Array<CChar> = Array(repeating: 0, count: 256)
    var stringBuffer: String =  ""
    
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
        repeat {
            numBytes = read(Int32(fileDescriptor), &buffer, buffer.count)
            
            if (numBytes == -1) {
                print("Error reading from modem - \(strerror(errno))(\(errno)).\n")
            } else if (numBytes > 0) {
                // NUL terminate the string and see if we got an OK response
                buffer[numBytes] = 0
                if let returned = String(validatingUTF8: buffer) {
                    print("Read: \(returned)")
                    stringBuffer += returned
                }
            }
            else {
                print("Nothing read.")
            }
        } while (numBytes > 0)
        
        if stringBuffer == kOKResponseString {
            result = true
        }
    }
    
    return result
}


// Given the file descriptor for a serial device, close that device.
func closeSerialPort(_ fileDescriptor: Int) {
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
        print("Using port at path \(path)")
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

let result = main()
print(result)









