# Performance audit — first pass

**Target:** Steph's original ROG Ally, conservatively assumed Ryzen Z1
(non-Extreme), running her actual Forge 1.20.1 modpack. This is a
source-level audit, not a GPU benchmark.

## Optimizations applied

- Aurora now exits before `atan`, `asin`, two interpolated noise
  evaluations, and trigonometric curtain shaping on pixels outside the
  visible nighttime sky. The existing night/sky fade still controls the
  effect on eligible pixels.
- Wetness exits before world-position reconstruction and screen-space
  derivatives when the smoothed wetness value is zero.
- Dry/unexposed surfaces skip procedural puddle noise and Fresnel shading.

These checks can introduce divergent branches on some GPUs; the net
performance impact must be measured in-game, especially on integrated
graphics. No FPS improvement is claimed.

## Remaining hotspots and risks

1. `final.fsh` is full-screen. Its wetness path reconstructs world
   position, uses derivatives, and evaluates two value-noise layers.
2. `final.fsh` aurora uses angular coordinates and two value-noise
   evaluations on eligible sky pixels. Consider a reduced-resolution
   atmosphere pass only if measurements justify extra buffers.
3. `gbuffers_water.fsh` lava uses several smooth-noise evaluations
   per visible lava fragment. This is material-local, not full-screen.
4. The shader currently has no additional full-resolution temporal
   buffers; avoid introducing them without an explicit shared-memory
   budget for the baseline ROG Ally.
5. GPU frame time, memory bandwidth, thermals, shader on/off comparison,
   and modpack-induced stutter cannot be inferred from source code.

## Acceptance criteria for future changes

- Keep the Cozy Lite aesthetic intact.
- Record repeatable frame times in Steph's real modpack, including
  camera movement and typical loaded modded areas.
- Check stability and memory consumption alongside average FPS.
- Revert an optimization if it produces visual artifacts or worsens
  frame pacing on either ROG Ally.
