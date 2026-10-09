# Steph's Cozy Shader

A warm, witchy storybook shader-pack prototype for **Minecraft Java 1.20.1
on Forge + Oculus**. The priority is making Steph's existing modpack beautiful
**while keeping it playable on her original ROG Ally**.

## First-test candidate: Cozy Lite v0.1.0-test1

**Experimental / not yet tested in Minecraft.** All six GLSL stages compile
and all three stage pairs link with the offline validator. Actual Oculus
integration, visual quality, stability and frame rate remain unverified.

The current baseline includes warm grading, cave and underwater atmosphere,
animated surface water and lava, rain wetness/puddles, a witchy moon halo,
and aurora. Some effects are visual approximations; this is not a complete
lighting or physically simulated weather system.

### Installation (Forge 1.20.1 + Oculus)

1. Duplicate your existing CurseForge/modpack profile before testing.
2. Confirm the profile has **Oculus compatible with Minecraft 1.20.1**
   (targeted here: Oculus 1.8.0) and its compatible rendering dependencies.
3. Download the **Cozy Lite v0.1.0-test1 ZIP** from GitHub Releases.
   Do **not** extract it.
4. In Minecraft's shader menu, open the shaderpacks folder and place the ZIP
   there. The ZIP's top-level folder is `shaders/`.
5. Select the shader pack and use a disposable Creative test world first.
6. For the conservative first test, start at **1280×720**, **6–8 chunk render
   distance**, and the device's normal power profile. These are Minecraft
   settings, not a built-in shader quality selector.
7. Inspect ordinary terrain, caves, water, lava, rain, snow, night sky and
   glass. Record FPS and stutters both with and without the shader.

If it fails to load, preserve the Oculus shader error and Minecraft
`latest.log`. Redact personal paths, account names and secrets before
sharing. Don't troubleshoot by changing Steph's original modpack.

**Cozy Lite is currently the name of our conservative test baseline, not an
in-game preset menu.** We will only add quality tiers after measuring
performance on the actual hardware.

## Developer validation

Install Khronos `glslangValidator` (Debian package: `glslang-tools`), then:

```bash
bash tools/validate_glsl.sh
```

See [Oculus compatibility notes](OCULUS-COMPATIBILITY.md) and
[performance audit](PERFORMANCE-AUDIT.md).

## Licence

No licence has been selected yet. Until one is added, normal copyright
rules apply.
