# Shared visual style

Participant-facing copy stays unchanged. Layout and typography use `lib/shell/app_design.dart`:

- Supporting text: 18 logical pixels.
- Instructions, form entries and main controls: 20.
- Headings: 24.
- Key numeric results: 32.

The two 56-pixel hourglass glyphs are illustrations, not an additional text size. Prefer 1.5 line height for instructions, 1.4 for supporting text, and 24-pixel page margins. Use white/white70 for readable text on black; muted icons may use lower contrast. Keep system text scaling enabled.

Primary actions use `primaryActionStyle`: cyan, black text, radius 14, minimum height 56, and room to grow with larger text. `AppActionArea` gives actions a common lower position and width (up to 480). `ProtocolCenteredScrollBody.action` and `ProtocolRoundShell.action` keep content scrollable above the action; round indicators or tutorial dots remain below it. Forms retain their bottom Save within the scrollable form so keyboard Next can bring it into view. Camera preview, rhythm sliders, and the trail's circular play control remain purpose-specific controls.

The trail uses 160-pixel spacing between levels. The active unlocked circle is 64 pixels across with a 72-pixel hit area and a play icon; the large adjacent Start button is gone. Viewport-based padding allows the first, middle, and last levels to center vertically. Centering runs at opening, progress changes, return from another route, and app resume. Scrolling by the user remains available; it does not continuously snap back. Locked levels never receive the start control. Keep the existing unlock rules and scoring logic.

Regression checks cover English and Hebrew at 150% text scale on a 320×640 viewport, action visibility, profile keyboard navigation, and trail centering/activation/locking. Device checks should include the user's preferred text size and VoiceOver/TalkBack.
