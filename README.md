# SonicForm 🎵⚡

SonicForm is a clean dark/electric lime audio player supporting **Google Chrome** and **Android**.

---

## 🌐 Running in Google Chrome

To open and run SonicForm in Google Chrome:

```powershell
cd "c:\Users\Sahith Raj\Desktop\Flutter_Apps\sonic_form"
flutter run -d chrome
```

*(Or open in VS Code, choose **SonicForm (Chrome)** in the Run & Debug tab, and press <kbd>F5</kbd>).*

### Importing & Playing Local Audio in Chrome:
1. When Chrome opens, click the **Folder icon** or **Select Audio**.
2. Select any local `.mp3` or `.wav` file from your computer.
3. The file is loaded via native browser Blob URLs into the HTML5 audio engine.
4. The vinyl visualizer will spin and audio will play immediately!

---

## 📱 Running on Android

To run on an Android device or emulator:

```powershell
flutter emulators --launch SonicForm_API_35
flutter run -d SonicForm_API_35
```
*(Android provides native hardware OpenSL ES equalizer processing with Flat, Warm, Vocal, Bright, and Deep presets).*
