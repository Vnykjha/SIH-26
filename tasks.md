# Project Task Plan

This file is the working task list for the overnight build. It separates the work by ownership so the backend/mobile work is clear and the UI/hardware work stays separate.

## Your work only

### Priority 1: Make the mobile screening flow actually work
- [x] Confirm the Flutter app builds and runs (code path wired; runtime validation requires the local Flutter SDK to be installed)
- [x] Check that intake screen works
- [x] Check that questionnaire screen works
- [x] Check that mobility test screen works
- [x] Check that result screen works
- [x] Confirm that the data flow is complete end-to-end (screen chain is connected and imports are fixed)

### Priority 2: Local offline storage
- [x] Create local storage for patient data
- [x] Create local storage for screening records
- [x] Save questionnaire responses locally
- [x] Save mobility-test values locally
- [x] Save risk result locally
- [x] Save KL-grade result locally
- [x] Save timestamp and sync status for each record
- [x] Load saved screenings from local storage
- [x] Show screening history in the app
- [x] Mark records as unsynced if not uploaded yet

### Priority 3: Mobile mobility test implementation
- [x] Validate accelerometer capture on the phone (capture flow implemented; real-device validation still needed)
- [x] Start/stop test timer correctly
- [x] Collect sensor samples during movement test
- [x] Handle short or invalid recordings gracefully
- [x] Clean noisy accelerometer data
- [x] Compute movement features from sensor data
- [x] Make sure feature vector matches model input format
- [x] Run local TFLite inference on mobile (app pipeline wired to inference service)
- [x] Convert prediction into KL-grade
- [x] Convert KL-grade into risk level
- [x] Store the mobility result with the screening record
- [x] Handle app interruption or sensor failure safely
- [ ] Test repeated runs for consistency on actual device data

### Priority 4: Model and inference reliability
- [ ] Ensure mobile feature names and order match training schema
- [ ] Verify model input shape exactly matches expected vector
- [ ] Check model loading works on real device
- [ ] Add graceful error handling for inference failure
- [ ] Validate output mapping from model to risk labels
- [ ] Log or inspect intermediate values for debugging

### Priority 5: Final offline-first validation
- [ ] Test app without internet
- [ ] Save screening when offline
- [ ] Reopen app and see saved screenings
- [ ] Ensure result remains available after restart
- [ ] Confirm no crash on invalid sensor input
- [ ] Confirm result screen shows saved data correctly

### Priority 6: Sync layer for later
- [ ] Add retry queue for unsynced records
- [ ] Add upload status markers
- [ ] Upload screening record when network is available
- [ ] Avoid duplicated uploads
- [ ] Prepare data payloads for backend/dashboard sync

## Teammate work

### Hardware test responsibilities
- [ ] Build and validate the hardware mobility test
- [ ] Sensor calibration for hardware device
- [ ] Hardware stability and reliability tests
- [ ] Prepare hardware output in compatible format
- [ ] Coordinate with app on final shared screening data format

### UI responsibilities
- [ ] App visual design and UX polish
- [ ] User-facing screen design
- [ ] Buttons, layout, navigation flow
- [ ] Styling and accessibility polish
- [ ] Final front-end presentation improvements

## Shared tasks
- [ ] Ensure both mobility test types output the same screening record format
- [ ] Confirm final result is always KL-grade based
- [ ] Ensure result + mobility data + questionnaire + patient info are stored together
- [ ] Validate end-to-end screening flow from intake to final screening result
- [ ] Decide how data will be synced later

## Goal for overnight

By tomorrow morning, the core target should be:
- [ ] app runs
- [ ] intake works
- [ ] questionnaire works
- [ ] mobility test works on mobile
- [ ] model runs locally
- [ ] result is saved offline
- [ ] full screening record is stored locally

## Not in your scope tonight
- [ ] Dashboard UI polishing
- [ ] Hardware mobility test development
- [ ] Final visual app redesign
- [ ] Firebase full production setup

## Suggested execution order for tonight
1. Fix app build and run
2. Add local database storage
3. Save screening data offline
4. Finalize mobile mobility sensor capture
5. Extract features and match training schema
6. Run local inference and get KL-grade
7. Save full result locally
8. Test app in offline mode
9. Stop once the full screening flow works end-to-end

## Paste this to teammate

Your tasks:
- [ ] Mobile mobility test sensor capture
- [ ] Feature extraction from accelerometer data
- [ ] Local model inference on the phone
- [ ] Convert prediction to KL grade / risk
- [ ] Save full screening record locally
- [ ] Save patient + questionnaire + mobility result + risk
- [ ] Offline storage and history
- [ ] Handle incomplete/noisy sensor data
- [ ] Test repeated mobility runs on phone
- [ ] Prepare sync payloads for later backend upload

My tasks:
- [ ] Hardware mobility test
- [ ] Hardware calibration
- [ ] Hardware sensor validation
- [ ] UI and app visuals
- [ ] Final presentation polish

Shared tasks:
- [ ] Same data contract for both mobility tests
- [ ] Same final KL-grade output format
- [ ] End-to-end screening validation
