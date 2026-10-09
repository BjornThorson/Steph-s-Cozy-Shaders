# Test 6 — Corrective visual pass
Feedback-driven revision of Test 5:
- Broader, dimmer aurora to leave more stars visible.
- Removed the disliked flat lower-cloud shapes; retained upper wisps.
- Lower outdoor daytime exposure while keeping cave/night treatment.
- Bluer water, much lower minimum opacity, livelier waves and stronger glints.
- Puddle visibility no longer depends on camera-level skylight; still
  requires real rainy-ground validation.

Not yet implemented: actual depth-aware shallow-water transparency and
refraction, genuine world-space torchlight flicker, volumetric lower clouds,
directional sunlight shadows and rays, glowing ores. A physically convincing
puddle system still requires material/geometry-aware validation.

All offline GLSL compile and link checks passed. Actual appearance and
performance require in-game testing. Keep previous ZIPs as fallbacks.
