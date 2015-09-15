//
//  ViewController.swift
//  BLECentralTest
//
//  Created by Dave Krawczyk on 8/17/15.
//  Copyright (c) 2015 Windy City Lab. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
  @IBOutlet weak var theLabel: UILabel!
  
    @IBOutlet weak var validatedLabel: UILabel!
  @IBOutlet weak var validatedSwitch: UISwitch!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var connectedSwitch: UISwitch!
  
    var numbersArray: [Double] = []

    override func viewDidLoad() {
    super.viewDidLoad()
    
    
    BLEManager.sharedInstance.startScan()
    BLEManager.sharedInstance.connectionCallback = ({ (result: String, connected: Bool) -> Void in
        self.connectedSwitch.on = connected ;
        
      if connected == true
      {
        self.fobConnected()
        self.connectedLabel.text = "Connected!"
        Diagnostics.writeToPlist("VC: fob connected")
      }else
      {
        self.validatedSwitch.on = false;
        self.connectedLabel.text = "Not Connected";
        self.fobDisconnected()
        Diagnostics.writeToPlist("VC: fob disconnected")
      }
    })
    
    BLEManager.sharedInstance.discoveryCallback = ({ (result: String?) -> Void in
      self.fobDiscovered()
    })
    
  }
  
    @IBAction func versionTapped(sender: AnyObject) {
        BLEManager.sharedInstance.currentFob?.checkVersion({ (value) -> Void in
            let alert = UIAlertController(title: "Version", message: "\(value)", preferredStyle: .Alert);
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil);
            alert.addAction(okAction);
            self.presentViewController(alert, animated: true, completion: nil);
        })
    }
  func fobDiscovered() {
    if let fob = BLEManager.sharedInstance.currentFob {
      self.theLabel.text = "Discovered: \(fob.name)"
        self.validatedSwitch.on = fob.isValidated();
        if fob.isValidated()
        {
            self.theLabel.textColor = UIColor.redColor()
        }
        else
        {
            self.theLabel.textColor = UIColor.blueColor()
        }
    }
    
  }
  
  func fobConnected() {
    if let fob = BLEManager.sharedInstance.currentFob {
      self.theLabel.text = "Connected: \(fob.name)"
        self.validatedSwitch.on = fob.isValidated();
    }
  }
  
  func fobDisconnected() {
    resetTapped(self)
  }

    @IBAction func batteryButtonTapped(sender: AnyObject) {
        BLEManager.sharedInstance.currentFob?.checkBattery({ (value) -> Void in
            let alert = UIAlertController(title: "Battery", message: "\(value) volts.", preferredStyle: .Alert);
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil);
            alert.addAction(okAction);
            self.presentViewController(alert, animated: true, completion: nil);
        })
    }
  
  @IBAction func clearLogButtonTapped(sender: AnyObject) {
    
    Diagnostics.clearLogFile()
  }
  
  @IBAction func resetTapped(sender: AnyObject) {
    self.theLabel.textColor = UIColor.blackColor()
    self.theLabel.text = "scanning..."
    self.view.backgroundColor = UIColor.whiteColor()
    BLEManager.sharedInstance.startScan()
  }

    @IBAction func validateSwitchTapped(sender: UISwitch) {
        if sender.on
        {
            BLEManager.sharedInstance.currentFob?.sendValidateCommand()
        }
        else
        {
            BLEManager.sharedInstance.currentFob?.sendInvalidateCommand()
        }
    }
  
  @IBAction func killButtonTapped(sender: AnyObject) {
    
    exit(0)
    
  }
  
  
    @IBAction func connectSwitchTapped(sender: UISwitch) {
       if !sender.on
       {
        BLEManager.sharedInstance.currentFob?.sendDisconnectCommand()
        }
        else
       {
        BLEManager.sharedInstance.currentFob?.connect()
        }
    }
    
    @IBAction func rebootButtonTapped(sender: AnyObject) {
        BLEManager.sharedInstance.currentFob?.reboot();
    }
  
  @IBAction func vibrateButtonTapped(sender: AnyObject) {
    BLEManager.sharedInstance.currentFob?.sendVibrateCommand()
  }
  
  @IBAction func validateButtonTapped(sender: AnyObject) {
    BLEManager.sharedInstance.currentFob?.sendValidateCommand()
  }
  
  @IBAction func invalidateButtonTapped(sender: AnyObject) {
    BLEManager.sharedInstance.currentFob?.sendInvalidateCommand()
  }
  
}

