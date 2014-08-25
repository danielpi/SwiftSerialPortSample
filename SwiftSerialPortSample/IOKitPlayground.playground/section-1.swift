// Playground - noun: a place where people can play

import CoreFoundation
import IOKit
import Cocoa


let classesToMatch = IOServiceMatching("IOSerialBSDClient").takeRetainedValue()
println("\(classesToMatch)")

// CFDictionarySetValue(classesToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDModemType));
let kIOSerialBSDTypeKeyString: NSString = "IOSerialBSDClientType"
let kIOSerialBSDTypeKeyData = kIOSerialBSDTypeKeyString.dataUsingEncoding(NSUTF8StringEncoding)
let kIOSerialBSDTypeKey: ConstUnsafePointer<()> = kIOSerialBSDTypeKeyData.bytes

let kIOSerialBSDModemTypeString: NSString = "IOModemSerialStream"
let kIOSerialBSDModemTypeData = kIOSerialBSDModemTypeString.dataUsingEncoding(NSUTF8StringEncoding)
let kIOSerialBSDModemType: ConstUnsafePointer<()> = kIOSerialBSDModemTypeData.bytes

//let kIOSerialBSDModemType: ConstUnsafePointer<()> = "IOModemSerialStream"
//CFDictionarySetValue(classesToMatch, kIOSerialBSDTypeKey, kIOSerialBSDModemType)
classesToMatch

var dict = ["IOProviderClass": "IOSerialBSDClient", "IOSerialBSDClientType": "IOModemSerialStream"]
//var cfDict: CFDictionary = dict as CFDictionary

CFStringGetTypeID
//func IOServiceGetMatchingServices(masterPort: mach_port_t, matching: CFDictionary!, existing: UnsafePointer<io_iterator_t>) -> kern_return_t
var matchingServices: io_iterator_t
let kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &matchingServices);


/*
/* Matching keys */
#define kIOSerialBSDTypeKey		"IOSerialBSDClientType"

/* Currently possible kIOSerialBSDTypeKey values. */
#define kIOSerialBSDAllTypes		"IOSerialStream"
#define kIOSerialBSDModemType		"IOModemSerialStream"
#define kIOSerialBSDRS232Type		"IORS232SerialStream"
*/

