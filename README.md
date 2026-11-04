[![Build Status](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)

# UsbDk

UsbDk (USB Development Kit) is a open-source library for Windows meant
to provide user mode applications with direct and exclusive access to
USB devices by detaching those from Windows PNP manager and device drivers
and providing user mode with API for USB-specific operations on the device.

The library is intended to be as generic as possible, support  all types of
USB devices, bulk and isochronous transfers, composite devices etc.

Library supports all Windows OS versions starting from Windows XP/2003.

## Documentation

* See ARCHITECTURE document in the source tree root.
* See Documentation folder in the source tree root.
* See UsbDkHelper\UsbDkHelper.h UsbDkHelper\UsbDkHelperHider.h for API documentation

## Building

**Tools required:**

* Visual Studio 2015/Visual Studio 2015 Express update 3 or newer
* WDK 10
* Windows 10 SDK
* Wix Toolset V3.8 (for building MSI installer)
* WDK 7.1 (for Windows XP/2003/Vista/2008 builds)

***Compilation***

Just open UsbDk.sln from the source tree root in Visual Studio 2015 and compile
desired configuration.

`buildAll.bat` rebuilds the Win7, Win8, Win8.1, Win10, and XP configurations for
Debug and Release on Win32 and x64, then generates trace metadata and the MSI.
The XP configurations require WDK 7.1, defaulting to
`C:\WinDDK\7600.16385.1`. Set the `UsbDkLegacyWdkRoot` MSBuild property to use
another WDK 7.1 install location. `UsbDkWindowsSdkVersion` can pin the installed
Windows SDK version; by default the projects use the WDK's latest version.
AppVeyor uses the Visual Studio 2015 image and downloads the legacy
`Microsoft.DriverKit.Build.Tasks.14.0.dll` task before building.

The AppVeyor test step runs `Tests\UsbDkApiContractTests.ps1` against the x64
Win10 Debug helper DLL. These API boundary tests need no installed
UsbDk driver or attached USB device and verify invalid-parameter handling,
output initialization, and last-error reporting.

## Installing and running

Use UsbDkController.exe to install/uninstall and verify basic operation.
Run UsbDkController.exe without parameters for command line options.

## Known issues

* Installation on 64-bit versions of Windows 7 fails if security update
  [3033929](https://technet.microsoft.com/en-us/library/security/3033929)
  is not installed. Reason: UsbDk driver is signed by SHA-256 certificate. Without this update
  Windows 7 does not recognize the signature properly and fails to load the driver.
