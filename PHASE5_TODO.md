# Phase 5 — Splash Screen & App Branding TODO

## Steps
- [x] 1. Analyze existing splash_page.dart and design system
- [x] 2. Plan approved
- [x] 3. Edit `mobile/lib/app/router/splash_page.dart` with:
  - [x] Import AppAnimation, AppGradients, AppShadows, AppRadius
  - [x] Use AppGradients.brand for background
  - [x] Use AppAnimation constants for durations/curves
  - [x] Wrap with LayoutBuilder for responsive layout
  - [x] Enhance _LogoGlow with AppShadows.glow + Semantics
  - [x] Add Semantics labels to text elements
  - [x] Refine _AnimatedDots with AppAnimation
- [x] 4. Run `dart analyze` — 0 errors, 0 warnings (only info-level hints remain)
- [x] 5. Run `flutter test` — all pre-existing failures, no new failures introduced
- [ ] 6. Run `flutter run -d chrome` — verify
- [ ] 7. Git commit
