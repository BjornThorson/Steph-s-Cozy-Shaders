# Test 7 — Water-state and opaque-depth prototype

Adds experimental block-state mappings for source (1001), flowing (1003),
and falling (1004) water; lava remains 1002. Adds a screen-position lookup of
depthtex1 to estimate opaque surface depth behind water, with fallback when
no valid opaque depth is available. Uses that estimate for shallower water
transparency and thin broken contact foam, enhanced on flowing/falling states.

## Diagnostic mode
Edit shaders/gbuffers_water.fsh and set WATER_STATE_DEBUG to 1.
Reload the shader. Source should appear blue, flowing amber, falling magenta.
If flowing/falling water is missing or wrongly coloured, Oculus's state mapping
or mc_Entity attributes need adjustment before relying on foam classifications.
Restore WATER_STATE_DEBUG to 0 for the normal water effect.

## In-game checks
1. Single-block pond: check shallow water opacity and contact rim.
2. Stream against stone: check flowing classification and foam.
3. Water over ledge: check falling classification.
4. Waterfall landing in pool and on stone: check impact approximation.
5. Observe camera-angle artefacts, transparent surfaces, and frame pacing.

IMPORTANT: Depth-based foam identifies screen-visible opaque intersections;
it does NOT establish actual fluid collisions or neighbours. Water-to-water
impact foam is not yet reliably detectable. True background refraction is not
implemented. depthtex1 binding, state mapping, and runtime rendering remain
UNVERIFIED on Forge 1.20.1 + Oculus 1.8.0. Offline GLSL compilation/linking
passes, which is not a runtime compatibility guarantee.

Keep Test 6 as fallback.
