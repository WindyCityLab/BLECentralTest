//
//  BLEManager.swift
//  BLECentralTest
//
//  Created by Dave Krawczyk on 8/17/15.
//  Copyright (c) 2015 Windy City Lab. All rights reserved.
//

import CoreBluetooth
import UIKit

class BLEManager: NSObject, CBCentralManagerDelegate {
  
  static let sharedInstance = BLEManager()
  var customUUID:         CBUUID!
  
  var centralManager:     CBCentralManager!
  var currentFob:  Fob?
  
  var connectionCallback: ((name: String, connected: Bool) -> Void)!
  var discoveryCallback: ((name: String?) -> Void)!
  
  override init() {
    super.init()
    
    Diagnostics.writeToPlist("BLEManager init")
    
    
    customUUID = CBUUID(string: kGLCustomUUID)
    
    self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: kGLRestoreIdentifier])
    self.isBLESupported()
    
  }
  
  //MARK: Actions
  func startScan() {
    Diagnostics.writeToPlist("startScan for peripherals with UUID : \(customUUID)")
    
    self.centralManager.scanForPeripheralsWithServices([customUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(bool: true), CBCentralManagerScanOptionSolicitedServiceUUIDsKey : [customUUID]])
//    self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
  }
  
  func stopScan() {
    Diagnostics.writeToPlist("Stopping scan")
    
    self.centralManager.stopScan()
  }
  
  func isBLESupported() -> Bool {
    
    if self.centralManager.state == CBCentralManagerState.PoweredOn
    {
      return true
    }
    
    var logMessage: String
    switch self.centralManager.state {
    case .PoweredOn:
      logMessage = "BLE is on and ready"
      break;
    case .Unsupported:
      logMessage = "This hardware doesn't support Bluetooth Low Energy"
      break;
    case .Unauthorized:
      logMessage = "This app is not authorized to use Bluetooth Low Energy"
      break;
    case .PoweredOff:
      logMessage = "Bluetooth is currently powered off"
      break;
    case .Unknown:
      logMessage = "Bluetooth state unknown"
      break;
    default:
      logMessage = "Bluetooth state is seriously unknown: \(self.centralManager.state)"
      break;
    }
    
    Diagnostics.writeToPlist(logMessage)
    print("logMessage")
    
    return false
  }
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        
        Diagnostics.writeToPlist("willRestoreState with dictionary: \(dict.description)")
        
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        self.currentFob?.connected()
        Diagnostics.showNotificationWithMessage("connected to peripheral: \(peripheral.name)")
        
        connectionCallback(name: peripheral.name!, connected: true)
        stopScan();
        
        
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        Diagnostics.writeToPlist("didDisconnectPeripheral")
        connectionCallback(name: peripheral.name!, connected: false)
        
        if let fob = self.currentFob {
            self.centralManager.connectPeripheral(fob.peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(bool: true),
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool: true),
                CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(bool: true)])
            
        }
        
        
    }
    
    func connectToPeripheral(peripheral : CBPeripheral)
    {
        Diagnostics.writeToPlist("connectToPeripheral");
        
        self.centralManager.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(bool: true),
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool: true),
            CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(bool: true)])
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        stopScan();
      Diagnostics.writeToPlist("didDiscoverPeripheral");
      Diagnostics.writeToPlist(advertisementData.description);

      
//        Diagnostics.showNotificationWithMessage("discovered peripheral: \(peripheral.name)")
//        Diagnostics.writeToPlist("discovered peripheral advertising: \(advertisementData)")
//        
        if self.currentFob == nil {
            self.currentFob = Fob(peripheral: peripheral)
        }
        self.currentFob?.name = advertisementData["kCBAdvDataLocalName"] as? String!;
//
//        
        Diagnostics.showNotificationWithMessage("\(self.currentFob?.name) discovered")
        discoveryCallback(name: self.currentFob?.name)
//
        self.connectToPeripheral(peripheral)
      
        //    self.centralManager.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(bool: true),
        //        CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool: true),
        //        CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(bool: true)])
        
    }
    
    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: [AnyObject]!) {
        Diagnostics.writeToPlist("didRetrieveConnectedPeripherals")
        
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        Diagnostics.writeToPlist("didFailToConnectPeripheral")
        
        if let fob = self.currentFob {
            self.centralManager.connectPeripheral(fob.peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(bool: true),
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool: true),
                CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(bool: true)])
            
        }
        
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        Diagnostics.writeToPlist("centralManagerDidUpdateState")
        
        switch central.state {
            
        case CBCentralManagerState.PoweredOn:
            Diagnostics.writeToPlist("BLE State -> Powered On")
            startScan()
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationBluetoothJustBecameAvailable, object: nil, userInfo: nil)
            return
            
        case CBCentralManagerState.Unauthorized:
            Diagnostics.writeToPlist("BLE State -> Unauthorized")
            
            break
            
        case .PoweredOff:
            Diagnostics.writeToPlist("BLE State -> Powered Off")
            
            break
            
        case .Resetting:
            Diagnostics.writeToPlist("BLE State -> Resetting")
            break
            
        case .Unknown:
            Diagnostics.writeToPlist("BLE State -> Unknown")
            
            break
            
        default:
            break
        }
    }

}