# ComicSmithDemoApp (SwiftUI Demo)

**Purpose:** a tiny SwiftUI app to exercise the ComicSmithCore package with three panes — Chat, Content (Issue/Page/Panel), and Script.

> This is a Swift Package with an executable target. Open it in Xcode and run the target.  
> To get a real `.app` bundle, create a macOS App project and drop these sources in, then add `ComicSmithCore` as a package dependency.

## Setup

1. Unzip **ComicSmithCore.zip** and **ComicSmithDemoApp.zip** next to each other.
2. Open **ComicSmithDemoApp/Package.swift** in Xcode.
3. If Xcode can't resolve the local dependency path, edit `Package.swift` to point at your local ComicSmithCore location.
4. Run the **ComicSmithDemoApp** scheme.

## What works

- **Issue Mode:** Add/Delete/Reorder pages and select one.
- **Page Mode:** Add/Delete/Reorder panels and select one.
- **Panel Mode:** Edit description, add speech/thought/caption/SFX balloons.
- **Chat:** Type “new page …” to trigger a mock tool call (Add Page). Replace with your real Gemini client.
- **Script:** Shows a live script. The **Apply Edits** button parses `Panel N: ...` lines for the **current page** and updates descriptions.

## Notes

- Images & “Generating…” overlays are not implemented in the demo.
- References UI is stubbed.
- This demo is intentionally minimal—meant to prove plumbing & flow.
