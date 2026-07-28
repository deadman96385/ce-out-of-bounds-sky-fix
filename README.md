# CE Out-of-Bounds Sky Fix

Campaign Evolved's common sky backdrop is a finite inverted-normal mesh:
`BP_UltraSky` -> `SM_Sphere_FlipNormal_100cm`. It is visible from inside and
backface-culled from outside, producing the black void once another mod lets the
camera travel beyond the shipping play space.

This UE4SS mod moves the backdrop to the initial camera and expands it to cover
the whole usable Unreal world. It also discovers the level-specific
`SM_*_Skydome` / `SM_*_Skybox` variants under `/Game/Env/SkyBox/SkyDome/`.

## Installation

1. Copy `CEOutOfBoundsFix` into `ue4ss/Mods/`.
2. Add `CEOutOfBoundsFix : 1` to `ue4ss/Mods/mods.txt`.
3. Start the game.

The fix runs once, two seconds after each level load. It has no polling loop,
keybinds, or persistent changes, and it does not modify saves or game packages.