# hardware_firmware — IMU puck (Tier 3 / roadmap)

ESP32-class firmware for the optional clip-on IMU puck used in
"Enhanced Screening" mode. Not required for Tier 1/2 — the phone's own
accelerometer covers Standard Screening.

## Planned scope

- Read IMU (accel + gyro), optional flex sensor
- Filter/package motion data
- Stream over BLE to mobile_app during the ~30s test
- LED status indicator (power / BLE connected / recording)

## Not yet implemented

- Pin mapping / hardware BOM
- Firmware (Arduino/ESP-IDF) for sensor read + BLE GATT service
- BLE protocol doc (must match what mobile_app expects to receive)
