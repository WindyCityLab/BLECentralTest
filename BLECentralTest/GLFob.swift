//
//  GLFob.swift
//  LlamaWrangler Jr
//
//  Created by Dave Krawczyk on 7/10/15.
//  Copyright (c) 2015 Windy City Lab. All rights reserved.
//

import Foundation
import CoreBluetooth

class GLFob: NSObject, CBPeripheralDelegate {
  
  var peripheral:         CBPeripheral!
  var name:               String!
  var UUID:               String!
  var advertData:         NSData!
  var advertRSSI:         NSNumber!
  var advertPackets:      NSInteger! = 0
  var lastAdvert:         NSDate!
  var outOfRange:         Bool!
  var manager:            BLEManager!
  
  var serviceUUID:        CBUUID!
  var sendUUID:           CBUUID!
  var receiveUUID:        CBUUID!
  var disconnectUUID:     CBUUID!
  var sendCharacteristic: CBCharacteristic!
  
  var loadedService:       Bool?
  var isInPairingMode:     Bool!
  
  
  func connected() {
    serviceUUID = CBUUID(string: kServiceUUID)
    sendUUID  = incrementUUID16(serviceUUID, byAmount: 1)
    receiveUUID = incrementUUID16(serviceUUID, byAmount: 2)
    disconnectUUID = incrementUUID16(serviceUUID, byAmount: 3)
    
    self.peripheral.delegate = self
    self.peripheral.discoverServices([serviceUUID])
  }
  
  
  func incrementUUID16(uuid: CBUUID, byAmount: UInt8) ->CBUUID {
    let uuidData = uuid.data
    
    // the number of elements:
    let count = uuidData.length / sizeof(UInt8)
    
    // create array of appropriate length:
    var bytesArray = [UInt8](count: count, repeatedValue: 0)
    
    // copy bytes into array
    uuidData.getBytes(&bytesArray, length:count * sizeof(UInt32))
    
    let result = bytesArray[3] + byAmount
    if result < bytesArray[3]
    {
      bytesArray[2]++
    }
    bytesArray[3] += byAmount
    
    return CBUUID(data: NSData(bytes: bytesArray, length: bytesArray.count))
  }
  
  
  func send(data: NSData) {
    print(">>>>>>> Sending: \(data)")
    
    if loadedService == false || data.length > kMaxSendData {
      print("Bad Send")
    } else {
      self.peripheral.writeValue(data, forCharacteristic: sendCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }
  }
  
  func sendDisconnectCommand() {
    let disconnectData = NSData.dataFromBytes([0x1, 0x2])
    self.send(disconnectData)
  }
  
  func sendVibrateCommand() {
    let vibrateData = NSData.dataFromBytes([0x2, 0x4])
    self.send(vibrateData)
  }
  
  
  func sendValidateCommand() {
    let validateCommand = NSData.dataFromBytes([0x1, 0x1])
    self.send(validateCommand)
  }
  
  
  func sendInvalidateCommand() {
    let invalidateCommand = NSData.dataFromBytes([0x1, 0x0])
    self.send(invalidateCommand)
  }
  
  override var description: String {
    let descriptionString = "Name: \t\t\t\t\(name!)\nUUID: \t\t\t\t\(UUID!)\nRSSI: \t\t\t\t\(advertRSSI!)\nLast Seen: \t\t\t\t\(lastAdvert!)\nOut of Range: \t\t\t\t\(self.outOfRange!)"
    return descriptionString
  }
  
  
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    print("didDiscoverServices")
    
    self.peripheral.discoverCharacteristics(nil, forService: peripheral.services!.first!)
    
    //    for service in self.peripheral.services {
    //      if service.UUIDString == serviceUUID {
    ////        var characteristics = [receiveUUID, sendUUID, sendUUID, disconnectUUID]
    //        println("discovering characteristics for service: \(service)")
    //
    //        self.peripheral.discoverCharacteristics(nil, forService: service as! CBService)
    //      }
    //    }
  }
  
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    print("didDiscoverCharacteristicsForService")
    
    for service in self.peripheral.services! {
      //      if service.UUIDString == serviceUUID {
      for characteristic in service.characteristics!  {
        
        
        if characteristic.UUID == self.receiveUUID {
          
          print("got received characteristic")
          self.peripheral.setNotifyValue(true, forCharacteristic: characteristic)
          
        } else if characteristic.UUID == sendUUID {
          
          print("got send characteristic")
          sendCharacteristic = characteristic
        }
      }
      
      var characteristicsArray: [CBCharacteristic] = service.characteristics!
      loadedService = characteristicsArray.count > 0
      
      if loadedService == true
      {
        if self.isInPairingMode == false {
          NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAlert, object: nil)
        } else {
          if peripheral.name == "?GL" {
            NSUserDefaults.standardUserDefaults().setObject(peripheral.identifier.UUIDString, forKey: kGLDeviceUUID)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            //Validate FOB
            self.isInPairingMode = false
            let validateData = NSData.dataFromBytes([0x1, 0x1])
            self.send(validateData)
            
            //Enable watchdog
            let watchDogData = NSData.dataFromBytes([0x6, 0xD, 0x1])
            self.send(watchDogData)
            
            //Increase advertising freq to 20ms
            let advertisingData = NSData.dataFromBytes([0x6, 0x8, 0x32, 0x30])
            self.send(advertisingData)
            
            //Write to flash so it is retained
            let writeFlashData = NSData.dataFromBytes([0x4, 0x1])
            self.send(writeFlashData)
            
            //Vibrate motor to confirm
            let vibrateData = NSData.dataFromBytes([0x2, 0x4])
            self.send(vibrateData)
            
            //Disconnect from FOB
            self.sendDisconnectCommand()
            
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationPairingComplete, object: nil)
          } else {
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationFOBAlreadyPairedError, object: nil)
          }
        }
      }
      //      }
    }
  }
  
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    print("didUpdateValueForCharacteristic")
    
    if characteristic.UUID == receiveUUID {
      self.sendVibrateCommand()
      self.sendDisconnectCommand()
      
    }
  }
}

extension NSData {
  
  class func dataFromBytes(bytes: [UInt8]) -> NSData {
    return NSData(bytes: bytes, length: bytes.count)
  }
  
}
