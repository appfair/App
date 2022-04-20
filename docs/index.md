---
layout: fairapp
---

Blunder Busq is a macOS app that connects to your iOS devices
and enables viewing device metadata and browsing the installed applications.

Devices can be accessed using wired (lightning) or wireless (WiFi)
connections, provided they have already been "trusted" by the computer.

Blunder Busq requires macOS 12 and can be installed 
with [App Fair.app](https://appfair.app), or by using
homebrew:

```
$ brew install appfair/app/blunder-busq
```

Blunder Busq is free and
[open source](https://github.com/Blunder-Busq/App/blob/main/Sources/App/AppContainer.swift), and is released under the GNU AGPL.

For feedback and support, please see the
[Discussions](https://github.com/Blunder-Busq/App/discussions)
and
[Issues](https://github.com/Blunder-Busq/App/issues)
pages.


## Usage

Information about the following permissions for each app,
along with their claimed usage descriptions, 
is shown when selecting the app.

  - User Tracking (`NSUserTrackingUsageDescription`)
  - Location (Always) (`NSLocationAlwaysUsageDescription`)
  - Location (Temporary) (`NSLocationTemporaryUsageDescriptionDictionary`)
  - Location (When in use) (`NSLocationWhenInUseUsageDescription`)
  - Location (Always) (`NSLocationAlwaysAndWhenInUseUsageDescription`)
  - Siri (`NSSiriUsageDescription`)
  - Speech Recognition (`NSSpeechRecognitionUsageDescription`)
  - Microphone (`NSMicrophoneUsageDescription`)
  - Camera (`NSCameraUsageDescription`)
  - Motion (`NSMotionUsageDescription`)
  - NFC Reader (`NFCReaderUsageDescription`)
  - Bluetooth (`NSBluetoothUsageDescription`)
  - Bluetooth (Always) (`NSBluetoothAlwaysUsageDescription`)
  - Bluetooth (peripheral) (`NSBluetoothPeripheralUsageDescription`)
  - Reminders (`NSRemindersUsageDescription`)
  - Contacts (`NSContactsUsageDescription`)
  - Calendars (`NSCalendarsUsageDescription`)
  - Photo Library Add (`NSPhotoLibraryAddUsageDescription`)
  - Photo Library (`NSPhotoLibraryUsageDescription`)
  - Apple Music (`NSAppleMusicUsageDescription`)
  - HomeKit (`NSHomeKitUsageDescription`)
  - return Video Subscriber Account Usage (`ase `)
  - Health Sharing (`NSHealthShareUsageDescription`)
  - Health Update (`NSHealthUpdateUsageDescription`)
  - Apple Events (`NSAppleEventsUsageDescription`)
  - Focus Status (`NSFocusStatusUsageDescription`)
  - Local Network (`NSLocalNetworkUsageDescription`)
  - Face ID (`NSFaceIDUsageDescription`)
  - Location (`NSLocationUsageDescription`)

The following device metadata will be displayed
for each connected device:

  - `DeviceName`
  - `DeviceClass`
  - `ProductName`
  - `ProductType`
  - `ProductVersion`
  - `ModelNumber`
  - `PasswordProtected`
  - `BatteryCurrentCapacity`
  - `BatteryIsCharging`
  - `CPUArchitecture`
  - `ActiveWirelessTechnology`
  - `AirplaneMode`
  - `BasebandCertId`
  - `BasebandChipId`
  - `BasebandPostponementStatus`
  - `BasebandStatus`
  - `BluetoothAddress`
  - `BoardId`
  - `BootNonce`
  - `BuildVersion`
  - `CertificateProductionStatus`
  - `CertificateSecurityMode`
  - `ChipID`
  - `CompassCalibrationDictionary`
  - `DeviceColor`
  - `DeviceEnclosureColor`
  - `DeviceSupportsFaceTime`
  - `DeviceVariant`
  - `DeviceVariantGuess`
  - `EffectiveProductionStatus`
  - `EffectiveProductionStatusAp`
  - `EffectiveProductionStatusSEP`
  - `EffectiveSecurityModeAp`
  - `EffectiveSecurityModeSEP`
  - `FirmwarePreflightInfo`
  - `FirmwareVersion`
  - `HardwarePlatform`
  - `HasSEP`
  - `Image4Supported`
  - `MixAndMatchPrevention`
  - `MLBSerialNumber`
  - `MobileSubscriberCountryCode`
  - `MobileSubscriberNetworkCode`
  - `PartitionType`
  - `RegionCode`
  - `RegionInfo`
  - `SerialNumber`
  - `SIMTrayStatus`
  - `SoftwareBehavior`
  - `SoftwareBundleVersion`
  - `SupportedDeviceFamilies`
  - `UniqueChipID`
  - `UniqueDeviceID`
  - `WifiVendor`



