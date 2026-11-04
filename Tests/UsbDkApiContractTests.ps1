param(
    [Parameter(Mandatory = $true)]
    [string] $LibraryPath
)

$ErrorActionPreference = "Stop"

$resolvedLibraryPath = (Resolve-Path $LibraryPath).Path
$interop = @"
using System;
using System.Runtime.InteropServices;

public static class UsbDkApiContract
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetDllDirectory(string path);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_GetDevicesList", SetLastError = true)]
    public static extern bool GetDevicesList(IntPtr devicesArray, IntPtr numberDevices);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_GetConfigurationDescriptor", SetLastError = true)]
    public static extern bool GetConfigurationDescriptor(IntPtr request, IntPtr descriptor, IntPtr length);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_StartRedirect", SetLastError = true)]
    public static extern IntPtr StartRedirect(IntPtr deviceId);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_ReadPipe", SetLastError = true)]
    public static extern int ReadPipe(IntPtr deviceHandle, IntPtr request, IntPtr overlapped);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_WritePipe", SetLastError = true)]
    public static extern int WritePipe(IntPtr deviceHandle, IntPtr request, IntPtr overlapped);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_ResetDevice", SetLastError = true)]
    public static extern bool ResetDevice(IntPtr deviceHandle);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_AddExtendedHideRule", SetLastError = true)]
    public static extern bool AddExtendedHideRule(IntPtr hiderHandle, IntPtr rule, uint type);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_AddExtendedPersistentHideRule", SetLastError = true)]
    public static extern int AddExtendedPersistentHideRule(IntPtr rule, uint type);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_DeleteExtendedPersistentHideRule", SetLastError = true)]
    public static extern int DeleteExtendedPersistentHideRule(IntPtr rule, uint type);

    [DllImport("UsbDkHelper.dll", EntryPoint = "UsbDk_DeleteAllPersistentRules", SetLastError = true)]
    public static extern int DeleteAllPersistentRules(IntPtr deleted, IntPtr notDeleted);
}
"@

Add-Type -TypeDefinition $interop
$libraryDirectory = Split-Path -Parent $resolvedLibraryPath
if (-not [UsbDkApiContract]::SetDllDirectory($libraryDirectory)) {
    throw "Failed to set DLL search path to '$libraryDirectory'."
}

function Assert-ApiResult([bool] $condition, [string] $message) {
    if (-not $condition) {
        throw $message
    }
}

function Assert-LastError([int] $expected, [string] $operation) {
    $actual = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Assert-ApiResult ($actual -eq $expected) "${operation}: expected last error $expected, got $actual."
}

$invalidParameter = 87
$invalidHandle = 6
$devicesPointer = [IntPtr]::Zero
$numberDevicesPointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(4)
$descriptorPointer = [Runtime.InteropServices.Marshal]::AllocHGlobal([IntPtr]::Size)
$lengthPointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(4)
$deletedPointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(4)

try {
    [Runtime.InteropServices.Marshal]::WriteInt32($numberDevicesPointer, 123)
    Assert-ApiResult (-not [UsbDkApiContract]::GetDevicesList([IntPtr]::Zero, $numberDevicesPointer)) "GetDevicesList accepted a null output pointer."
    Assert-LastError $invalidParameter "GetDevicesList"
    Assert-ApiResult ([Runtime.InteropServices.Marshal]::ReadInt32($numberDevicesPointer) -eq 0) "GetDevicesList did not clear the device count."

    [Runtime.InteropServices.Marshal]::WriteIntPtr($descriptorPointer, [IntPtr](123))
    [Runtime.InteropServices.Marshal]::WriteInt32($lengthPointer, 123)
    Assert-ApiResult (-not [UsbDkApiContract]::GetConfigurationDescriptor([IntPtr]::Zero, $descriptorPointer, $lengthPointer)) "GetConfigurationDescriptor accepted a null request."
    Assert-LastError $invalidParameter "GetConfigurationDescriptor"
    Assert-ApiResult ([Runtime.InteropServices.Marshal]::ReadIntPtr($descriptorPointer) -eq [IntPtr]::Zero) "GetConfigurationDescriptor did not clear the descriptor output."
    Assert-ApiResult ([Runtime.InteropServices.Marshal]::ReadInt32($lengthPointer) -eq 0) "GetConfigurationDescriptor did not clear the length output."

    Assert-ApiResult ([UsbDkApiContract]::StartRedirect([IntPtr]::Zero) -eq [IntPtr](-1)) "StartRedirect did not reject a null device ID."
    Assert-LastError $invalidParameter "StartRedirect"

    Assert-ApiResult ([UsbDkApiContract]::ReadPipe([IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) "ReadPipe accepted a null request."
    Assert-LastError $invalidParameter "ReadPipe"
    Assert-ApiResult ([UsbDkApiContract]::WritePipe([IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) "WritePipe accepted a null request."
    Assert-LastError $invalidParameter "WritePipe"

    Assert-ApiResult (-not [UsbDkApiContract]::ResetDevice([IntPtr]::Zero)) "ResetDevice accepted a null handle."
    Assert-LastError $invalidHandle "ResetDevice"

    Assert-ApiResult (-not [UsbDkApiContract]::AddExtendedHideRule([IntPtr]::Zero, [IntPtr]::Zero, 0)) "AddExtendedHideRule accepted a null rule."
    Assert-LastError $invalidParameter "AddExtendedHideRule"
    Assert-ApiResult ([UsbDkApiContract]::AddExtendedPersistentHideRule([IntPtr]::Zero, 0) -eq 0) "AddExtendedPersistentHideRule accepted a null rule."
    Assert-LastError $invalidParameter "AddExtendedPersistentHideRule"
    Assert-ApiResult ([UsbDkApiContract]::DeleteExtendedPersistentHideRule([IntPtr]::Zero, 0) -eq 0) "DeleteExtendedPersistentHideRule accepted a null rule."
    Assert-LastError $invalidParameter "DeleteExtendedPersistentHideRule"

    [Runtime.InteropServices.Marshal]::WriteInt32($deletedPointer, 123)
    Assert-ApiResult ([UsbDkApiContract]::DeleteAllPersistentRules($deletedPointer, [IntPtr]::Zero) -eq 0) "DeleteAllPersistentRules accepted a null output pointer."
    Assert-LastError $invalidParameter "DeleteAllPersistentRules"
    Assert-ApiResult ([Runtime.InteropServices.Marshal]::ReadInt32($deletedPointer) -eq 0) "DeleteAllPersistentRules did not clear its output."
}
finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($numberDevicesPointer)
    [Runtime.InteropServices.Marshal]::FreeHGlobal($descriptorPointer)
    [Runtime.InteropServices.Marshal]::FreeHGlobal($lengthPointer)
    [Runtime.InteropServices.Marshal]::FreeHGlobal($deletedPointer)
}

Write-Output "UsbDk API contract tests passed."
