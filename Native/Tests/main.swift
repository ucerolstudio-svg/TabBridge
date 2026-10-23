import Foundation
func check(_ condition: @autoclosure () -> Bool, _ name: String) { precondition(condition(), name); print("PASS \(name)") }
let input = """
List of devices attached
samsungA device usb:123 model:SM_X800 transport_id:1
samsungB unauthorized usb:456 transport_id:2
10.0.0.2:5555 device model:remote
emulator-5554 device model:emulator
* daemon started successfully
"""
let parsed = USBInventory.parse(input)
check(parsed.count == 2, "only-physical-usb-devices")
check(parsed[0].name == "SM X800", "model-display-name")
check(parsed[0].authorized, "authorized-state")
check(!parsed[1].authorized, "unauthorized-cannot-connect")
check(USBInventory.choose(parsed, preferred: "")==nil, "never-pick-arbitrary-device")
check(USBInventory.choose(parsed, preferred: "samsungB")?.id == "samsungB", "explicit-selection")
check(USBInventory.choose(Array(parsed.prefix(1)), preferred: "")?.id == "samsungA", "single-device-selection")
check(USBInventory.parse("").isEmpty, "empty-inventory")
print("8 USB target checks passed")
