import json, glob, os, re, sys
# usage: python parse_loot.py [folder with <slug>.html loot pages]
from bs4 import BeautifulSoup
out={}
src=sys.argv[1] if len(sys.argv)>1 else '.'
for f in sorted(glob.glob(os.path.join(src,'*.html'))):
    slug=os.path.basename(f)[:-5]
    s=open(f,encoding='utf-8').read()
    soup=BeautifulSoup(s[:s.find('self.__next_f')],'html.parser')
    items=[]
    for li in soup.select('li[id^="item-"]'):
        iid=int(li['id'].split('-')[1])
        btn=li.find('button')
        spans=btn.find_all('span',recursive=False)
        boss=spans[-1].get_text(' ',strip=True) if spans else ''
        bosses=[b.strip() for b in re.split(r'\s*[·,/]\s*',boss) if b.strip()]
        items.append({'id':iid,'bosses':bosses})
    out[slug]=items
json.dump(out,open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'loot.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
for k,v in out.items(): print(k,len(v),sorted(set(b for i in v for b in i['bosses']))[:12])
