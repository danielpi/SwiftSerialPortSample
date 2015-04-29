SwiftSerialPortSample
=====================

An attempt to convert Apples SerialPortSample project over to Swift

The serial port sample from Apple is a simple application written in C that shows some of the tasks required for interacting with a serial port from Mac OS X. It covers IOKit as well as the POSIX commands that are used to find serial ports, open them, change their attributes etc.

As a C program there are a lot of challenges in converting this over to Swift. CoreFoundation is supposedly simple to use from Swift, though I have found a few issues. The POSIX function calls are not very well supported as of Beta 6 and I haven't figured out good work arounds yet. 

### Issues, Annoyances
C Structs need to be initialised before being used. This leads to the following code when trying to use a termios structure

	var gOriginalTTYAttrs: termios = termios(	c_iflag: 0, 
												c_oflag: 0, 
												c_cflag: 0, 
												c_lflag: 0, 
												c_cc: 	(0, 0, 0, 0, 0, 0, 0, 0, 
														 0, 0, 0, 0, 0, 0, 0, 0, 
														 0, 0, 0, 0), 
												c_ispeed: 0, 
												c_ospeed: 0)

It took me a little while to figure out how to access the serial parts of IOKit. In the end it is pretty simple

	import IOKit
	import IOKit.serial

Working with CFDictionaries is a bit cumbersome. I believe that they should be toll free bridged to the Dictionary type but for now I have had to perform multiple casts to get them to work

	var classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue).takeUnretainedValue()
    var classesToMatchDict = (classesToMatch as NSDictionary) as Dictionary<String, AnyObject>
    
I was then able to modify the Dictionary using subscripts and then cast it back to a CFDictionaryRef (Why not a CFDictionary??) in order to use it for IOServiceGetMatchingServices.

	classesToMatchDict[kIOSerialBSDTypeKey] = kIOSerialBSDModemType
    let classesToMatchCFDictRef = (classesToMatchDict as NSDictionary) as CFDictionaryRef
        
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatchCFDictRef, &serialPortIterator);
    
IORegistryEntryCreateCFProperty returns an ANYObject? rather than a String?

I'm not sure how you work with arrays within C structures (I'm not very good with C though so might be my own ignorance) 

	options.c_cc[VMIN] = 0;
	
ioctl and fcntl are apparently not automatically bridged. 

So far I haven't been able to open a port or read or change any attributes either (despite that code at least compiling). 