#!/usr/bin/env python3
"""Grobe Balancing-Simulation für die MVP-Mission (Phase 0).

Kein Spielcode: Diese Datei prüft nur, ob die vorläufigen Werte aus
docs/game-design/04-economy-and-balance.md grundsätzlich tragen.
Sie liest dieselbe JSON-Datei, die später das Spiel liest
(Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json), damit es nur EINE Quelle gibt.

Aufruf: python3 tools/balance-sim/sim.py [--verbose] [--reserve]
"""
import json, math, sys, os, random

HERE = os.path.dirname(os.path.abspath(__file__))
CFG = json.load(open(os.path.join(HERE, "..", "..", "Packages", "OddlingsCore", "Sources",
                            "OddlingsCore", "Resources", "Balance", "mvp-mission-01.json")))
DT = 1.0 / CFG["simulation"]["ticksPerSecond"]

PATH = [tuple(p) for p in CFG["map"]["path"]]
SEGS = []
_acc = 0.0
for a, b in zip(PATH, PATH[1:]):
    l = math.dist(a, b); SEGS.append((a, b, _acc, l)); _acc += l
PATH_LEN = _acc

def pos_at(d):
    for a, b, s, l in SEGS:
        if d <= s + l:
            t = (d - s) / l
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    return PATH[-1]

def dist_point_seg(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.dist(p, (ax + dx * t, ay + dy * t))

W, H = CFG["map"]["width"], CFG["map"]["height"]
MIN_CLEAR = CFG["map"]["minDistanceFromPath"]
CANDIDATES = [(x + 0.5, y + 0.5) for x in range(W) for y in range(H)
              if min(dist_point_seg((x + 0.5, y + 0.5), a, b) for a, b, *_ in SEGS) >= MIN_CLEAR]

def coverage(p, r, step=0.1):
    """Weglänge (Felder) innerhalb der Reichweite r um p."""
    n = 0; d = 0.0
    while d < PATH_LEN:
        if math.dist(pos_at(d), p) <= r: n += 1
        d += step
    return n * step

TOWERS = CFG["towers"]; ENEMIES = CFG["enemies"]

class Enemy:
    def __init__(s, kind, eid, scale=1.0):
        c = ENEMIES[kind]; s.kind = kind; s.id = eid
        s.hp = c["hp"] * scale; s.speed = c["speed"]; s.d = 0.0
        s.slow_until = -1; s.slow_factor = 1.0
    def p(s): return pos_at(s.d)

def run(build_order, verbose=False, seed=1):
    rng = random.Random(seed)
    gold = CFG["mission"]["startGold"]; lives = CFG["mission"]["fortressLives"]
    placed = []  # dict(kind, pos, cd)
    used = set()
    enemies = []; eid = 0; t = 0.0
    spawn_queue = []  # (time, kind)
    waves = CFG["waves"]; wi = -1; next_wave_at = CFG["mission"]["firstWaveDelay"]
    order = list(build_order); stats = {"leaked": 0, "kills": 0, "goldEarned": 0}
    dmg_by = {}

    def try_build():
        nonlocal gold
        while order and gold >= TOWERS[order[0]]["cost"]:
            k = order.pop(0); c = TOWERS[k]
            # Platz mit größter Wegabdeckung; Blitz bevorzugt Nähe zu Sporen
            best, bv = None, -1
            for p in CANDIDATES:
                if p in used: continue
                if k == "spore":
                    # Sporen lohnen dort, wo viele Angriffstürme denselben Weg abdecken
                    v = 0.0; d = 0.0
                    while d < PATH_LEN:
                        q = pos_at(d)
                        if math.dist(q, p) <= c["range"] + 0.5:
                            v += 0.25 * (1 + sum(1 for o in placed if o["kind"] != "spore"
                                                 and math.dist(q, o["pos"]) <= TOWERS[o["kind"]]["range"]))
                        d += 0.25
                else:
                    v = coverage(p, c["range"], 0.25)
                if k == "lightning":
                    v += sum(1.5 for q in placed if q["kind"] == "spore" and math.dist(p, q["pos"]) < 2.5)
                if v > bv: best, bv = p, v
            used.add(best); gold -= c["cost"]
            placed.append({"kind": k, "pos": best, "cd": 0.0, "id": len(placed)})
            if verbose: print(f"  t={t:6.1f}s baue {k:9s} @ {best}  (Abdeckung {bv:.1f})")

    while True:
        # Wellensteuerung
        if wi + 1 < len(waves) and t >= next_wave_at and not spawn_queue:
            wi += 1; w = waves[wi]; st = t
            for g in w["groups"]:
                for i in range(g["count"]):
                    spawn_queue.append((st + g.get("delay", 0) + i * g["interval"], g["enemy"], w.get("hpScale", 1.0)))
            spawn_queue.sort()
            last = spawn_queue[-1][0]
            next_wave_at = last + CFG["mission"]["timeBetweenWaves"]
        while spawn_queue and spawn_queue[0][0] <= t:
            _, k, sc = spawn_queue.pop(0); eid += 1; enemies.append(Enemy(k, eid, sc))
        try_build()
        # Sporen (Aura)
        for tw in placed:
            c = TOWERS[tw["kind"]]; tw["cd"] -= DT
            if tw["cd"] > 0: continue
            inr = [e for e in enemies if math.dist(e.p(), tw["pos"]) <= c["range"]]
            if not inr: continue
            tw["cd"] = c["attackInterval"]
            if tw["kind"] == "spore":
                for e in inr:
                    e.hp -= c["damage"]; dmg_by[tw["id"]] = dmg_by.get(tw["id"], 0) + c["damage"]
                    e.slow_factor = min(e.slow_factor if e.slow_until > t else 1.0, c["slowFactor"])
                    e.slow_until = t + c["slowDuration"]
            else:
                tgt = max(inr, key=lambda e: e.d)  # "erster" = am weitesten vorn
                dmg = c["damage"]; hit = {tgt.id}; cur = tgt
                cur.hp -= dmg; dmg_by[tw["id"]] = dmg_by.get(tw["id"], 0) + dmg
                for _ in range(c.get("chainJumps", 0)):
                    dmg *= c["chainFalloff"]
                    nxt = [e for e in enemies if e.id not in hit and math.dist(e.p(), cur.p()) <= c["chainRadius"]]
                    if not nxt: break
                    cur = min(nxt, key=lambda e: math.dist(e.p(), cur.p())); hit.add(cur.id)
                    cur.hp -= dmg; dmg_by[tw["id"]] = dmg_by.get(tw["id"], 0) + dmg
        # Bewegung, Tod, Durchbruch
        alive = []
        for e in enemies:
            if e.hp <= 0:
                r = ENEMIES[e.kind]["reward"]; gold += r; stats["goldEarned"] += r; stats["kills"] += 1; continue
            f = e.slow_factor if e.slow_until > t else 1.0
            e.d += e.speed * f * DT
            if e.d >= PATH_LEN:
                lives -= ENEMIES[e.kind]["leakDamage"]; stats["leaked"] += 1; continue
            alive.append(e)
        enemies = alive; t += DT
        if lives <= 0:
            return dict(result="NIEDERLAGE", wave=wi + 1, t=t, lives=0, gold=gold, towers=len(placed), **stats)
        if wi == len(waves) - 1 and not spawn_queue and not enemies:
            spent = sum(TOWERS[p["kind"]]["cost"] for p in placed)
            return dict(result="SIEG", wave=wi + 1, t=t, lives=lives, gold=gold, towers=len(placed), spent=spent, **stats)

STRATEGIES = CFG.get("simStrategies", {})

def headroom(order, lo=0.5, hi=4.0):
    """Größter globaler HP-Faktor, bei dem die Strategie noch gewinnt (Reserve der Verteidigung)."""
    base = {k: v["hp"] for k, v in ENEMIES.items()}
    def wins(f):
        for k in ENEMIES: ENEMIES[k]["hp"] = base[k] * f
        r = run(order); 
        for k in ENEMIES: ENEMIES[k]["hp"] = base[k]
        return r["result"] == "SIEG"
    if not wins(lo): return 0.0
    for _ in range(9):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if wins(m) else (lo, m)
    return lo


if __name__ == "__main__":
    verbose = "--verbose" in sys.argv
    print(f"Weglänge {PATH_LEN:.1f} Felder, {len(CANDIDATES)} Bauplätze, Ticks {1/DT:.0f}/s")
    total_gold = CFG["mission"]["startGold"] + sum(
        g["count"] * ENEMIES[g["enemy"]]["reward"] for w in CFG["waves"] for g in w["groups"])
    print(f"Gold gesamt verfügbar (Start + alle Belohnungen): {total_gold}")
    for name, order in STRATEGIES.items():
        r = run(order * 1, verbose=verbose)
        print(f"{name:28s} {r['result']:10s} Welle {r['wave']:2d}  Leben {r['lives']:2d}  "
              f"Türme {r['towers']:2d}  Durchbrüche {r['leaked']:3d}  Dauer {r['t']/60:4.1f} min")
    if "--reserve" in sys.argv:
        print("\nReserve = größter HP-Faktor auf alle Gegner, bei dem die Strategie noch gewinnt")
        for name, order in STRATEGIES.items():
            print(f"{name:28s} x{headroom(order):.2f}")
