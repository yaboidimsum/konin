#!/usr/bin/env python3
"""Generate placeholder pixel-art assets for 'Last Train East'.
All assets are intentionally small/lo-fi so they can be redrawn later.
"""
from PIL import Image, ImageDraw
import os

OUT_BG = "/Users/dimasps32/Developer/gamejam/Konin/Konin/Images/Backgrounds"
OUT_GP = "/Users/dimasps32/Developer/gamejam/Konin/Konin/Images/Gameplay"
os.makedirs(OUT_BG, exist_ok=True)
os.makedirs(OUT_GP, exist_ok=True)

def save(img, path):
    img.save(path, "PNG")
    print("wrote", os.path.basename(path))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def new(w, h, bg=(0,0,0,0)):
    return Image.new("RGBA", (w, h), bg)

def px(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def rect(img, x0, y0, x1, y1, color):
    d = ImageDraw.Draw(img)
    d.rectangle([x0, y0, x1, y1], fill=color)

def vline(img, x, y0, y1, color):
    d = ImageDraw.Draw(img); d.line([x, y0, x, y1], fill=color)

def hline(img, x0, x1, y, color):
    d = ImageDraw.Draw(img); d.line([x0, y, x1, y], fill=color)

# ---------------------------------------------------------------------------
# BACKGROUNDS  (1024 x 512 each, horizon near bottom third)
# ---------------------------------------------------------------------------
def make_background(name, sky_top, sky_mid, sky_horizon, ground_near, horizon_objs, mist=None):
    W, H = 1024, 512
    img = new(W, H)
    horizon = int(H * 0.62)
    # sky gradient (3 bands)
    for y in range(horizon):
        t = y / horizon
        if t < 0.5:
            f = t/0.5
            r = int(sky_top[0]*(1-f)+sky_mid[0]*f)
            g = int(sky_top[1]*(1-f)+sky_mid[1]*f)
            b = int(sky_top[2]*(1-f)+sky_mid[2]*f)
        else:
            f = (t-0.5)/0.5
            r = int(sky_mid[0]*(1-f)+sky_horizon[0]*f)
            g = int(sky_mid[1]*(1-f)+sky_horizon[1]*f)
            b = int(sky_mid[2]*(1-f)+sky_horizon[2]*f)
        hline(img, 0, W-1, y, (r,g,b,255))
    # ground gradient
    for y in range(horizon, H):
        t = (y-horizon)/(H-horizon)
        r = int(sky_horizon[0]*(1-t)+ground_near[0]*t)
        g = int(sky_horizon[1]*(1-t)+ground_near[1]*t)
        b = int(sky_horizon[2]*(1-t)+ground_near[2]*t)
        hline(img, 0, W-1, y, (r,g,b,255))
    # horizon line subtle
    hline(img, 0, W-1, horizon, (max(0,sky_horizon[0]-20), max(0,sky_horizon[1]-20), max(0,sky_horizon[2]-20), 255))
    # horizon objects (function draws silhouettes)
    horizon_objs(img, horizon)
    if mist:
        for y in range(horizon-40, horizon+10):
            a = int(60*(1-abs(y-horizon+15)/45))
            if a>0:
                d=ImageDraw.Draw(img); d.line([0,y,1023,y], fill=(mist[0],mist[1],mist[2],min(a,mist[3])))
    save(img, os.path.join(OUT_BG, name))

def church_spire(img, cx, base_y, shade):
    rect(img, cx-3, base_y-40, cx+3, base_y, shade)
    for dy in range(12):
        w = 4 - dy//3
        rect(img, cx-w, base_y-40-dy-12, cx+w, base_y-40-dy-12, shade)

def krotoszyn_objs(img, horizon):
    # distant church spires + low hills + simple houses
    hills = (138,140,118,255)
    for x in range(0,1024,8):
        hh = 4 + (x*7+len("krotoszyn"))%6
        vline(img, x, horizon-hh, horizon, hills)
    shade=(96,98,82,255)
    church_spire(img, 120, horizon, shade)
    church_spire(img, 760, horizon, shade)
    # small houses silhouettes
    for hx in [260, 540, 820]:
        rect(img, hx-14, horizon-16, hx+14, horizon, (110,104,92,255))
        # roof triangle-ish
        for dy in range(6):
            rect(img, hx-14+dy, horizon-16-dy-1, hx+14-dy, horizon-16-dy, (96,52,44,255))

def kozmin_objs(img, horizon):
    # darker hills, broken trees, damaged houses
    hills = (90,92,82,255)
    for x in range(0,1024,8):
        hh = 3 + (x*5)%5
        vline(img, x, horizon-hh, horizon, hills)
    # damaged farmhouse silhouettes
    for hx in [300, 700]:
        rect(img, hx-16, horizon-20, hx+16, horizon, (78,76,68,255))
        # collapsed roof
        for dy in range(8):
            rect(img, hx-16+dy, horizon-20-dy, hx+16-dy, horizon-20-dy, (60,58,54,255))
    # bare trees
    for tx in [120, 480, 880]:
        rect(img, tx-1, horizon-26, tx+1, horizon, (60,58,52,255))
        for b in range(6):
            px(img, tx-3+b, horizon-22-b%3, (60,58,52,255))

def jarocin_objs(img, horizon):
    # ruined city silhouette, smoke columns, fires
    shade=(54,50,46,255)
    for x in range(0,1024,10):
        hh = 30 + (x*13)%70
        rect(img, x, horizon-hh, x+8, horizon, shade)
    # gaps / broken tops
    for x in range(200, 800, 60):
        for yy in range(15):
            px(img, x, horizon-40+yy, (0,0,0,0)) if (x*yy)%3==0 else None
    # smoke columns
    for sx in [220, 520, 780]:
        for y in range(60):
            r=3+y//8
            for dx in range(-r,r):
                for dy in range(3):
                    a=120-y*2
                    if a>0: px(img, sx+dx, horizon-80-y+dy, (90,86,82,a))
    # fire glow
    fx=[220,780]
    for fxp in fx:
        for y in range(20):
            a=160-y*7
            if a>0: hline(img, fxp-12, fxp+12, horizon-2-y, (180,100,40,a))

def konin_objs(img, horizon):
    # ethereal: soft hills, single distant spire, hazy
    hills=(150,148,130,180)
    for x in range(0,1024,8):
        hh=3+(x*3)%4
        vline(img, x, horizon-hh, horizon, hills)
    church_spire(img, 512, horizon, (170,162,140,200))
    # soft clouds
    for cy in [80,140]:
        for cx in range(150,900,180):
            for dx in range(40):
                for dy in range(6):
                    a=80- dy*10
                    if a>0: px(img, cx+dx, cy+dy, (220,214,196,a))

def zolkiew_objs(img, horizon):
    # misty town silhouette
    shade=(150,150,146,200)
    for x in range(0,1024,12):
        hh=20+(x*17)%50
        rect(img, x, horizon-hh, x+10, horizon, shade)
    church_spire(img, 480, horizon, (150,148,140,210))
    church_spire(img, 640, horizon, (150,148,140,210))

make_background("bg-krotoszyn.png",(110,126,138),(180,176,160),(196,184,150),(96,100,74), krotoszyn_objs)
make_background("bg-kozmin.png",(64,70,74),(88,92,90),(104,104,96),(58,56,50), kozmin_objs)
make_background("bg-jarocin.png",(74,68,66),(96,80,64),(122,86,60),(58,50,40), jarocin_objs)
make_background("bg-konin.png",(150,146,132),(180,168,140),(200,178,140),(108,122,90), konin_objs)
make_background("bg-zolkiew.png",(170,172,168),(190,190,186),(200,200,196),(140,142,134), zolkiew_objs, mist=(210,210,206,90))

# ---------------------------------------------------------------------------
# GAMEPLAY SPRITES
# ---------------------------------------------------------------------------
def sprite(name, w, h, draw_fn):
    img = new(w,h)
    draw_fn(img)
    save(img, os.path.join(OUT_GP, name))

# rail-metal.png  4 x 32  (vertical rail texture; we use rotated/scaled)
(r_top, r_main, r_shade)=(210,205,200),(150,150,150),(90,90,90)
def rail_metal(img):
    W,H=img.size
    for y in range(H):
        px(img,0,y,(r_top+r_shade)[0]//2 if y%4==0 else r_top) if y==0 else None
    # simplied: column 0 highlight, 1 main, 2 shade, 3 dark
    for y in range(H):
        px(img,0,y,(220,216,210,255))
        px(img,1,y,(160,158,156,255))
        px(img,2,y,(110,110,110,255))
        px(img,3,y,(70,70,70,255))
sprite("rail-metal.png",4,32,rail_metal)

# sleeper-wood.png 48 x 12
def sleeper_wood(img):
    rect(img,0,0,img.width-1,img.height-1,(92,66,40,255))
    # grain
    for x in range(0,img.width,6):
        vline(img,x,0,img.height-1,(76,54,32,255))
    # edge shadow / highlight
    hline(img,0,img.width-1,0,(110,80,48,255))
    hline(img,0,img.width-1,img.height-1,(56,38,24,255))
    # cracks
    for x in [12,30,40]:
        vline(img,x,2,img.height-3,(50,34,20,255))
sprite("sleeper-wood.png",48,12,sleeper_wood)

# ballast.png 32 x 32 gravel tile
def ballast(img):
    rect(img,0,0,31,31,(74,70,64,255))
    import random; random.seed(7)
    for _ in range(120):
        x=random.randint(0,31); y=random.randint(0,31)
        c=random.choice([(90,86,78,255),(60,56,50,255),(104,98,88,255),(70,66,60,255)])
        px(img,x,y,c)
sprite("ballast.png",32,32,ballast)

# rail-joint.png 12 x 8 bolt plate
def rail_joint(img):
    rect(img,0,0,11,7,(120,120,120,255))
    rect(img,1,1,10,6,(150,150,150,255))
    for bx,by in [(2,2),(9,2),(2,5),(9,5)]:
        rect(img,bx,by,bx+1,by+1,(60,60,60,255))
sprite("rail-joint.png",12,8,rail_joint)

# tree-birch.png 32 x 64
def tree_birch(img):
    W,H=img.size
    # trunk
    rect(img,14,H-24,17,H,(220,216,200,255))
    for y in range(H-24,H,3):
        rect(img,14,y,15,y,(40,38,34,255))
    # foliage clumps
    for cx,cy in [(16,H-30),(10,H-40),(22,H-42),(16,H-52)]:
        for dx in range(-6,7):
            for dy in range(-6,7):
                if dx*dx+dy*dy<28:
                    px(img,cx+dx,cy+dy,(120,140,84,255))
    # shadow under
    rect(img,10,H-25,22,H-24,(40,40,40,160))
sprite("tree-birch.png",32,64,tree_birch)

# tree-pine.png 28 x 60
def tree_pine(img):
    W,H=img.size
    rect(img,13,H-14,15,H,(70,50,36,255))
    for i,(ys,w) in enumerate([(H-16,12),(H-30,10),(H-44,8)]):
        for dx in range(-w,w+1):
            for dy in range(10):
                if abs(dx)<=w-dy:
                    px(img,14+dx,ys-dy,(46,70,48,255))
sprite("tree-pine.png",28,60,tree_pine)

# tree-oak.png 40 x 56
def tree_oak(img):
    W,H=img.size
    rect(img,18,H-16,21,H,(80,56,36,255))
    for cx,cy in [(20,H-20),(12,H-28),(28,H-30),(20,H-38)]:
        for dx in range(-10,11):
            for dy in range(-10,11):
                if dx*dx+dy*dy<70:
                    px(img,cx+dx,cy+dy,(86,104,52,255))
sprite("tree-oak.png",40,56,tree_oak)

# bush-small.png 24 x 16
def bush_small(img):
    for cx,cy in [(8,10),(16,8),(12,12)]:
        for dx in range(-7,8):
            for dy in range(-6,7):
                if dx*dx+dy*dy<30:
                    px(img,cx+dx,cy+dy,(70,90,48,255))
sprite("bush-small.png",24,16,bush_small)

# bush-flower.png 28 x 20
def bush_flower(img):
    for cx,cy in [(10,12),(18,10)]:
        for dx in range(-8,9):
            for dy in range(-7,8):
                if dx*dx+dy*dy<38:
                    px(img,cx+dx,cy+dy,(82,104,56,255))
    for fx,fy,c in [(6,6,(220,200,120,255)),(20,7,(210,140,160,255)),(14,15,(220,200,120,255))]:
        rect(img,fx,fy,fx+1,fy+1,c)
sprite("bush-flower.png",28,20,bush_flower)

# telegraph-pole.png 16 x 90
def telegraph_pole(img):
    rect(img,7,0,9,img.height-1,(120,90,60,255))
    rect(img,2,16,14,18,(140,104,68,255))
    rect(img,1,40,15,42,(140,104,68,255))
    # ceramic insulators
    for ix in [4,12]:
        rect(img,ix-1,13,ix,15,(210,210,210,255))
sprite("telegraph-pole.png",16,90,telegraph_pole)

# telegraph-pole-broken.png 24 x 70
def telegraph_broken(img):
    rect(img,9,30,11,69,(120,90,60,255))
    rect(img,9,28,18,30,(140,104,68,255))
    # snapped top lying
    rect(img,9,26,22,28,(120,90,60,255))
    rect(img,9,24,15,26,(140,104,68,255))
sprite("telegraph-pole-broken.png",24,70,telegraph_broken)

# farmhouse-polish.png 64 x 56
def farmhouse_polish(img):
    W,H=img.size
    rect(img,4,20,60,55,(208,196,176,255))
    # roof
    for dy in range(14):
        rect(img,4-dy//2,20-dy-1,60+dy//2,20-dy,(150,54,42,255))
    rect(img,4,19,60,20,(150,54,42,255))
    # door
    rect(img,26,38,38,55,(90,60,40,255))
    # windows
    rect(img,10,30,20,40,(200,200,180,255))
    rect(img,44,30,54,40,(200,200,180,255))
    # chimney
    rect(img,46,4,52,20,(150,140,120,255))
sprite("farmhouse-polish.png",64,56,farmhouse_polish)

# farmhouse-damaged.png 64 x 56
def farmhouse_damaged(img):
    rect(img,4,24,60,55,(150,144,130,255))
    for dy in range(12):
        rect(img,4+dy,24-dy,30,24-dy,(120,52,38,255))
    rect(img,30,24,60,28,(120,52,38,255))
    # holes
    rect(img,12,32,20,40,(40,40,40,255))
    rect(img,40,44,52,52,(40,40,40,255))
    # door
    rect(img,24,40,34,55,(70,46,32,255))
sprite("farmhouse-damaged.png",64,56,farmhouse_damaged)

# haystack.png 40 x 32
def haystack(img):
    rect(img,2,24,38,32,(120,92,40,255))
    for dy in range(20):
        w=max(0,16-dy)
        if w>0:
            rect(img,20-w,24-dy,20+w,24-dy,(150,118,52,255))
    rect(img,2,30,38,32,(90,68,30,255))
sprite("haystack.png",40,32,haystack)

# church-spire.png 24 x 80
def church_spire_spr(img):
    rect(img,10,40,14,80,(140,140,130,255))
    for dy in range(36):
        w=8-dy//4
        rect(img,12-w,40-dy-4,12+w,40-dy,(150,150,140,255))
    # cross
    rect(img,11,0,13,6,(200,200,200,255))
    rect(img,9,2,15,4,(200,200,200,255))
sprite("church-spire.png",24,80,church_spire_spr)

# wrecked-tank.png 64 x 40
def wrecked_tank(img):
    # treads
    rect(img,2,30,62,36,(40,40,40,255))
    for x in range(2,62,6):
        rect(img,x,28,x+4,30,(60,60,60,255))
    # body
    rect(img,8,22,52,30,(70,72,66,255))
    rect(img,8,20,52,22,(86,88,80,255))
    # turret (tilted)
    rect(img,18,14,40,22,(70,72,66,255))
    # barrel broken
    rect(img,40,16,56,18,(50,50,50,255))
    rect(img,54,15,58,19,(40,40,40,255))
    # scorch
    rect(img,20,24,30,28,(30,30,30,255))
sprite("wrecked-tank.png",64,40,wrecked_tank)

# crater.png 48 x 24
def crater(img):
    rect(img,0,8,48,24,(60,54,44,255))
    for dy in range(14):
        w=20-dy
        rect(img,24-w,8+dy,24+w,8+dy,(40,34,28,255))
    rect(img,6,4,42,8,(74,66,54,255))
sprite("crater.png",48,24,crater)

# barbed-wire.png 48 x 16
def barbed_wire(img):
    rect(img,2,12,46,14,(80,74,64,255))
    for x in range(4,46,8):
        rect(img,x,4,x+1,12,(90,86,78,255))
        for yy in range(4,12,3):
            px(img,x-1,yy,(90,86,78,255)); px(img,x+1,yy+1,(90,86,78,255))
sprite("barbed-wire.png",48,16,barbed_wire)

# sandbags.png 48 x 24
def sandbags(img):
    for i,(bx,by) in enumerate([(2,14),(14,12),(26,14),(38,12),(8,6),(20,4),(32,6)]):
        for dx in range(10):
            for dy in range(8):
                if dx*dx+dy*dy<40:
                    px(img,bx+dx,by+dy,(120,104,72,255))
        rect(img,bx,by+6,bx+9,by+7,(90,78,52,255))
sprite("sandbags.png",48,24,sandbags)

# cart-horse.png 64 x 40
def cart_horse(img):
    # horse silhouette
    rect(img,4,18,24,32,(70,54,44,255))
    rect(img,4,14,10,20,(70,54,44,255))
    for x in range(6,24,4):
        vline(img,x,32,40,(70,54,44,255))
    # cart
    rect(img,28,22,60,34,(120,90,56,255))
    rect(img,28,20,60,22,(100,74,44,255))
    for x in range(30,58,8):
        vline(img,x,34,40,(60,44,30,255))
sprite("cart-horse.png",64,40,cart_horse)

# water-tower.png 32 x 72
def water_tower(img):
    rect(img,4,40,28,72,(110,104,92,255))
    rect(img,2,28,30,40,(120,110,94,255))
    rect(img,8,20,24,28,(120,110,94,255))
    rect(img,10,8,22,20,(120,110,94,255))
sprite("water-tower.png",32,72,water_tower)

# tunnel-wall.png 64 x 64  (brick)
def tunnel_wall(img):
    rect(img,0,0,63,63,(54,48,44,255))
    for row in range(0,64,8):
        for col in range(0 if row//8%2==0 else -16,64,16):
            for dx in range(14):
                for dy in range(6):
                    c=(80,72,66,255) if (dx+dy)%3!=0 else (70,62,58,255)
                    rect(img,col+dx,row+dy,col+dx,row+dy,c)
sprite("tunnel-wall.png",64,64,tunnel_wall)

# tunnel-beam.png 16 x 64
def tunnel_beam(img):
    rect(img,0,0,15,15,(90,66,40,255))
    rect(img,6,0,9,64,(70,52,32,255))
    rect(img,0,0,15,3,(110,82,52,255))
sprite("tunnel-beam.png",16,64,tunnel_beam)

# station-building.png 240 x 120
def station_building(img):
    W,H=img.size
    rect(img,0,40,W,H,(190,184,172,255))
    # brick lower
    rect(img,0,80,W,H,(150,90,72,255))
    for row in range(80,H,6):
        for col in range(0 if row//6%2==0 else -8,W,16):
            rect(img,col,row,col+14,row+5,(160,98,78,255))
    # roof
    for dy in range(20):
        rect(img,-2-dy//2,40-dy-1,W+2+dy//2,40-dy,(130,52,42,255))
    rect(img,0,39,W,40,(140,58,46,255))
    # arched windows
    for wx in [20,80,140,180]:
        rect(img,wx,52,wx+22,76,(210,210,190,255))
        rect(img,wx,50,wx+22,52,(120,116,104,255))
        for x in range(wx,wx+22):
            if (x-wx)%11==0: vline(img,x,52,76,(90,90,84,255))
    # door
    rect(img,108,58,130,100,(90,60,40,255))
    rect(img,106,56,132,58,(120,116,104,255))
    # gable clock
    rect(img,104,18,136,40,(160,154,142,255))
    rect(img,112,24,128,36,(220,210,190,255))
    rect(img,118,26,122,34,(50,50,50,255))
sprite("station-building.png",240,120,station_building)

# station-platform.png 256 x 16
def station_platform(img):
    rect(img,0,4,255,16,(170,166,158,255))
    rect(img,0,0,255,4,(120,116,108,255))
    # yellow safety line
    hline(img,0,255,7,(200,180,80,255))
    for x in range(8,256,24):
        vline(img,x,7,11,(180,160,70,255))
sprite("station-platform.png",256,16,station_platform)

# station-clock.png 24 x 24
def station_clock_spr(img):
    rect(img,0,0,23,23,(40,40,40,255))
    rect(img,2,2,21,21,(220,210,190,255))
    rect(img,11,4,12,10,(40,40,40,255))
    rect(img,11,11,17,12,(40,40,40,255))
sprite("station-clock.png",24,24,station_clock_spr)

# station-lamp.png 16 x 48
def station_lamp(img):
    rect(img,7,8,9,48,(60,56,50,255))
    rect(img,6,6,10,8,(80,76,66,255))
    rect(img,4,0,12,6,(200,180,120,255))
    rect(img,5,1,11,5,(220,200,140,255))
sprite("station-lamp.png",16,48,station_lamp)

# station-bench.png 32 x 16
def station_bench(img):
    rect(img,2,8,30,10,(100,70,44,255))
    rect(img,2,6,30,8,(120,88,56,255))
    rect(img,2,10,4,16,(70,52,32,255))
    rect(img,29,10,31,16,(70,52,32,255))
sprite("station-bench.png",32,16,station_bench)

# passenger-silhouette.png 16 x 32
def passenger_sil(img):
    rect(img,5,2,9,8,(30,30,34,255))
    rect(img,4,9,10,24,(40,40,46,255))
    rect(img,4,24,6,32,(30,30,34,255))
    rect(img,8,24,10,32,(30,30,34,255))
sprite("passenger-silhouette.png",16,32,passenger_sil)

print("DONE")