# Map-development workflow and user preferences

## Scope
- Work only in eggsy09/Vanguard-Map-creation. Never access, modify, or integrate with the user's other game repository.
- Use the eggsy09 GitHub connection. Do not assume another connected account is appropriate.
- Complete Havenreach review first. Town order: Havenreach, Brinewatch, Cinderford, Moonvale, Duneshade, Frosthaven, Skyrest.
- Show each actual Godot town preview and wait for the user's approval before starting the next town.
- Preserve the approved direction. If an earlier approved reference is unavailable, say so; do not claim an unseen reference was matched.

## Required map behavior
- Exact 2000 x 2000 px world; original-scale ElizaWy/LPC art.
- Five accessible house doors with clear approaches; north, south, east and west entrances.
- Native Godot world collision, with open door channels and tree-trunk footprints.
- A 64 x 64 sprite-frame sample character. Keep the feet-collision default and optional full 64 x 64 body test clearly distinguished.
- Animated water: reuse original LPC waterfall and reflection frames.
- Keep the Windows play and editor launchers. Shared simple test interiors are placeholders, not finished house interiors.

## Faster continuation
1. Read this file and README.md; fetch this repository and inspect current changes. Do not rebuild the project from scratch.
2. Reuse the existing player, door behavior, collision overlay, launcher, source art, credits, and Godot scene-building tools. Fetch only additional art needed for a new approved town.
3. Inspect scenes/Havenreach.tscn and data/havenreach.json. The scene is already baked and playable; no Python setup is needed for the user.
4. Make the requested changes, then run the relevant existing Godot checks. Avoid repeating the full asset discovery, concept generation, or renderer setup unless there is a concrete need.
5. Capture the actual Godot scene with tools/capture_preview.gd. Do not label a concept or Pillow reconstruction as a Godot screenshot.
6. Upload only changed files. Prefer authenticated git push when available. With the GitHub connector, create a tree against the current base tree, using inline content for changed text files and blobs only for changed binaries. Reuse unchanged blob SHAs. Read independent file chunks in parallel; avoid one upload commit per file.
7. Verify the published tree against the tested local files and check the public download URL. Do not report GitHub delivery complete before the branch is updated.
8. Give direct GitHub download and preview links first. The user could not open chat sandbox links during this session. GitHub Code > Download ZIP is the fallback.
9. Clearly report Windows launcher testing limits when working on Linux. Do not claim testing on the user's PC.

## Reusable commands
```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/test_havenreach.gd
godot --headless --path . --script res://tools/build_map.gd
```

The build command overwrites scenes/Havenreach.tscn; run it only when intentionally regenerating from layout data.

## Validated baseline
- Godot 4.7.2 Compatibility renderer.
- Fresh extracted project imports without script errors.
- Physics checks: zero failures; all five houses and four entrances reachable with the full 64 x 64 body.
- Door panels open; enter/return selects the correct house.
- Four-frame waterfall and twenty animated river surface details.
- Windows launchers are included and inspected, but were not executed on Windows.
- Original art revision and attribution are in credits/SOURCES.json and credits/.
- Main project commit before this workflow note: 8781762e631213caf255257f358211dac437d3f4.

## Linux screenshot environment, if this same workspace remains
A reusable runner exists outside the repository at ../tools/render_godot.py, with Godot and extracted Xvfb dependencies under ../tools/.
This environment isolates process/network setup across shell calls. Start Xvfb and Godot from the same process invocation; use a TCP display and ensure xkbcomp exists in that invocation.
If those transient tools no longer exist, set up a working display once. Do not repeatedly attempt screenshots with Godot's dummy headless renderer.
