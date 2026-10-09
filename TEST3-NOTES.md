# Test 3 — Storybook atmosphere experiment

Built from Steph's positive Test 2 feedback.

Changes:
- Preserve approved moon, aurora and nighttime brightness.
- Increase saturation and warm grading for a more storybook palette.
- Add inexpensive sky-only painterly cloud patches in daytime; suppress at night
  to protect the approved aurora.
- Make wet-ground puddle patches easier to see, with stronger sky-coloured sheen.
- Apply gentle water displacement in world-up instead of camera-up.

**Not yet included:** actual water refraction. That requires carefully
sampling the background scene behind translucent water using a compatible
render target/depth arrangement; it is not the same as increasing ripple
movement. This must be implemented and tested separately to avoid regressions.

**Unverified:** Cloud appearance, puddle visibility, camera-angle-dependent
water geometry, and integrated-GPU performance. In particular, the current
puddle method uses camera-level skylight exposure and may need a material-aware
pass if the effect still does not show on exposed ground.

Test beside v0.1.0-test2, not in place of it. Check aurora, moon, caves,
clouds, water, rainy ground, and frame pacing.
