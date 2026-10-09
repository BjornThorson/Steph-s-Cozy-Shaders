# Oculus compatibility baseline

**Target:** Minecraft Java 1.20.1, Forge, Oculus 1.8.0. The shader pack is
still an untested prototype; this commit is a static compatibility baseline,
not proof of in-game operation.

## Changes in this pass

- Match the Iris/Oculus `mc_Entity` vertex attribute's two-component declaration
  in the water/lava vertex program. The first component carries the mapped block
  material ID; the second is the fluid flag.
- Preserve the existing GLSL 330 compatibility profile, explicit fluid IDs,
  and the original artistic effects.
- Add `python3 tools/check_shader_pack.py` to check packaging and common
  integration mistakes without claiming to compile or run Minecraft.

## First-device acceptance test (Steph's modpack)

1. Back up or duplicate the Forge 1.20.1 profile. Record the Oculus version,
   graphics settings, modpack version, and display resolution.
2. Open the shaderpack ZIP in Oculus. Check for compile/link errors and
   missing shader programs before judging the visuals.
3. Test ordinary blocks, glass, surface water, lava, rain and snow,
   underwater, caves, and night sky/moon.
4. Compare shader off/on while standing still and moving in the same area.
   Record FPS *and* visible stutters, RAM usage, resolution, and render distance.
5. If a program fails, capture `latest.log` or Oculus shader error output,
   removing account names, tokens, and private paths before sharing.

## Known unverified areas

- Material IDs and the fluid flag must be confirmed in the actual Oculus
  rendering passes, including modded fluids and translucent materials.
- Uniform availability/semantics (especially moon position, skylight,
  depth and weather smoothing) need runtime validation.
- The weather program changes both rain and snow opacity.
- No OpenGL context, Oculus runtime, modpack, or real device was used in
  this static pass. No performance claim can be made.
