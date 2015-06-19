SwiftSerialPortSample
=====================

An attempt to convert Apples SerialPortSample project over to Swift

The [serial port sample](https://developer.apple.com/library/mac/samplecode/SerialPortSample/Introduction/Intro.html) from Apple is a simple application written in C that shows some of the tasks required for interacting with a serial port from Mac OS X. It covers IOKit as well as the POSIX commands that are used to find serial ports, open them, change their attributes etc.

As a C program there are a lot of challenges in converting this over to Swift. CoreFoundation is supposedly simple to use from Swift, though I have found a few issues. The POSIX function calls are not very well supported either.

This experiment has been updated to Swift 2.0 and is actually slightly functional.

### Issues, Annoyances

ioctl and fcntl aren't useable from Swift as they need varags.

