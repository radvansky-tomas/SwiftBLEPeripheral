//
//  BLEPeriferalServer.swift
//  BLEPeriferal
//
//  Created by Tomas Radvansky on 20/10/2015.
//  Copyright © 2015 Radvansky Solutions. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BLEPeriferalServerDelegate
{
    func periferalServer(periferal:BLEPeriferalServer, centralDidSubscribe:CBCentral)
    func periferalServer(periferal:BLEPeriferalServer, centralDidUnsubscribe:CBCentral)
}

class BLEPeriferalServer: NSObject,CBPeripheralManagerDelegate {
    //MARK:-Public
    var serviceName:String?
    var serviceUUID:CBUUID?
    var characteristicUUID:CBUUID?
    
    var delegate:BLEPeriferalServerDelegate?
    //MARK:-Private
    var peripheral:CBPeripheralManager?
    var characteristic:CBMutableCharacteristic?
    var serviceRequiresRegistration:Bool?
    var service:CBMutableService?
    var pendingData:NSData?
    
    init(withDelegate delegate:BLEPeriferalServerDelegate)
    {
        super.init()
        self.peripheral = CBPeripheralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    class func isBluetoothSupported()->Bool
    {
        if (NSClassFromString("CBPeripheralManager")==nil)
        {
            return false
        }
        return true
    }
    
    func sendToSubscribers(data:NSData)
    {
        if (self.peripheral?.state != CBPeripheralManagerState.PoweredOn)
        {
            print("sendToSubscribers: peripheral not ready for sending state: %d", self.peripheral!.state.rawValue)
            return
        }
        
        if let success:Bool = (self.peripheral?.updateValue(data, forCharacteristic: self.characteristic!, onSubscribedCentrals: nil))!
        {
            if !success
            {
                print("Failed to send data, buffering data for retry once ready.")
                self.pendingData = data
                return
            }
    }
    }
    
    func applicationDidEnterBackground()
    {
        
    }
    
    func applicationWillEnterForeground()
    {
        print("applicationWillEnterForeground")
    }
    
    func startAdvertising()
    {
       if self.peripheral?.isAdvertising == true
       {
        self.peripheral?.stopAdvertising()
        }
        
        let advertisement:[String:AnyObject]? = [CBAdvertisementDataServiceUUIDsKey:[self.serviceUUID!], CBAdvertisementDataLocalNameKey:self.serviceName!]
        
        self.peripheral?.startAdvertising(advertisement)
        
    }
    
    func stopAdvertising()
    {
        self.peripheral?.stopAdvertising()
    }
    
    func isAdvertising()->Bool?
    {
        return self.peripheral?.isAdvertising
    }
    
    func disableService()
    {
        self.peripheral?.removeService(self.service!)
        self.service = nil
        self.stopAdvertising()
    }
    
    func enableService()
    {
        if (self.service != nil)
        {
            self.peripheral?.removeService(self.service!)
        }
        
        self.service = CBMutableService(type: self.serviceUUID!, primary: true)
        
        self.characteristic = CBMutableCharacteristic (type: self.characteristicUUID!, properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable)
        
        var characteristics = [CBMutableCharacteristic]()
        characteristics.append( self.characteristic!)
        
        self.service?.characteristics = characteristics
        
        self.peripheral?.addService(self.service!)
        
        let runAfter : dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        
        dispatch_after(runAfter, dispatch_get_main_queue()) { () -> Void in
            self.startAdvertising()
        }
    }
    
    //MARK:-CBPeripheralManagerDelegate
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        //self.startAdvertising()
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        switch (peripheral.state) {
        case CBPeripheralManagerState.PoweredOn:
            print("peripheralStateChange: Powered On")
            // As soon as the peripheral/bluetooth is turned on, start initializing
            // the service.
            self.enableService()
        case CBPeripheralManagerState.PoweredOff:
            print("peripheralStateChange: Powered Off")
            self.disableService()
            self.serviceRequiresRegistration = true
        case CBPeripheralManagerState.Resetting:
            print("peripheralStateChange: Resetting");
            self.serviceRequiresRegistration = true
        case CBPeripheralManagerState.Unauthorized:
            print("peripheralStateChange: Deauthorized");
            self.disableService()
            self.serviceRequiresRegistration = true
        case CBPeripheralManagerState.Unsupported:
            print("peripheralStateChange: Unsupported");
            self.serviceRequiresRegistration = true
            // TODO: Give user feedback that Bluetooth is not supported.
        case CBPeripheralManagerState.Unknown:
            print("peripheralStateChange: Unknown")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        self.delegate?.periferalServer(self, centralDidSubscribe: central)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        self.delegate?.periferalServer(self, centralDidUnsubscribe: central)
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        print(error?.localizedDescription)
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        print("isReadyToUpdateSubscribers")
        if let data:NSData = self.pendingData
        {
            self.sendToSubscribers(data)
        }
    }
}
