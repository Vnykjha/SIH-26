# TO RUN: CREPISENSE Setup Guide

This is the easiest setup guide for the project. Follow the steps in order. Do not skip steps.

This project has 3 main parts:
1. Python model training and TFLite export
2. Flutter mobile app
3. optional web dashboard

------------------------------------------------------------
HOW TO SEND THE PROJECT TO SOMEONE
------------------------------------------------------------

If you cannot push to GitHub, the easiest way is:

1. Open the project folder in File Explorer.
2. Right click the folder: `SIH-OA-SCREENING`
3. Select `Send to > Compressed (zipped) folder`
4. Share the `.zip` file through:
   - WhatsApp
   - email
   - Google Drive
   - any file transfer app

The other person can then unzip it and run the project from the extracted folder.

Important:
- Do not send only a few files.
- Send the full folder, including `mobile_app`, `ml_model`, `web_dashboard`, `docs`, and `README.md`.

------------------------------------------------------------
REQUIRED SOFTWARE
------------------------------------------------------------

Install these first:

1. Python 3.11
   - Use Python 3.11, not 3.12 or 3.13
   - This project is tested with Python 3.11

2. Flutter SDK
   - Install Flutter stable version
   - Make sure `flutter` is in PATH

3. Node.js LTS
   - Needed for the web dashboard

4. VS Code (recommended)
   - Install Flutter and Python extensions if needed

5. Optional: Git
   - Only needed if you want version control later

------------------------------------------------------------
CHECK YOUR INSTALLATIONS
------------------------------------------------------------

Open PowerShell or terminal and run:

```powershell
python --version
flutter --version
node --version
```

Expected:
- Python version should be 3.11.x
- Flutter version should be installed and working
- Node version should be a recent LTS version

------------------------------------------------------------
STEP 1: OPEN THE PROJECT FOLDER
------------------------------------------------------------

Open the project folder in VS Code or terminal:

```powershell
cd "D:\sih-oa-screening"
```

If your folder is somewhere else, replace the path accordingly.

------------------------------------------------------------
STEP 2: CREATE PYTHON VIRTUAL ENVIRONMENT
------------------------------------------------------------

Inside the project folder, create a virtual environment:

```powershell
python -m venv .venv
```

Activate it:

```powershell
.\.venv\Scripts\Activate.ps1
```

If PowerShell blocks activation, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Check that it activated:

```powershell
python --version
```

It should show Python 3.11.

------------------------------------------------------------
STEP 3: INSTALL PYTHON DEPENDENCIES
------------------------------------------------------------

From the project root:

```powershell
pip install -r .\ml_model\requirements.txt
```

This installs:
- scikit-learn
- pandas
- numpy
- tensorflow

If TensorFlow install fails, it is usually because the wrong Python version is active.

------------------------------------------------------------
STEP 4: TRAIN THE ML MODEL
------------------------------------------------------------

Go to the model folder:

```powershell
cd .\ml_model
```

Then run:

```powershell
python .\train.py
```

This should create the trained model files in the data folder.

After training, export the TensorFlow Lite model:

```powershell
python .\export_tflite.py
```

This should generate the `.tflite` file that the Flutter app uses.

------------------------------------------------------------
STEP 5: CHECK THE ML ARTIFACTS
------------------------------------------------------------

Look inside:
- `ml_model/data/oa_risk_dataset.csv`
- `ml_model/data/oa_risk_model.keras`
- `mobile_app/assets/model.tflite`

If the model file is missing, re-run the training and export steps.

------------------------------------------------------------
STEP 6: INSTALL FLUTTER DEPENDENCIES
------------------------------------------------------------

Open a new terminal and go to the mobile app folder:

```powershell
cd "D:\sih-oa-screening\mobile_app"
flutter pub get
```

This installs the Flutter packages from `pubspec.yaml`.

------------------------------------------------------------
STEP 7: RUN THE MOBILE APP
------------------------------------------------------------

After dependencies are installed:

```powershell
flutter run
```

If you want to run it in a specific emulator/device:

```powershell
flutter devices
flutter run -d <device-id>
```

If the app does not run, check:
- Flutter is installed and in PATH
- the emulator is running
- Android SDK is installed
- `flutter doctor` shows no major errors

Run:

```powershell
flutter doctor
```

Fix any missing Android setup issues before proceeding.

------------------------------------------------------------
STEP 8: OPTIONAL WEB DASHBOARD
------------------------------------------------------------

Open the dashboard folder:

```powershell
cd "D:\sih-oa-screening\web_dashboard"
npm install
npm start
```

This runs the dashboard UI locally.

------------------------------------------------------------
STEP 9: OFFLINE-FIRST MODE
------------------------------------------------------------

This project is meant to work offline first.

The app should work without Firebase at first. That means:
- local screening storage
- local risk result storage
- local records saved on the phone
- sync later when internet is available

Do not start with Firebase as the main flow.

------------------------------------------------------------
VERY IMPORTANT NOTES
------------------------------------------------------------

1. Use Python 3.11
   - Do not use Python 3.14 for this project

2. Do not skip model creation
   - The app expects the TFLite file to exist

3. The model is synthetic at first
   - This is a prototype model
   - It is useful for workflow testing, not final clinical deployment

4. The project is split by responsibility
   - Mobile app: screening + mobility test + local inference
   - Hardware team: hardware mobility test
   - Dashboard: reporting later

------------------------------------------------------------
QUICK COPY-PASTE COMMAND SEQUENCE
------------------------------------------------------------

If you want the simplest version, run this in order:

```powershell
cd "D:\sih-oa-screening"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r .\ml_model\requirements.txt
cd .\ml_model
python .\train.py
python .\export_tflite.py
cd ..\mobile_app
flutter pub get
flutter run
```

For the dashboard:

```powershell
cd "D:\sih-oa-screening\web_dashboard"
npm install
npm start
```

------------------------------------------------------------
IF SOMETHING BREAKS
------------------------------------------------------------

Common problems:

- Python version is wrong
  - Use Python 3.11

- TensorFlow installation fails
  - Re-activate the right venv
  - Verify `python --version`

- Flutter app does not run
  - Run `flutter doctor`
  - Check Android SDK / emulator

- Missing model file
  - Re-run `python train.py` and `python export_tflite.py`

- Dashboard does not start
  - Run `npm install` first

------------------------------------------------------------
FINAL NOTE
------------------------------------------------------------

This project is meant to be built in a simple order:

1. install Python + Flutter + Node
2. train the model
3. export TFLite model
4. run the mobile app
5. then add offline storage and sync
6. then add dashboard or hardware integration later

That is the correct order for this project.
