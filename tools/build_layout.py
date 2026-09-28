"""Assemble Havenreach from original-scale LPC tiles; no generated map bitmap.
Writes editable sprite/collision data and native tile coordinates for Godot.
"""
from pathlib import Path
import json, math, random
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets/lpc'; D=ROOT/'assets/derived';D.mkdir(exist_ok=True)
rng=random.Random(928)
assets={p.stem:Image.open(p).convert('RGBA') for p in A.glob('*.png')}
# Open door assembled from LPC frame pieces, with an 80px clear opening.
f=assets['doorframe']; door=Image.new('RGBA',(96,64),(0,0,0,0))
ImageDraw.Draw(door).rectangle((8,3,87,63),fill='#261c2a')
door.alpha_composite(f.crop((24,0,32,64)),(0,0))
door.alpha_composite(f.crop((64,0,72,64)),(88,0))
for x in range(8,88,16):door.alpha_composite(f.crop((32,0,48,4)),(x,0))
# House expansion repeats native columns; all source pixels remain 1:1.
def house_art(name,kind,extra):
 im=assets[kind].copy(); w,h=im.size
 if kind=='house_a':
  cut=112; out=Image.new('RGBA',(w+extra,h));out.alpha_composite(im.crop((0,0,cut,h)))
  for x in range(cut,cut+extra,32):out.alpha_composite(im.crop((112,0,144,h)),(x,0))
  out.alpha_composite(im.crop((cut,0,w,h)),(cut+extra,0))
  # Remove former stair art and replace the full doorway at its front facade.
  ImageDraw.Draw(out).rectangle((60,192,104,223),fill=(0,0,0,0))
  out.alpha_composite(door,(48,128))
  for x in range(48,144,32):out.alpha_composite(assets['steps'].crop((0,64,32,88)),(x,192))
  info={'w':w+extra,'h':h,'door':[96,192],'kind':'brick','extra':extra}
 else:
  # Extend the left roof and siding by a complete native 96px bay.
  out=Image.new('RGBA',(256,176));out.alpha_composite(im.crop((0,0,96,128)),(0,0));out.alpha_composite(im.crop((0,0,96,128)),(96,0));out.alpha_composite(im.crop((96,0,160,160)),(192,0))
  ImageDraw.Draw(out).rectangle((192,128,255,175),fill=(0,0,0,0))
  out.alpha_composite(door,(160,80))
  for x in range(160,256,32):out.alpha_composite(assets['steps'].crop((0,64,32,88)),(x,144))
  info={'w':256,'h':176,'door':[208,144],'kind':'cottage','extra':96}
 out.save(D/(name+'.png'));assets[name]=out
 return info
infos={n:house_art(n,k,e) for n,k,e in [('guild_house','house_a',0),('river_house','house_a',0),('rose_cottage','cottage',0),('garden_house','house_a',0),('workshop','cottage',0)]}
# LPC 64x64 animated sample character, composited without resizing.
src=ROOT.parent/'lpc-source'; walk=Image.new('RGBA',(512,256))
character_paths=['Characters/Body/Body 02 - Masculine, Thin/Tan/Walk.png','Characters/Head/Head 02 - Masculine/Tan/Walk.png','Characters/Clothing/Masculine, Thin/Legs/Pants 03 - Pants/Charcoal/Walk.png','Characters/Clothing/Masculine, Thin/Feet/Shoes 02 - Boots/Brown/Walk.png','Characters/Clothing/Masculine, Thin/Torso/Shirt 01 - Longsleeve Shirt/Blue/Walk.png','Characters/Head/Head Overlay - Eyes/Blue/Walk.png','Characters/Hair/Medium 01 - Page/Brown/Walk.png']
for p in character_paths:walk.alpha_composite(Image.open(src/p).convert('RGBA'))
walk.save(D/'sample_walk.png')
(ROOT/'credits/CHARACTER-SOURCES.json').write_text(json.dumps(character_paths,indent=2))
# Town geometry follows the approved layout with five courtyards and river east.
N=63; WORLD=2000
roads=Image.new('1',(WORLD,WORLD));rd=ImageDraw.Draw(roads)
paths=[([(1000,0),(1000,280),(948,532),(968,720),(960,928)],112), ([(0,1008),(320,1008),(680,1024),(920,1032),(1300,1008),(2000,1008)],128), ([(952,2000),(952,1730),(936,1520),(896,1350),(936,1216)],112), ([(468,524),(472,616),(652,692),(816,768),(904,928)],112), ([(1392,668),(1392,760),(1232,848),(1136,928)],112), ([(392,892),(400,984)],128), ([(440,1464),(440,1576),(688,1608),(928,1552)],112), ([(1336,1448),(1336,1568),(1140,1608),(928,1552)],112)]
for points,width in paths:rd.line(points,fill=1,width=width,joint='curve');[rd.ellipse((x-width//2,y-width//2,x+width//2,y+width//2),fill=1) for x,y in points]
rd.ellipse((708,820,1212,1236),fill=1)
water=Image.new('1',(WORLD,WORLD));wd=ImageDraw.Draw(water)
river=[(1760,0),(1760,208),(1736,360),(1784,544),(1832,696),(1760,848),(1776,1008),(1840,1200),(1784,1408),(1856,1584),(1912,1776),(2000,1952)]
wd.line(river,fill=1,width=128,joint='curve')
for x,y in river:wd.ellipse((x-64,y-64,x+64,y+64),fill=1)
wd.ellipse((1632,224,1888,416),fill=1)
roadgrid=[[bool(roads.getpixel((min(1999,x*32+16),min(1999,y*32+16)))) for x in range(N)] for y in range(N)]
watergrid=[[bool(water.getpixel((min(1999,x*32+16),min(1999,y*32+16)))) for x in range(N)] for y in range(N)]
data={'size':[2000,2000],'source':'ElizaWy/LPC','layers':[],'sprites':[],'solids':[],'houses':[],'spawn':[936,1440],'entrances':[[1000,40],[952,1960],[40,1032],[1960,1032]],'route_paths':[p for p,w in paths]}
def layer(name,tex,cells):data['layers'].append({'name':name,'texture':tex,'cells':cells})
base=[];grass=[];stone=[];wet=[];water_solids=[]
def val(grid,x,y,default=False):return grid[y][x] if 0<=x<N and 0<=y<N else default
# Quarter-tile autotiling using the LPC outer edges and concave corners.
def quarter(grid,x,y,qx,qy,origin,inner):
 hx=-1 if qx==0 else 1;vy=-1 if qy==0 else 1
 a=val(grid,x+hx,y);b=val(grid,x,y+vy);c=val(grid,x+hx,y+vy)
 if not a and not b: tx=0 if qx==0 else 2;ty=0 if qy==0 else 2
 elif not a: tx=0 if qx==0 else 2;ty=1
 elif not b:tx=1;ty=0 if qy==0 else 2
 elif not c:return [inner[0]+(1-qx)*2+qx,inner[1]+(1-qy)*2+qy]
 else:tx=1;ty=1
 return [(origin[0]+tx)*2+qx,(origin[1]+ty)*2+qy]
gridgrass=[[not roadgrid[y][x] for x in range(N)] for y in range(N)]
for y in range(N):
 for x in range(N):
  for qy in range(2):
   for qx in range(2):
    gx=x*2+qx;gy=y*2+qy
    if gx>=125 or gy>=125:continue
    base.append([gx,gy,6+qx,6+qy])
    if gridgrass[y][x]:
     sx,sy=quarter(gridgrass,x,y,qx,qy,(0,0),(0,12))
     if (x*13+y*29)%5==0 and all(val(gridgrass,x+dx,y+dy) for dx in [-1,0,1] for dy in [-1,0,1]):sx=6+qx;sy=2+qy
     grass.append([gx,gy,sx,sy])
    cx=gx*16+8;cy=gy*16+8
    if ((cx-960)/224)**2+((cy-1024)/176)**2<1:stone.append([gx,gy,qx,qy])
    if watergrid[y][x]:
     sx,sy=quarter(watergrid,x,y,qx,qy,(0,10),(0,26));wet.append([gx,gy,sx,sy])
     if not (944<=cy<=1088):water_solids.append([gx,gy])
layer('PackedEarth','terrain',base);layer('GrassEdges','terrain',grass);layer('TownSquare','stone',stone);layer('RiverBanks','terrain',wet)
data['water_cells']=water_solids
# Sprite / collision primitives use native pixel coordinates.
def sprite(name,tex,x,y,region=None,foot=None,z=0):
 o={'name':name,'texture':tex,'x':int(x),'y':int(y),'z':z}
 if region:o['region']=region
 if foot:o['foot']=foot
 data['sprites'].append(o);return o

def poly(name,pts):data['solids'].append({'name':name,'points':pts})
def rect(name,x,y,w,h):
 if w>0 and h>0:poly(name,[[x,y],[x+w,y],[x+w,y+h],[x,y+h]])
# Irregular masonry footprints; only the physical lower building collides.
def house(name,tex,x,y):
 info=infos[tex];dx,dy=info['door'];sprite(name,tex,x,y,foot=[x+info['w']/2,y+dy]);cx=x+dx;by=y+dy
 if info['kind']=='brick':
  extra=info['extra'];rect(name+'_back',x+32,y+96,128+extra,32);rect(name+'_left_jamb',x+32,y+128,24,64);rect(name+'_right_wall',cx+40,y+128,24+extra,64);rect(name+'_wing',x+160+extra,y+80,64,80)
 else:
  rect(name+'_back',x,y+56,256,8);rect(name+'_left_wall',x,y+64,168,80);rect(name+'_right_jamb',x+248,y+64,8,80)
 data['houses'].append({'id':tex,'name':name,'door':[cx,by-20],'front':[cx,by+48],'trigger':[cx-36,by-40,72,52]})
house('Guild House','guild_house',372,308)
house('Riverside House','river_house',1296,476)
house('Rose Cottage','rose_cottage',184,748)
house('Garden House','garden_house',344,1272)
house('Artisan Workshop','workshop',1128,1320)
# Four broad boundary openings; closing the map edges elsewhere prevents escape.
for name,x,y,w,h in [('Nw',0,-16,880,16),('Ne',1120,-16,880,16),('Sw',0,2000,848,16),('Se',1056,2000,944,16),('Wn',-16,0,16,896),('Ws',-16,1120,16,880),('En',2000,0,16,896),('Es',2000,1120,16,880)]:rect(name,x,y,w,h)
# Grass-capped low terraces assembled from native cliff sprites.
for begin,end,y in [(0,320,224),(320,880,128),(1120,1568,144),(1568,1696,80),(1824,2000,64),(0,288,1712),(288,576,1760),(576,848,1792),(1056,1504,1760),(1504,1728,1824)]:
 for x in range(begin,end,16):
  sprite('Terrace','cliff',x,y,[176,224,16,64],z=-5)
  rect('TerraceFace',x,y+24,16,40)
# Entrance stair treads; wide enough for full-square clearance test.
for x,y in [(904,96),(856,1808)]:
 for tx in range(x,x+192,32):sprite('GateSteps','steps',tx,y,[0,64,32,24],z=-2)
# Broad east bridge. Repeated native plank sections, with rail bases on the sides.
for x in range(1648,1936,32):
 for y in range(944,1088,16):sprite('BridgePlank','bridge',x,y,[32,32,32,16],z=-2)
 for y in [928,1088]:
  sprite('BridgeRail','fence',x,y,[32,0,32,32],foot=[x+16,y+30]);rect('BridgeRail',x,y+20,32,9)
for x in [1648,1936]:
 for y in [928,1088]:sprite('BridgePost','fence',x-8,y,[96,0,32,32],foot=[x+8,y+30]);rect('BridgePost',x+3,y+12,10,20)
# Fountain and landscaped plaza corners; route loops remain wide.
sprite('TownFountain','fountain',910,950,foot=[942,1028]);poly('FountainBase',[[916,984],[924,970],[953,970],[969,987],[969,1019],[953,1031],[927,1031],[916,1019]])
# Wooden seating composed from LPC furniture/picket timber details.
def bench(x,y):
 for tx in range(x,x+80,16):sprite('BenchSeat','bridge',tx,y,[32,40,16,24],foot=[x+40,y+28])
 for tx in [x,x+68]:sprite('BenchLeg','fence',tx,y+8,[108,16,12,16],foot=[x+40,y+28])
 rect('Bench',x+2,y+8,76,22)
bench(740,904);bench(1072,1144)
for x,y in [(680,856),(1128,880),(676,1152),(1192,1104),(700,644),(1536,824),(760,1488),(1080,1608)]:
 sprite('Lantern','lamp',x-16,y-86,[0,0,32,96],foot=[x,y]);rect('LampFoot',x-6,y-7,12,15)
# Sparse trees arranged around courtyards and the outer banks.
for x,y,t in [(144,160,0),(224,224,0),(146,560,1),(155,736,0),(1216,320,0),(1568,872,0),(136,1264,0),(752,1488,0),(1536,1256,1),(1696,1760,1),(160,1888,0),(1912,1872,0),(1480,1592,0),(1248,1920,0)]:
 region=[128,0,96,128] if t==0 else [128,384,96,128]
 sprite('Oak' if t==0 else 'Pine','trees',x-48,y-114,region,foot=[x,y]);rect('TreeTrunk',x-11,y-22,22,21)
# Low garden fences, kept away from each front apron.
def fence_h(x1,x2,y):
 for x in range(x1,x2,32):sprite('GardenFence','fence',x,y,[32,0,32,32],foot=[x+16,y+30]);rect('FenceRail',x,y+20,32,10)
 for x in (x1,x2):sprite('FencePost','fence',x-8,y,[96,0,32,32],foot=[x+8,y+30]);rect('FencePost',x+4,y+12,8,19)
def fence_v(x,y1,y2):
 for y in range(y1,y2,32):sprite('GardenFence','fence',x,y,[96,32,32,32],foot=[x+16,y+32]);rect('FenceRail',x+14,y,5,32)
 for y in range(y1,y2+1,64):sprite('FencePost','fence',x,y,[96,0,32,32],foot=[x+16,y+30]);rect('FencePost',x+12,y+12,8,19)
for x1,x2,y in [(316,724,300),(584,744,588),(1216,1632,432),(1512,1640,720),(120,280,740),(248,712,1264),(512,744,1536),(1456,1648,1392),(1432,1648,1616)]:fence_h(x1,x2,y)
for x,y1,y2 in [(308,316,480),(744,300,608),(1640,448,736),(112,740,920),(240,1296,1488),(744,1392,1536),(1648,1424,1632)]:fence_v(x,y1,y2)
# Planting is clustered in side plots and avoids the navigable lane centers.
def bush(x,y,flower=False):
 tex='flowers' if flower else 'plants';region=[rng.choice([0,32]),0,32,32] if flower else [0,0,32,32]
 sprite('RoseBush' if flower else 'Shrub',tex,x,y,region,foot=[x+16,y+27]);rect('BushBase',x+5,y+18,22,10)
for x1,x2,y in [(580,724,540),(520,700,1496),(1464,1616,1576)]:
 for x in range(x1,x2,32):bush(x,y,True)
for x,y in [(336,504),(560,504),(1216,640),(1520,644),(144,896),(444,900),(292,1456),(664,1456),(1104,1440),(1472,1456),(600,656),(832,656),(1336,872),(320,1640),(1600,1700),(160,320),(768,280),(1200,1520)]:bush(x,y,False)
# Vegetable beds at the riverside house: soil, crops and generous side margin.
for y in range(528,704,48):
 for x in range(1536,1632,32):
  sprite('SoilBed','soil',x,y,[160,0,32,32],z=-3)
  sprite('Vegetable','plants',x+4,y+8,[64,0,32,32],foot=[x+20,y+38])
# Crates and barrels are solid, stored at workshop sides.
for x,y in [(1512,1448),(1544,1464),(1512,1496),(324,500),(1280,650),(664,1472)]:
 sprite('Barrel','barrel',x,y,[0,0,32,48],foot=[x+16,y+40]);rect('BarrelBase',x+4,y+25,24,15)
for x,y in [(1488,1408),(1520,1408),(1488,1440),(320,1296),(352,1296)]:
 sprite('Crate','crate',x,y,[0,0,32,32],foot=[x+16,y+30]);rect('CrateBase',x+2,y+12,28,20)
# Low flowers and tufts are walkable and kept sparse.
for _ in range(210):
 x=rng.randrange(64,1940);y=rng.randrange(80,1940)
 if roads.getpixel((x,y)) or water.getpixel((x,y)):continue
 if any(abs(x-h['front'][0])<96 and abs(y-h['front'][1])<100 for h in data['houses']):continue
 if rng.random()<.6:sprite('MeadowTuft','plants',x,y,[496,48,16,16],z=-4)
 else:sprite('Wildflower','wildflowers',x,y,[0,0,16,16],z=-4)
sprite('Waterfall','waterfall',1712,0,[0,0,96,160],z=-4)['animation']={'frames':4,'step':96,'fps':6}
# Original LPC four-frame reflections; stagger phases along the flowing river.
for i,(x,y) in enumerate([(1740,200),(1700,280),(1788,328),(1716,420),(1752,524),(1816,652),(1772,788),(1728,884),(1816,1160),(1792,1300),(1776,1400),(1824,1520),(1872,1640),(1896,1760),(1944,1872)]):
 sprite('RiverReflections','reflections',x,y,[0,0,32,32],z=-5)['animation']={'frames':4,'step':32,'fps':4,'phase':i%4}
for i,(x,y) in enumerate([(1744,168),(1744,304),(1820,736),(1808,1232),(1864,1584)]):
 sprite('WaterRipples','reflections',x,y,[0,64,32,32],z=-5)['animation']={'frames':4,'step':32,'fps':5,'phase':i%4}

# Original source rock and reed clusters line the water without blocking the bridge.
for x,y in [(1640,336),(1848,424),(1680,664),(1864,808),(1704,1240),(1880,1456),(1800,1648)]:
 sprite('Reeds','plants',x,y,[320,0,32,64],foot=[x+16,y+58])
for x,y in [(1600,280),(1880,360),(1640,744),(1860,888),(1696,1380),(1910,1660)]:
 sprite('BankRock','rocks',x,y,[0,0,32,32],foot=[x+16,y+30]);rect('BankRockBase',x+5,y+17,22,14)
(ROOT/'data/havenreach.json').write_text(json.dumps(data,separators=(',',':')))
print('Terrain cells:',sum(len(l['cells']) for l in data['layers']),'sprites:',len(data['sprites']),'solid polygons:',len(data['solids']),'houses:',len(data['houses']))
