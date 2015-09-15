//
//  Peripheral.swift
//  BLECentralTest
//
//  Created by Dave Krawczyk on 8/18/15.
//  Copyright (c) 2015 Windy City Lab. All rights reserved.
//

import CoreBluetooth
import Foundation

enum Requests {
    case Version
    case Battery
}

class Fob: NSObject {
  
    var currentRequest = Requests.Version;
    var peripheral: CBPeripheral!
    let serviceUUID = CBUUID(string: kServiceUUID)
    let receiveUUID = CBUUID(string: "FD9A1DF1-2C82-41BF-9ABE-07EB2C00FD4D")
    let sendUUID = CBUUID(string: "FD9A1DF2-2C82-41BF-9ABE-07EB2C00FD4D")
    var sendCharacteristic: CBCharacteristic!
    var name : String?
    var manager: BLEManager!
    var value : Float = 3.1415
    var whenComplete : ((value : Float) -> Void)!
    var whenCompleteInt : ((value : Int) -> Void)!
    
    override init() {
        super.init()
    }

    convenience init(peripheral: CBPeripheral) {
        self.init()

        self.peripheral = peripheral
        self.peripheral.delegate = self
    }

    func isValidated()->Bool
    {
        return self.name == "!GL";
    }
    
    func connect()
    {
        BLEManager.sharedInstance.connectToPeripheral(BLEManager.sharedInstance.currentFob!.peripheral);
    }
    
    func connected() {

    self.peripheral.discoverServices([serviceUUID])

    }


    func writeToPeripheral(bytes: [UInt8]) {
    let sendData = NSData(bytes: bytes, length: bytes.count)
    Diagnostics.writeToPlist(">>>>>>> Sending: \(bytes)")
    self.peripheral.writeValue(sendData, forCharacteristic: sendCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }

    func sendDisconnectCommand() {
    self.writeToPeripheral([0x1, 0x2])
    }

    func sendVibrateCommand() {
    self.writeToPeripheral([0x2, 0x4])
    }

    func sendValidateCommand() {
    self.writeToPeripheral([0x1, 0x1])
    }

    func sendInvalidateCommand() {
    self.writeToPeripheral([0x1, 0x0])
    }

    func checkBattery(complete:(value : Float) -> Void)
    {
        currentRequest = .Battery
        whenComplete = complete;
        self.writeToPeripheral([0x3, 0x1]);
    }
    func checkVersion(complete:(value : Int) -> Void)
    {
        currentRequest = .Version;
        whenCompleteInt = complete;
        self.writeToPeripheral([0x3, 0x3]);
    }
    
    func reboot()
    {
        self.writeToPeripheral([0x5,0x0]);
    }

}

extension Fob: CBPeripheralDelegate {
  
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    Diagnostics.writeToPlist("didDiscoverCharacteristicsForService")
    
      for characteristic in service.characteristics!  {
        
        if characteristic.UUID == self.receiveUUID {
          
          Diagnostics.writeToPlist("got received characteristic")
          self.peripheral.setNotifyValue(true, forCharacteristic: characteristic)
          
        } else if characteristic.UUID == sendUUID {
          
          Diagnostics.writeToPlist("got send characteristic")
          sendCharacteristic = characteristic
          
        }
      }
    
  }
  
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    Diagnostics.writeToPlist("didDiscoverServices")
    self.peripheral.discoverCharacteristics(nil, forService: peripheral.services!.first!)
  }
 
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    Diagnostics.writeToPlist("didUpdateValueForCharacteristic")
    Diagnostics.writeToPlist("did receive value of \(characteristic.value)");
    switch currentRequest
    {
        case .Battery:
            var values = [UInt8](count:2, repeatedValue:0);
            characteristic.value!.getBytes(&values, length: 2);
            var result = Float(values[0]) + Float(values[1]) / 100;
            Diagnostics.writeToPlist("converting to float \(result)");
            whenComplete(value:result);
        case .Version:
            var values = [UInt8](count:2, repeatedValue:0);
            characteristic.value!.getBytes(&values, length: 2);
            var result = Int(values[1]) * 256 + Int(values[0]);
            Diagnostics.writeToPlist("converting to int \(result)");
            whenCompleteInt(value:result);
    }
  }
}