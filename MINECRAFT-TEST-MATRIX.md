# Minecraft compatibility matrix for Cozy Shaders

A green GitHub Actions preflight validates shader GLSL compilation/linking and the shaderpack ZIP layout. It **does not prove any Minecraft version, launcher or loader is supported**.

| Minecraft Java | Loader | Shader engine | Status |
|---|---|---|---|
| 1.20.1 | Forge | Oculus 1.8.0 | Primary intended target, awaiting real gameplay |
| 1.20.1 | Fabric | Iris + matched Sodium | Candidate, untested |
| 1.21.1 | Fabric | Iris + matched Sodium | Candidate, untested |
| 1.21.1 | NeoForge | Iris + matched Sodium | Candidate, untested |

For each combination, test fresh installations through **Prism Launcher** and the **CurseForge app** when those versions are available. Record the launcher application's version separately from Minecraft, mod-loader and shader-engine versions.

A runtime test passes only when a licensed client launches, opens a disposable world, loads the shaderpack with no shader errors, and visuals are inspected across terrain, glass, caves, rain, snow, water, lava and the night sky. Capture FPS and stutter both with and without the shader, at matching settings. Record OS, GPU/driver, launcher, exact versions and a **redacted** `latest.log` if anything breaks.

Forge 1.20.1 requires Oculus for this test; Iris supports Fabric 1.20.1 and Fabric/NeoForge 1.21.1. Launcher apps are installation/profile managers, not substitutes for shader engines. No Minecraft login secrets should enter GitHub Actions. For Steph's modpack, final FPS/performance acceptance must happen on her actual hardware.
