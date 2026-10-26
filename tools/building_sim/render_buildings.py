#!/usr/bin/env python3
# Vẽ mặt bằng + phối cảnh song song cho từng công trình trong dump_parts.
#   node tools/building_sim/dump_parts.cjs Plot_E1_PacificBluffsVilla ... > /tmp/parts_v27.json
#   python3 tools/building_sim/render_buildings.py   # cần Pillow
import json, math
from PIL import Image, ImageDraw, ImageFont

data = json.load(open("/tmp/parts_v27.json"))
F = "/usr/share/fonts/truetype/dejavu/"
f_b = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 18)
f_m = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 12)
f_s = ImageFont.truetype(F + "DejaVuSans.ttf", 10)

TITLES = {
    "Plot_E1_PacificBluffsVilla": ("E1 · PACIFIC BLUFFS VILLA", "biệt thự ven vịnh · hồ bơi vô cực · gara 2 xe"),
    "Plot_E2_LaMesaGarage": ("E2 · LA MESA CUSTOMS", "xưởng độ xe · 3 khoang cầu nâng · buồng sơn"),
    "Plot_E3_LittleSeoulDiner": ("E3 · LITTLE SEOUL DINER", "quán ăn đêm Hàn Quốc · 2 tầng · sân trước"),
    "Plot_E4_RichmanGalleria": ("E4 · RICHMAN GALLERIA", "TTTM 3 tầng · giếng trời vòm kính · sân thượng"),
    "Plot_D3_VinewoodCinema": ("D3 · VINEWOOD CINEMA", "rạp phim · 2 phòng chiếu · marquee"),
    "Plot_C2_LegionSquare": ("C2 · LEGION SQUARE", "quảng trường · bãi thử xe · đài phun nước · tượng đài"),
}
ORDER = ["Plot_E1_PacificBluffsVilla", "Plot_E2_LaMesaGarage", "Plot_E3_LittleSeoulDiner",
         "Plot_E4_RichmanGalleria", "Plot_D3_VinewoodCinema", "Plot_C2_LegionSquare"]

PW, PH = 660, 400
COLS = 2
ROWS = 3
W, H = PW * COLS + 8, PH * ROWS + 64
img = Image.new("RGB", (W, H), (9, 12, 18))
d = ImageDraw.Draw(img, "RGBA")
d.text((16, 14), "LOS SANTOS · QA 6 CÔNG TRÌNH DỰNG TRONG LƯỢT NÀY", font=f_b, fill=(226, 238, 248))
d.text((16, 38), "mỗi ô: TRÁI = mặt bằng nhìn từ trên (tô sáng theo độ cao) · PHẢI = phối cảnh song song 28°",
       font=f_s, fill=(132, 148, 166))

def fit(pts, ax, ay, aw, ah):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)
    s = min(aw / max(1e-6, bx1 - bx0), ah / max(1e-6, by1 - by0))
    ox = ax + (aw - (bx1 - bx0) * s) / 2 - bx0 * s
    oy = ay + (ah - (by1 - by0) * s) / 2 - by0 * s
    return s, ox, oy

def plan(parts, ax, ay, aw, ah):
    pts = [(p["x"] - p["ex"], p["z"] - p["ez"]) for p in parts] + \
          [(p["x"] + p["ex"], p["z"] + p["ez"]) for p in parts]
    s, ox, oy = fit(pts, ax, ay, aw, ah)
    for p in sorted(parts, key=lambda q: q["y"]):
        k = max(0.0, min(1.0, (p["y"] - 1.0) / 36.0))
        col = tuple(int(min(255, v * (0.6 + 0.5 * k) + 30 * k)) for v in p["c"])
        x0 = ox + (p["x"] - p["ex"]) * s; x1 = ox + (p["x"] + p["ex"]) * s
        y0 = oy + (p["z"] - p["ez"]) * s; y1 = oy + (p["z"] + p["ez"]) * s
        if x1 - x0 < 0.8: x1 = x0 + 0.8
        if y1 - y0 < 0.8: y1 = y0 + 0.8
        d.rectangle([x0, y0, x1, y1], fill=col + ((240 if p["ey"] > 3 else 175),))

def axono(parts, ax, ay, aw, ah):
    KX, KZ, KY = 0.94, 0.40, 0.62
    def proj(x, y, z):
        return ((x * KX + z * KZ), (-z * KZ * 0.72 - (y - 1.15) * KY))
    pts = []
    for p in parts:
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    pts.append(proj(p["x"] + sx * p["ex"], p["y"] + sy * p["ey"], p["z"] + sz * p["ez"]))
    s, ox, oy = fit(pts, ax, ay, aw, ah)
    for p in sorted(parts, key=lambda q: (q["z"], q["y"])):
        col = tuple(int(min(255, v * 0.9 + 14)) for v in p["c"])
        top = [proj(p["x"] + sx * p["ex"], p["y"] + p["ey"], p["z"] + sz * p["ez"])
               for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        face_top = [(ox + q[0] * s, oy + q[1] * s) for q in top]
        d.polygon(face_top, fill=tuple(min(255, int(v * 1.22) + 16) for v in p["c"]) + (240,))
        # mặt hướng Nam (ra trước)
        a0 = proj(p["x"] - p["ex"], p["y"] - p["ey"], p["z"] + p["ez"])
        a1 = proj(p["x"] + p["ex"], p["y"] - p["ey"], p["z"] + p["ez"])
        b0 = proj(p["x"] - p["ex"], p["y"] + p["ey"], p["z"] + p["ez"])
        b1 = proj(p["x"] + p["ex"], p["y"] + p["ey"], p["z"] + p["ez"])
        d.polygon([(ox + a0[0] * s, oy + a0[1] * s), (ox + a1[0] * s, oy + a1[1] * s),
                   (ox + b1[0] * s, oy + b1[1] * s), (ox + b0[0] * s, oy + b0[1] * s)],
                  fill=col + (240,))
        d.line(face_top + [face_top[0]], fill=(0, 0, 0, 46), width=1)

for i, key in enumerate(ORDER):
    col, row = i % COLS, i // COLS
    px, py = 8 + col * PW, 56 + row * PH
    t, sub = TITLES[key]
    d.rectangle([px, py, px + PW - 8, py + PH - 8], fill=(15, 20, 28, 255), outline=(38, 50, 64, 255))
    d.text((px + 12, py + 8), t, font=f_m, fill=(118, 214, 255))
    d.text((px + 12, py + 24), sub, font=f_s, fill=(126, 140, 156))
    n = len(data[key]["parts"])
    lbl = f"{n} part"
    d.text((px + PW - 20 - d.textlength(lbl, font=f_m), py + 8), lbl, font=f_m, fill=(150, 240, 168))
    parts = data[key]["parts"]
    gx = px + 10 + 300
    d.line([gx, py + 44, gx, py + PH - 18], fill=(36, 46, 60), width=1)
    plan(parts, px + 10, py + 46, 292, PH - 66)
    axono(parts, gx + 6, py + 46, PW - 40 - 300, PH - 66)
    d.text((px + 12, py + PH - 20), "mặt bằng", font=f_s, fill=(96, 112, 130))
    d.text((gx + 8, py + PH - 20), "phối cảnh", font=f_s, fill=(96, 112, 130))

OUT = __import__("os").path.join(__import__("os").path.dirname(__file__), "..", "..", "agents", "reviews", "city-buildings-v27.png")
img.save(OUT)
print("ok", img.size)
