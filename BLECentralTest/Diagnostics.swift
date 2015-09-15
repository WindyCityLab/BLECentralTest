//
//  Diagnostics.swift
//  LlamaWrangler Jr
//
//  Created by Dave Krawczyk on 8/13/15.
//  Copyright (c) 2015 Windy City Lab. All rights reserved.
//

import Foundation
import UIKit

let logFileName = "debug.txt"

class Diagnostics {
 
  class func showNotificationWithMessage(message: String) {
    
    self.writeToPlist(message)
    let localnotification = UILocalNotification()
    localnotification.alertBody = message
    UIApplication.sharedApplication().presentLocalNotificationNow(localnotification)

  }
  
  class func clearLogFile() {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
//    let path = paths.stringByAppendingPathComponent(logFileName)
//
//    do {
//      try NSFileManager.defaultManager().removeItemAtPath(path)
//    } catch _ {
//    }
    
    
  }
  class func writeToPlist(message:String!) {
    
    print(message)
    let paths : NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let path = paths.stringByAppendingPathComponent(logFileName)
    
    if !NSFileManager.defaultManager().fileExistsAtPath(path) {
      NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
    }
    

    let now = NSDate()
    let format = NSDateFormatter()
    format.dateFormat = "HH:mm:ss.SSS"
    let stringToWrite = "\(format.stringFromDate(now)) --- \(message)\n"
    let file = NSFileHandle(forUpdatingAtPath: path)
    file?.seekToEndOfFile()
    file?.writeData(stringToWrite.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    file?.closeFile()
    
  }
}


/*

NSString *content = @"This is my log";

//Get the file path
NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"myFileName.txt"];

//create file if it doesn't exist
if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
[[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];

//append text to file (you'll probably want to add a newline every write)
NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
[file seekToEndOfFile];
[file writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
[file closeFile];


*/