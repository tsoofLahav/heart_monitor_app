# Forms and instruction screens

Profile entry establishes the behavior for future questionnaires:

- Keep stable field controllers and focus nodes throughout the form.
- Show a localized Next keyboard action, plus a visible accessory Next control for keyboards such as the iOS phone pad that have no action key.
- Next moves directly to the next empty field, skipping completed fields without dismissing and reopening the keyboard. If necessary, wrap to an earlier empty field.
- When no other fields need input, dismiss the keyboard and scroll to the bottom Save/Finish button. Do not automatically submit.
- Keep validation and failure messages. Normal saves and completion should not show success snackbars.
- Use the same behavior in English and Hebrew, including directional layout.

Instruction copy uses short separated paragraphs, approximately 20px text and 1.55 line height. Quality practice does not introduce counting or play counting beeps. Its last instruction page starts recording directly; the button sits above the page dots. Counting sessions introduce the two beeps and play the localized ready/count cue before recording begins. This does not change the measured interval or signal processing.

Reminder switches default off; choosing a time enables that session. Finish schedules only enabled reminders, cancels previously scheduled reminders, and saves switch choices locally. All ten schedule times remain in the backend schedule payload for compatibility. The `enabled` field is a local scheduling preference; backend scheduling must honor it if server-driven reminders are introduced in the future.

Device checks: verify keyboard Next and phone-pad accessory on iOS/Android, Hebrew layout at large text sizes, actual notification permission denial and delivery, and both spoken counting cues.

Compatibility: the existing server and SQL check constraint accept 7 minutes for assessment schedule metadata, so the payload retains 7 while the UI and notification copy display the current 10-minute estimate. Update both server validation and the SQL constraint before changing this wire value.
