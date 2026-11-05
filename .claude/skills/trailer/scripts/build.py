"""Cut the recorded Movie Maker shots into the Space Thunder trailer (1080p60, YouTube spec).
Usage: python -I build.py <dir>  - reads <dir>/shots/<shot>.avi, writes <dir>/work/* and <dir>/space_thunder_trailer.mp4
Edit `cards` and the cut list `SEG` below; times are seconds inside each recorded shot."""
import subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SP = Path(sys.argv[1])
SHOTS = SP / "shots"
WORK = SP / "work"
WORK.mkdir(exist_ok=True)
REPO = Path(__file__).resolve().parents[4]
FONT = str(REPO / "resources/vendor/kenney/space_shooter_redux/Bonus/kenvector_future.ttf")
MUSIC = str(REPO / "resources/shared/audio/music/Orbital Colossus.mp3")
MUSIC_END = 150.0  # the track's own ending fades out at ~147-150 s
OUT = SP / "space_thunder_trailer.mp4"
W, H, FPS = 1920, 1080, 60

TEXT = (191, 217, 255)
ACCENT = (255, 217, 51)
CYAN = (90, 220, 255)


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(" ".join(map(str, cmd)))
        print(r.stderr[-3000:])
        sys.exit(1)


def glow_text(lines, path, bg=None):
    """lines = [(text, size, color, y_center)] -> full frame PNG (transparent unless bg)."""
    img = Image.new("RGBA", (W, H), bg + (255,) if bg else (0, 0, 0, 0))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sharp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for text, size, color, y in lines:
        font = ImageFont.truetype(FONT, size)
        for layer, alpha in ((glow, 200), (sharp, 255)):
            d = ImageDraw.Draw(layer)
            box = d.textbbox((0, 0), text, font=font)
            x = (W - (box[2] - box[0])) / 2 - box[0]
            d.text((x, y - (box[3] + box[1]) / 2), text, font=font, fill=color + (alpha,))
    glow = glow.filter(ImageFilter.GaussianBlur(14))
    img = Image.alpha_composite(img, glow)
    img = Image.alpha_composite(img, glow)
    img = Image.alpha_composite(img, sharp)
    img.save(path)


# --- segments: ("card", png, seconds) or ("shot", name, start, end, game_volume, overlay_png or None)
cards = {
    "c_open": [("2189. THE KUIPER BELT GOES SILENT.", 40, TEXT, 470), ("THEY WERE NEVER COMING IN PEACE.", 64, ACCENT, 580)],
    "c_hold": [("ONE PILOT. ONE INTERCEPTOR.", 44, TEXT, 470), ("HOLD THE LINE.", 92, ACCENT, 580)],
    "c_l2": [("THE SWARM DID NOT RETREAT.", 44, TEXT, 470), ("IT DUG IN.", 92, ACCENT, 580)],
}
for name, lines in cards.items():
    glow_text(lines, WORK / f"{name}.png", bg=(0, 0, 0))
glow_text([("SURVIVE THE SWARM", 66, ACCENT, 560), ("LEVEL 1  FIRST CONTACT    LEVEL 2  ASTEROID SIEGE", 38, CYAN, 660)],
          WORK / "o_end.png")

SEG = [
    ("card", "c_open", 3.4),
    ("shot", "l1_open", 1.0, 5.4, 1.0, None),
    ("shot", "l1_swarm", 2.3, 8.3, 0.55, None),
    ("card", "c_hold", 2.4),
    ("shot", "l1_boss", 0.9, 4.9, 0.55, None),
    ("shot", "l1_boss", 9.0, 11.4, 0.55, None),
    ("shot", "l1_worm", 0.8, 5.0, 0.55, None),
    ("shot", "l1_worm", 10.4, 13.2, 0.55, None),
    ("card", "c_l2", 2.6),
    ("shot", "l2_open", 0.2, 4.6, 0.8, None),
    ("shot", "l2_beetle", 3.0, 8.0, 0.55, None),
    ("shot", "l2_worm", 0.8, 3.6, 0.55, None),
    ("shot", "l2_worm", 9.0, 11.2, 0.55, None),
    ("shot", "l2_nuke", 2.6, 6.6, 0.6, None),
    ("shot", "title", 0.5, 7.0, 0.0, "o_end"),
]

# "short" variant: ~27 s cut-down for shorts and feeds, same shots and music logic
if len(sys.argv) > 2 and sys.argv[2] == "short":
    OUT = SP / "space_thunder_trailer_short.mp4"
    SEG = [
        ("card", "c_open", 2.5),
        ("shot", "l1_open", 1.0, 5.4, 1.0, None),
        ("shot", "l1_boss", 0.9, 4.9, 0.55, None),
        ("card", "c_l2", 2.0),
        ("shot", "l2_beetle", 3.0, 7.0, 0.55, None),
        ("shot", "l2_nuke", 2.6, 6.6, 0.6, None),
        ("shot", "title", 0.5, 7.0, 0.0, "o_end"),
    ]

parts = []
for i, seg in enumerate(SEG):
    out = WORK / f"seg{i:02d}.mkv"
    parts.append(out)
    if seg[0] == "card":
        _, name, dur = seg
        vf = f"fade=in:st=0:d=0.35,fade=out:st={dur - 0.35}:d=0.35,format=yuv420p"
        run(["ffmpeg", "-v", "error", "-y", "-loop", "1", "-framerate", str(FPS), "-t", str(dur), "-i", str(WORK / f"{name}.png"),
             "-f", "lavfi", "-t", str(dur), "-i", "anullsrc=r=48000:cl=stereo",
             "-vf", vf, "-c:v", "libx264", "-crf", "12", "-preset", "fast", "-c:a", "pcm_s16le", "-shortest", str(out)])
        continue
    _, name, a, b, vol, overlay = seg
    dur = b - a
    src = str(SHOTS / f"{name}.avi")
    inputs = ["-ss", str(a), "-t", str(dur), "-i", src]
    if overlay:
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", str(dur), "-i", str(WORK / f"{overlay}.png")]
        fc = (f"[1:v]format=rgba,fade=in:st=1.2:d=0.8:alpha=1[o];[0:v][o]overlay=0:0,"
              f"fade=out:st={dur - 1.2}:d=1.2,format=yuv420p[v]")
    else:
        fc = "[0:v]format=yuv420p[v]"
    fc += f";[0:a]aresample=48000,volume={vol},afade=in:st=0:d=0.05,afade=out:st={dur - 0.08}:d=0.08[a]"
    run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", fc, "-map", "[v]", "-map", "[a]",
         "-r", str(FPS), "-c:v", "libx264", "-crf", "12", "-preset", "fast", "-c:a", "pcm_s16le", str(out)])

lst = WORK / "list.txt"
lst.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts))
joined = WORK / "joined.mkv"
run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(joined)])

total = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(joined)],
                             capture_output=True, text=True).stdout)
music_start = MUSIC_END - total
print(f"trailer length {total:.2f} s, music from {music_start:.2f} s")

# music carries the trailer, game sound effects sit under it; loudness normalized for YouTube (-14 LUFS)
fc = (f"[1:a]atrim=start={music_start}:end={MUSIC_END},asetpts=PTS-STARTPTS,aresample=48000,volume=0.8,"
      f"afade=in:st=0:d=2.0[m];"
      f"[0:a]volume=1.0[g];[m][g]amix=inputs=2:duration=first:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[a]")
run(["ffmpeg", "-v", "error", "-y", "-i", str(joined), "-i", MUSIC, "-filter_complex", fc,
     "-map", "0:v", "-map", "[a]", "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-profile:v", "high",
     "-pix_fmt", "yuv420p", "-g", "30", "-bf", "2", "-movflags", "+faststart",
     "-c:a", "aac", "-b:a", "320k", "-ar", "48000", "-t", str(total), str(OUT)])
print("written", OUT)
