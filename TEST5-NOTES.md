# Test 5 — Mixed storybook clouds and puddle visibility

Includes everything from Test 4 plus:
- Two distinct procedural cloud layers: soft-edged square lower formations
  with warm/cool shading, and thinner wispy upper cirrus.
- Retains very faint cloud silhouettes at night while protecting the moon and aurora.
- Broader rain-wet ground exposure and slightly wider puddle coverage.

These are fixed-cost, sky-only procedural clouds, not true volumetric clouds.
They do not yet cast world shadows or receive real directional shadow-map light.
Puddles remain sky-coloured screen-space wet highlights, not physically
reflected scenery.

Still outstanding: actual screen-space water refraction with safe background
sampling, block/material-aware glowing ores, sunlight shadow maps and sun rays.
Those need separate Oculus-compatible rendering passes, and cannot honestly
be represented as complete in this release.

Offline GLSL compile/link tests pass. Actual in-game appearance, compatibility
and Ally frame pacing remain unverified. Keep Test 2/4 as fallbacks.
