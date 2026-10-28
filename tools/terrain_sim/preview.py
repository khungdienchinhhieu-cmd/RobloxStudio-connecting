"""
Bản Python của công thức địa hình trong src/shared/World/TerrainZone.luau.
Dùng để xem layout (đồi, sông, đường, cầu, rừng) mà không cần Studio.
Khi sửa công thức bên Luau, PHẢI sửa cả ở đây.
Chạy: python3 tools/terrain_sim/preview.py  -> ghi terrain_preview.png (không commit).
"""
import math, sys, os

HALF, V = 512, 4
WATER, ROAD_Y, RIVER_BED = 3, 12, -2

def clamp01(v): return 0.0 if v < 0 else (1.0 if v > 1 else v)
def smooth(t):
    u = clamp01(t); return u * u * (3 - 2 * u)
def hsh(ix, iz):
    v = math.sin(ix * 127.1 + iz * 311.7) * 43758.5453
    return v - math.floor(v)
def vnoise(x, z):
    ix, iz = math.floor(x), math.floor(z)
    fx, fz = x - ix, z - iz
    ux = fx * fx * (3 - 2 * fx); uz = fz * fz * (3 - 2 * fz)
    a = hsh(ix, iz); b = hsh(ix + 1, iz); c = hsh(ix, iz + 1); d = hsh(ix + 1, iz + 1)
    ab = a + (b - a) * ux; cd = c + (d - c) * ux
    return ab + (cd - ab) * uz
def fbm(x, z):
    s, amp, f, norm = 0.0, 0.5, 1.0, 0.0
    for _ in range(4):
        s += amp * vnoise(x * f, z * f); norm += amp; amp *= 0.5; f *= 2
    return s / norm
def river_x(z): return 80 * math.sin(z / 140)
def baseAt(x, z):
    m = smooth((vnoise(x / 450, z / 450) - 0.55) / 0.25)
    return 18 + 110 * fbm(x / 400, z / 400) + 6 * (vnoise(x / 60, z / 60) - 0.5) + 120 * m
def roadY(x):
    return max(10, sum(baseAt(x + k * 30, 0) for k in range(-3, 4)) / 7)
def heightAt(x, z):
    base = baseAt(x, z)
    d = abs(x - river_x(z))
    ro = 1 - smooth((abs(z) - 7) / 9)
    target = base + (roadY(x) - base) * ro
    if d < 18: return RIVER_BED
    if d < 32: return RIVER_BED + (target - RIVER_BED) * smooth((d - 18) / 14)
    return target
def isRoad(x, z): return abs(z) < 7 and abs(x - river_x(z)) >= 32
def isRiver(x, z): return abs(x - river_x(z)) < 32

def main():
    n = 2 * HALF // V
    grid = [[heightAt(-HALF + (i + .5) * V, -HALF + (k + .5) * V) for k in range(n)] for i in range(n)]
    flat = [h for row in grid for h in row]
    print(f"cao độ: min {min(flat):.1f}  max {max(flat):.1f} stud  (≈ {max(flat)/3.33:.1f} m đỉnh)")
    road = [roadY(x) for x in range(-500, 501, 20) if isRoad(x, 0.0)]
    print(f"đường tại z=0: {len(road)} điểm, cao {min(road):.1f}–{max(road):.1f} stud (≈ {min(road)/3.33:.0f}–{max(road)/3.33:.0f} m)")
    # cây: cùng quy tắc như Luau (mật độ theo fbm)
    forest = sum(1 for i in range(n) for k in range(n)
                 if fbm((-HALF + (i+.5)*V) / 140, (-HALF + (k+.5)*V) / 140) > 0.56
                 and 8 < grid[i][k] < 90 and abs(-HALF + (k+.5)*V) > 16 and not isRiver(-HALF+(i+.5)*V, -HALF+(k+.5)*V))
    print(f"ô rừng ứng viên (chưa tính jitter/độ ngẫu nhiên): {forest} / {n*n} ô")
    try:
        from PIL import Image
    except ImportError:
        print("Không có Pillow — bỏ qua ảnh."); return
    img = Image.new("RGB", (n, n))
    px = img.load()
    for i in range(n):
        for k in range(n):
            x, z = -HALF + (i+.5)*V, -HALF + (k+.5)*V
            h = grid[i][k]
            if isRiver(x, z) and h <= WATER: c = (40, 90, 160)
            elif isRoad(x, z) and h >= ROAD_Y - 1: c = (60, 60, 64)
            elif h > 80: c = (120, 110, 100)
            elif fbm(x/140, z/140) > 0.56 and 8 < h < 90: c = (30, 90, 40)
            else: c = (120, 170, 80) if h > 14 else (200, 185, 130)
            px[i, n-1-k] = c
    out = os.environ.get("TERRAIN_PREVIEW_OUT", os.path.join(os.path.dirname(__file__), "terrain_preview.png"))
    img.save(out); print("đã ghi", out)

if __name__ == "__main__":
    main()
