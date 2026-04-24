# CosmIQ Guru

**App:** CosmIQ Guru
**Version:** 1.0.0
**Built by:** [Tateru Pro](https://github.com/ushanboe/tateruProPlus) (AppForge pipeline — Tateru Pro's predecessor)
**Last updated:** 2026-04-25

A mystical life OS for Android — combines **7 ancient divination systems** (astrology, tarot, I Ching, numerology, runes, palmistry, biorhythms) into one personal-coaching feed. Daily readings, calendar tracking, screenshot sharing. **Built end-to-end by the Tateru / AppForge pipeline from a feature brief.**

This repo exists as a public **sample app** demonstrating that Tateru can ship apps in the **content-rich lifestyle** category — apps with multiple distinct features unified by a coherent UX, not just a single workflow.

---

## Why this is a useful sample

CosmIQ Guru exercises a different part of the pipeline than the technical samples (Scientific Pro Calculator, PocketAI Pro):

- **7 distinct subsystems** ("engines") sharing a common UI shell and persistence layer — tests that the pipeline can produce coherent multi-feature apps, not just single-purpose tools
- **Calendar-driven personalisation** — daily content rotates by date with timezone-correct scheduling (`flutter_local_notifications` + `timezone`)
- **Charts + visualisation** — biorhythm and astrology aspects rendered with `fl_chart`
- **Polished motion design** — `flutter_animate` for transitions, daily-card reveal sequences
- **Share-as-image flow** — `screenshot` + `share_plus` for social distribution

The result is **45 Dart files** of real, runnable code generated autonomously.

---

## What's in the box

- **7 divination engines** — astrology (zodiac, horoscope, aspects), tarot (daily card + 3-card spread), I Ching (hexagram of the day), numerology (life path, personal year), runes (single rune draw), palmistry (interpretation guide), biorhythms (physical/emotional/intellectual cycles)
- **Daily personalised feed** — combines outputs from multiple engines for the user's birth date and current date
- **Calendar view** — `table_calendar` integration for tracking readings over time
- **Notifications** — daily reminder for the morning reading
- **Share readings** — capture any card or chart as an image and share to social
- **Local-only** — no accounts, no cloud, no telemetry; all data in `sqflite`
- **Material 3 UI** — themed for the cosmic / mystical aesthetic

## Tech stack (key packages)

`provider` (state) · `sqflite` (persistence) · `table_calendar` (calendar UI) · `fl_chart` (biorhythm/aspects) · `flutter_animate` (motion) · `flutter_local_notifications` + `timezone` (daily reminders) · `screenshot` + `share_plus` (share-as-image) · `google_fonts` (typography)

---

## Build it yourself

This project was built with [Tateru Pro](https://github.com/ushanboe/tateruProPlus) — the desktop app that turns one-paragraph briefs into installable Android APKs end-to-end, no human in the loop.

1. Install Tateru Pro (Linux beta available, macOS coming): see the [latest release](https://github.com/ushanboe/tateruProPlus/releases/latest)
2. Bring your own Anthropic API key (BYOK)
3. Open the AI Spec Chat panel
4. Describe a multi-feature lifestyle app you want
5. Review the generated brief in the wizard
6. Click Launch — walk away — install the APK on your phone

For more on how Tateru works, see [tateru.app](https://tateru.app).

---

## Standard Flutter run instructions

```bash
flutter pub get
flutter run                      # debug build
flutter build apk --release      # release APK
```

## License

MIT — feel free to fork, modify, and ship your own version. No royalties, no attribution required.
