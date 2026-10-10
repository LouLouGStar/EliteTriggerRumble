# Elite Trigger Rumble (iOS)

Experimental open-source app to test an Xbox Elite Series 2 controller's haptics from iPhone.

## Important limitations
- This app is experimental. It can only use controller haptic locations that iOS exposes through Apple's GameController framework.
- The app checks whether the connected controller reports `leftTrigger` and `rightTrigger` haptic localities. If the Elite Series 2 does not expose them to iOS, an app cannot force them to work through this API.
- Keep the controller paired to the iPhone over Bluetooth while testing.
- This project has not been compiled or hardware-tested in this environment.

## Build an unsigned IPA without owning a Mac

1. Create or sign into a free GitHub account at https://github.com.
2. Create a **new public repository** named `EliteTriggerRumble` (public makes the first setup simpler).
3. On the repository page, choose **Add file → Upload files** and upload the contents of this ZIP (not the ZIP itself). Include the `.github` folder. If GitHub's web uploader hides dot-folders, upload the files through the GitHub website after enabling display of hidden files, or use the browser's desktop view.
4. Commit the files to the `main` branch.
5. Open the repository's **Actions** tab. If asked, enable GitHub Actions.
6. Select **Build unsigned iOS IPA**, then click **Run workflow → Run workflow**.
7. Wait for the run to finish. Open the completed run and download the artifact named `EliteTriggerRumble-unsigned-ipa`.
8. Extract the downloaded artifact ZIP to find `EliteTriggerRumble.ipa`.

## Install on iPhone from Windows

1. Download Sideloadly from its official site: https://sideloadly.io/
2. Install Apple's Windows iTunes/iCloud components if Sideloadly asks for them.
3. Connect the iPhone to the Windows PC by USB and tap **Trust** on the iPhone.
4. Open Sideloadly, select your iPhone, drag `EliteTriggerRumble.ipa` into the IPA box, and enter your Apple ID when prompted for signing. Use only the official Sideloadly site.
5. Start installation. On iPhone, if prompted, go to **Settings → General → VPN & Device Management** and trust your Apple ID developer profile.
6. With a free Apple ID, the app typically needs to be refreshed/re-signed about every 7 days using Sideloadly.

## Use
1. Pair the Xbox Elite Series 2 to the iPhone: **Settings → Bluetooth**.
2. Open the app and press **Refresh / Detect controller**.
3. Check the status line. It lists the haptic locations iOS reports.
4. Move one slider at a time and tap **Start** for that motor. Tap **Stop all** to stop.
5. If either trigger is shown as unsupported, this is a controller/iOS capability limitation rather than a slider problem.

## Privacy
The app has no network code and does not collect data. The GitHub Actions build uses GitHub's cloud macOS runner.
