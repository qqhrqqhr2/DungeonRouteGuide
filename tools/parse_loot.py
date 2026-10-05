import json, glob, os, re
from bs4 import BeautifulSoup
out={}
for f in sorted(glob.glob('*.html')):
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
json.dump(out,open('loot.json','w',encoding='utf-8'),ensure_ascii=False,indent=0)
for k,v in out.items(): print(k,len(v),sorted(set(b for i in v for b in i['bosses']))[:12])
