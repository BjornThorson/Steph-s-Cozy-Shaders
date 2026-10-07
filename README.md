# Steph's Cozy Shader

A cozy Minecraft Java Edition shader pack developed for **Iris Shaders**.

## Current milestone

**v0.1 foundation**

The first milestone is intentionally small: prove that Iris can detect, compile, and run the pack before we start building the actual cozy rendering systems.

The initial shader applies a deliberately visible warm colour grade. It is a diagnostic effect, not the finished look.

## Test it with CurseForge

1. Use a Minecraft Java profile with **Iris Shaders** installed.
2. Download this repository as a ZIP, or clone it locally.
3. Put the pack in that Minecraft instance's `shaderpacks` folder.
4. Make sure the pack root contains the `shaders/` directory.
5. Launch Minecraft.
6. Open the Iris shader-pack menu and select **Steph's Cozy Shader**.
7. Load a world and check that the scene has a noticeable warm tint.

If the pack appears in Iris but fails to compile, save the shader error/log before changing anything. That gives us a precise failure to fix.

## Project structure

```text
Steph-s-Cozy-Shaders/
├── README.md
├── .gitignore
└── shaders/
    ├── shaders.properties
    ├── final.vsh
    └── final.fsh
```

## Direction

The intended look is warm, soft, comfortable, and recognisably Minecraft rather than a total visual replacement.

Once the foundation is confirmed working in-game, features can be added one system at a time: lighting and colour, skies and atmosphere, foliage movement, water, shadows, interior warmth, and user-facing quality/style settings.

## Development rule

Keep a known-good version at every milestone. Add one rendering system, test it in Minecraft, then commit the working state.

## Licence

No licence has been selected yet. Until one is added, normal copyright rules apply.
