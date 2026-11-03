---
name: gemini-generate
description: Generate images (Nano Banana, gemini-2.5-flash-image) or MP4 videos with animation (Veo 3.1) for Space Thunder through the Gemini API using GEMINI_API_KEY. Use whenever a new image, sprite key pose, background, icon or animated video clip is needed and it should be generated rather than drawn or taken from the user. Enforces the rule of ONE generation per request - no trial batches.
---

# Generate images and videos with Gemini (Nano Banana / Veo)

Script: `.claude/skills/gemini-generate/scripts/gemini_gen.py` (Python 3, standard library only, no install).
Key: environment variable `GEMINI_API_KEY` (set at user level in Windows; a new PowerShell window picks it up). The key alone is enough for both image and video through the Gemini API. Veo video may require billing to be enabled on the Google AI project - if the API answers with a quota or billing error, tell the user; do not retry in a loop.

## Budget rule (most important)

**Generate exactly ONE image or ONE video per request.** Do not make 4 variants, "trials", A/B sets or a series of retries to pick a best one. The script never generates more than one output and refuses to overwrite an existing file.

- Think the prompt through first (use the art brief: `art_level1.md` / `art_level2.md` and the level's art bible, `#00FF00` flat background, nose pointing right, starts and ends on the key pose).
- Run `--dry-run` first when the request is unclear, to confirm the arguments without spending anything.
- If the one result is wrong, change the prompt and make ONE more call only after saying what was wrong. Repeated failures are a reason to stop and ask the user, not to keep paying.
- Reuse what exists: for animations, pass the approved key pose as `--ref` so the ship stays identical, and do not regenerate the key pose.
- Do not generate what the repo already has or what the user already supplied. Check `resources/` first (asset-layout skill).
- A `429` answer with `limit: 0` on the free tier means image generation is not available on this key at all (billing must be enabled on the Google AI project). Stop and tell the user; do not retry.
- Video is the expensive call. Generate a video only when a clip is actually needed, one clip per animation, and say which animation it is for.

## Commands (run from the repo root)

Image (Nano Banana):
`python -I .claude/skills/gemini-generate/scripts/gemini_gen.py image --prompt "<prompt>" --out <scratch>/<name>.png [--ref <key_pose>.png]`

Video (Veo 3.1, 8 s, MP4 with animation):
`python -I .claude/skills/gemini-generate/scripts/gemini_gen.py video --prompt "<prompt>" --out <scratch>/<name>.mp4 [--ref <key_pose>.png] [--aspect 16:9]`

- `--out` goes to the scratchpad by default. Move the chosen file into the repo (e.g. `resources/levels/levelN/enemies/<x>/source/`) only when the user accepts it.
- `--model` overrides the default model ids (`gemini-2.5-flash-image`, `veo-3.1-generate-preview`) if Google renames them; check the current ids on ai.google.dev when a call says the model is not found.
- Video takes minutes; the script polls until done. Run it in the background if other work is waiting.
- After a generation, look at the result (Read the PNG, or the sprite-animation preview for video) and report what was produced, then stop. Do not start follow-up generations on your own.

## Prompt rules for this game

- Ships and enemies: flat `#00FF00` background, no shadows on the background, single object, nose pointing right, same design as the reference.
- Animated clips: one clip per animation (idle, move, attack, death), starting and ending on the key pose, no camera movement, no second object.
- Backgrounds and pickups follow the level bible; copy the relevant section of the art file into the prompt, since the user pastes these briefs into Gemini too.

## Logging

After each generation, state in the reply: model used, prompt in short, output path, and that it was a single generation. This keeps the paid calls visible to the user.
