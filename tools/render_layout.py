from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1];a={p.stem:Image.open(p).convert('RGBA') for p in (R/'assets').rglob('*.png')};d=json.loads((R/'data/havenreach.json').read_text());im=Image.new('RGBA',(2000,2000),'#4b8638')
for layer in d['layers']:
 tex=a[layer['texture']]
 for x,y,sx,sy in layer['cells']:im.alpha_composite(tex.crop((sx*16,sy*16,sx*16+16,sy*16+16)),(x*16,y*16))
for s in sorted(d['sprites'],key=lambda s:(s['z'],s.get('foot',[s['x'],s['y']])[1])):
 tex=a[s['texture']]
 if 'region' in s:
  x,y,w,h=s['region'];tex=tex.crop((x,y,x+w,y+h))
 im.alpha_composite(tex,(s['x'],s['y']))
(R/'docs').mkdir(exist_ok=True);im.save(R/'docs/layout-review.png')
ov=Image.new('RGBA',im.size);dr=ImageDraw.Draw(ov)
for o in d['solids']:dr.polygon([tuple(p) for p in o['points']],fill=(255,48,60,80),outline=(255,32,40,200))
for x,y in d['water_cells']:dr.rectangle((x*16,y*16,x*16+15,y*16+15),fill=(255,48,60,80))
Image.alpha_composite(im,ov).save(R/'docs/collision-review.png')
