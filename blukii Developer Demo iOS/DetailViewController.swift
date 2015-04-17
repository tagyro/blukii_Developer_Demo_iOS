//
//  DetailViewController.swift
//  Hello-Blukii-App-1
//
//  Created by Lennart Fleig on 07.04.15.
//  Copyright (c) 2015 Lennart Fleig. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlukiiKit


class DetailViewController: UIViewController {
    
    
    var blukii: CBPeripheral?
    
    @IBOutlet var lbFirmware: UILabel!
    @IBOutlet var lbHardwareVersion: UILabel!
    @IBOutlet var lbManufactor: UILabel!
    @IBOutlet var lbBattery: UILabel!
    @IBOutlet var lbBlukiiName: UILabel!
    @IBOutlet var lbTemperatur: UILabel!
    @IBOutlet var lbX: UILabel!
    @IBOutlet var lbY: UILabel!
    @IBOutlet var lbZ: UILabel!

    
    typealias BKProfileOperationCompletion = (characteristic: CBCharacteristic, error: NSError?) -> ()
    var blukiiContext: BKBlukiiDeviceContext?
    
    var blukiiDescription: BKBlukiiDescription?
    
    var blukiiName: NSString?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if blukii == nil {
            let alert = UIAlertView(title: "No Blukii Selected", message: "Please choose a Blukii.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            loadProfiles()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        stopAll()
        blukiiDescription = nil
        blukiiContext = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btRefreshData(sender: AnyObject) {

        println("getData")
        
        self.blukiiContext?.blukiiDescription.determineDeviceInformation(completeWith: {
            (error: NSError?) -> () in
            if error == nil {
                self.lbBlukiiName.text = self.blukii?.name
                self.lbFirmware.text = self.blukiiContext?.blukiiDescription.firmwareRevisionString
                self.lbHardwareVersion.text = self.blukiiContext?.blukiiDescription.hardwareRevision
                self.lbManufactor.text = self.blukiiContext?.blukiiDescription.manufacterName
            } else {
                println(error)
            }
        })

        self.blukiiContext?.temperature?.enableProfile({
            (characteristic, error) -> () in
            if error == nil {
                self.blukiiContext?.temperature?.updateValue({
                    (characteristic, error) -> () in
                    if error == nil {
                        let temperature = self.blukiiContext?.temperature?.value
                        self.lbTemperatur.text = String(format: "%f", temperature!)
                    } else {
                        println(error)
                    }
                })
            } else {
                println(error)
            }
        })

        
        self.blukiiContext?.batteryService?.updateBatteryLevel({
             (characteristic, error) -> () in
            if error == nil {
                let batteryLevel = self.blukiiContext?.batteryService?.batteryLevel
                self.lbBattery.text = String (batteryLevel!)
            } else {
                println(error)
            }

        })
        
    }
    
   
    func loadProfiles(){
        var hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.labelText = "Load Profiles"
        blukiiDescription = BKBatteryServiceProfileLoader.evaluatePeripheral(blukii!)
        //Load Temperature-Profile
        BKTemperatureProfileLoader().loadProfileForBlukii(self.blukiiDescription!, completeWith: {
            (blukiiDeviceContext: BKBlukiiDeviceContext?, error: NSError?) -> () in
            if error == nil {
                self.blukiiContext = blukiiDeviceContext!
                println("Blukii Temperature Ready")
                BKBatteryServiceProfileLoader().loadProfileForBlukii(self.blukiiDescription!, completeWith: {
                    (blukiiDeviceContext: BKBlukiiDeviceContext?, error: NSError?) -> () in
                    if error == nil {
                        self.blukiiContext = blukiiDeviceContext
                        println("Blukii Battery Status Ready")
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    } else {
                        println(error)
                    }
                })
            } else {
                println(error)
            }
            
        })
        // You can only run one request at a time.
        // Es kann immer nur eine Abfrage zur gleichen Zeit ablaufen. Folgende Fehlermeldung erscheint, wenn versucht wird mehrere abfragen auf einmal zu starten:
        //    [WARNING | API MISUSE]: determineDeviceInformation(completeWith:) already running. This call will be ignored and the completion will never be executed.
    }
    
    func stopAll(){
        self.blukiiContext?.temperature?.disableProfile({ (characteristic, error) -> () in
            if error == nil {
                println("Temperature Successful disabled")
            } else {
                println(error)
            }
        })
    }

}
