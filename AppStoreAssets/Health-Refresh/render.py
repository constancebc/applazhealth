import sys,math,json,zipfile
# Requires Pillow; install in your preferred Python environment.
from PIL import Image,ImageDraw,ImageFont,ImageFilter
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=Path(__file__).resolve().parent;src=Path(sys.argv[1]) if len(sys.argv)>1 else out/'native-captures'
fontpath='/System/Library/Fonts/Avenir Next.ttc'
def font(n):return ImageFont.truetype(fontpath,n)
def bg(w,h):
 im=Image.new('RGB',(132,287));p=im.load()
 for y in range(287):
  for x in range(132):
   a=math.exp(-((x/132-.9)**2+(y/287-.12)**2)/.22);b=math.exp(-((x/132-.15)**2+(y/287-.28)**2)/.25);c=math.exp(-((x/132-.8)**2+(y/287-.95)**2)/.25)
   p[x,y]=tuple(int(max(0,min(255,v))) for v in (249-9*b-18*c+5*a,247-7*b-28*c-19*a,251+2*b-4*c-32*a))
 return im.resize((w,h),Image.Resampling.BICUBIC)
def center(im,text,y,size):
 ImageDraw.Draw(im).multiline_text((im.width/2,y),text,font=font(size),fill='#111111',anchor='ma',align='center',spacing=2)
slides=[('01-notebooks','Reach your goals.\nOne day at a time.','Keep your routines, meals, and notes together.','design-home'),('02-checklist','Small habits.\nSteady progress.','Make daily checklists your own.','navigated-note'),('03-workout','Your routine.\nYour rhythm.','Plan workouts and check off each exercise.','navigated-workout'),('04-insights','See your\nconsistency.','Explore daily, weekly, and monthly patterns.','navigated-charts'),('05-food-diary','Make room for\na daily food diary.','Log meals and review your daily tally.','navigated-food'),('06-newsfeed','Share what\nkeeps you going.','Discover routines and reflections from others.','newsfeed'),('07-new-notebook','Make it\nyour own.','Choose a template, a layout, and who can see it.','new-notebook-preview')]
validation=[]
for kind,w,h,cw in [('iphone',1320,2868,920),('iphone-medium',1206,2622,840),('ipad',2064,2752,1450)]:
 folder=out/f'{kind}-{w}x{h}';folder.mkdir(parents=True,exist_ok=True)
 for filename,title,sub,route in slides:
  im=bg(w,h);scale=w/1320;pad=kind=='ipad'
  center(im,'A P P L A Z',90 if pad else round(105*scale),40 if pad else round(33*scale))
  center(im,title,210 if pad else round(220*scale),108 if pad else round(91*scale))
  center(im,sub,510 if pad else round(490*scale),42 if pad else round(35*scale))
  shot=Image.open(src/('ipad' if pad else 'iphone')/(route+'.png')).convert('RGB');ch=round(cw*shot.height/shot.width);shot=shot.resize((cw,ch),Image.Resampling.LANCZOS)
  x=(w-cw)//2;y=h-ch-(95 if pad else round(105*scale))
  assert y>600*scale if not pad else y>650
  shadow=Image.new('RGBA',im.size);ImageDraw.Draw(shadow).rounded_rectangle((x-14,y-5,x+cw+14,y+ch+27),radius=62,fill=(11,18,63,50));im=Image.alpha_composite(im.convert('RGBA'),shadow.filter(ImageFilter.GaussianBlur(24)))
  ImageDraw.Draw(im).rounded_rectangle((x-12,y-12,x+cw+12,y+ch+12),radius=170*scale if route=='navigated-note' and not pad else (60 if not pad else 45),fill='white')
  mask=Image.new('L',(cw,ch));ImageDraw.Draw(mask).rounded_rectangle((0,0,cw,ch),radius=160*scale if route=='navigated-note' and not pad else (48 if not pad else 32),fill=255);im.paste(shot,(x,y),mask)
  path=folder/(filename+'.png');im.convert('RGB').save(path)
  with Image.open(path) as check:assert check.size==(w,h) and check.mode=='RGB'
  validation.append({'file':str(path.relative_to(out)),'pixels':[w,h],'mode':'RGB','alpha':False,'native_device':'iPad Pro 13-inch M5' if pad else 'iPhone 18 Pro','route':route})
 sheet=Image.new('RGB',(300*len(slides),round(300*h/w)),'white')
 for i,(filename,*_) in enumerate(slides):sheet.paste(Image.open(folder/(filename+'.png')).resize((300,sheet.height),Image.Resampling.LANCZOS),(i*300,0))
 sheet.save(out/f'{kind}-overview.png')
(out/'validation.json').write_text(json.dumps(validation,indent=2))
print('Rendered and validated',len(validation),'opaque RGB screenshots')
