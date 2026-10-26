#!/usr/bin/env python3
# Vẽ bản đồ QA thành phố từ /api/services của bridge + dump_parts.cjs.
#   node tools/building_sim/dump_parts.cjs > /tmp/parts_all.json
#   python3 tools/building_sim/render_map.py        # cần Pillow
# Hình khối = chiếu bằng thật của từng part (nửa kích thước) — nhìn là thấy ô nào trống.
import json, urllib.request
from PIL import Image, ImageDraw, ImageFont

parts = json.load(open("/tmp/parts_all.json"))
svc = json.load(urllib.request.urlopen("http://localhost:8080/api/services"))
W, H = 1680, 900
X0, X1, Z0, Z1 = -640, 640, -300, 200
MX, MY, MTOP = 54, 18, 74
scale = min((W - 2 * MX) / (X1 - X0), (H - MTOP - 30) / (Z1 - Z0))
ox = (W - (X1 - X0) * scale) / 2
oy = MTOP + (H - MTOP - 30 - (Z1 - Z0) * scale) / 2
def sx(x): return ox + (x - X0) * scale
def sz(z): return oy + (z - Z0) * scale

img = Image.new("RGB", (W, H), (7, 10, 15))
d = ImageDraw.Draw(img, "RGBA")
F = "/usr/share/fonts/truetype/dejavu/"
f_t = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 22)
f_m = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 13)
f_s = ImageFont.truetype(F + "DejaVuSans.ttf", 10)
f_sb = ImageFont.truetype(F + "DejaVuSans-Bold.ttf", 10)

d.text((22, 14), "LOS SANTOS · 10/10 Ô ĐẤT ĐÃ CÓ CÔNG TRÌNH", font=f_t, fill=(230, 240, 250))
n_part = sum(len(v["parts"]) for v in parts.values())
d.text((22, 44), f"{n_part:,} BasePart · {len(parts)} module · 15 quầy dịch vụ đang chạy · hình khối = chiếu bằng thật của từng part"
       .replace(",", " "), font=f_s, fill=(140, 156, 174))

# ── đường ────────────────────────────────────────────────────────────────────
EW = [(-224, 40, "VINEWOOD BLVD"), (-36, 48, "OLYMPIC FREEWAY"), (148, 40, "VESPUCCI BLVD")]
NS = [(-556, 40, None), (-338, 40, None), (-110, 48, None), (110, 48, None), (338, 40, None), (556, 40, None)]
for c, w, name in EW:
    d.rectangle([sx(X0), sz(c - w/2), sx(X1), sz(c + w/2)], fill=(25, 30, 37, 255))
    d.line([sx(X0), sz(c - w/2), sx(X1), sz(c - w/2)], fill=(52, 62, 74, 255), width=1)
    d.line([sx(X0), sz(c + w/2), sx(X1), sz(c + w/2)], fill=(52, 62, 74, 255), width=1)
    if name:
        for px in range(int(sx(X0)), int(sx(X1)), 44):
            d.line([px, sz(c), px + 22, sz(c)], fill=(72, 84, 98, 255), width=1)
        d.text((sx(X0) + 12, sz(c) - 17), name, font=f_sb, fill=(116, 130, 146, 255))
for c, w, _ in NS:
    d.rectangle([sx(c - w/2), sz(Z0), sx(c + w/2), sz(Z1)], fill=(25, 30, 37, 255))
    d.line([sx(c - w/2), sz(Z0), sx(c - w/2), sz(Z1)], fill=(52, 62, 74, 255), width=1)
    d.line([sx(c + w/2), sz(Z0), sx(c + w/2), sz(Z1)], fill=(52, 62, 74, 255), width=1)

# ── ô đất + hình khối công trình ─────────────────────────────────────────────
for p in svc["plots"]:
    cx, cz, sw, sh = p["cx"], p["cz"], p["sx"], p["sz"]
    d.rectangle([sx(cx - sw/2), sz(cz - sh/2), sx(cx + sw/2), sz(cz + sh/2)],
                fill=(22, 32, 44, 210), outline=(46, 74, 96, 255), width=1)

plot_of = {}
for f, v in parts.items():
    plot_of.setdefault(v["plotId"], []).extend(v["parts"])

for pid, plist in plot_of.items():
    for q in sorted(plist, key=lambda r: r["y"]):
        k = max(0.0, min(1.0, (q["y"] - 1.0) / 44.0))
        c = q["c"]
        col = (int(min(255, c[0] * (0.5 + 0.6 * k) + 34 * k)),
               int(min(255, c[1] * (0.5 + 0.6 * k) + 34 * k)),
               int(min(255, c[2] * (0.5 + 0.6 * k) + 38 * k)))
        a = 225 if q["ey"] > 2.5 else 120
        x0 = sx(q["x"] - q["ex"]); x1 = sx(q["x"] + q["ex"])
        y0 = sz(q["z"] - q["ez"]); y1 = sz(q["z"] + q["ez"])
        if x1 - x0 < 0.6: x1 = x0 + 0.6
        if y1 - y0 < 0.6: y1 = y0 + 0.6
        d.rectangle([x0, y0, x1, y1], fill=col + (a,))

# ── nhãn ô + quầy ────────────────────────────────────────────────────────────
ALIAS = {"E1": "Plot_E1", "D1": "Plot_D1", "D2": "Plot_D2", "D3": "Plot_D3", "E2": "Plot_E2",
         "E3": "Plot_E3", "C1": "Plot_C1", "C2": "Plot_C2", "C3": "Plot_C3_East", "E4": "Plot_E4"}
for p in svc["plots"]:
    cx, cz, sw, sh = p["cx"], p["cz"], p["sx"], p["sz"]
    pid = ALIAS.get(p["id"], "Plot_" + p["id"])
    n = len(plot_of.get(pid, []))
    if p["id"] == "C3":
        n = len(plot_of.get("Plot_C3_East", [])) + len(plot_of.get("Plot_C3_West", []))
    tx = sx(cx - sw/2) + 6
    ty = sz(cz - sh/2) + 6
    lab = f"{p['id']} · {p['district']}"
    wd = max(d.textlength(lab, font=f_m), d.textlength(f"{n} part", font=f_s)) + 12
    d.rectangle([tx, ty, tx + wd, ty + 32], fill=(9, 13, 19, 214), outline=(48, 78, 100, 255))
    d.text((tx + 6, ty + 3), lab, font=f_m, fill=(126, 214, 255, 255))
    d.text((tx + 6, ty + 19), f"{n} part", font=f_s, fill=(150, 240, 170, 255))

for s in svc["services"]:
    px, py = sx(s["x"]), sz(s["z"])
    if s["active"]:
        d.ellipse([px-13, py-13, px+13, py+13], fill=(56, 189, 248, 34))
        d.ellipse([px-7, py-7, px+7, py+7], fill=(56, 189, 248, 92))
        d.ellipse([px-3, py-3, px+3, py+3], fill=(190, 240, 255, 255))
    else:
        d.ellipse([px-4, py-4, px+4, py+4], outline=(120, 132, 148, 150), width=1)

OUT = __import__("os").path.join(__import__("os").path.dirname(__file__), "..", "..", "agents", "reviews", "city-map-v27.png")
img.save(OUT)
print("saved", img.size)
