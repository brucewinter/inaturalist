
# Download info and photos for specified iNaturalist user and create html pages
#  - API documented here: https://api.inaturalist.org/v1/docs/#!/Observations/get_observations
#  - More info at: http://brucewinter.net/photos/inaturalist/

import requests, json, os, time, getopt, sys
from functools import partial

user = 'brucewinter'
path = 'c:/Users/bruce/Documents/inaturalist/animals'

pgm = sys.argv[0]
soptions = "huo:"
loptions = ["help", "user", "outdir ="] 
try: 
    arguments, values = getopt.getopt(sys.argv[1:], soptions, loptions) 
    for myarg, myval in arguments: 
        if myarg in ("-h", "--Help"): 
            print ('\n%s downloads data from inaturalist.org\n\nUsage: %s --user %s --outdir %s\n' % (pgm, pgm, user, path))
            exit()
        elif myarg in ("-u", "--user"): 
            user = myval
        elif myarg in ("-o", "--outdir"): 
            path = myval
except getopt.error as err: 
    print (str(err))
    
out0  = path + '/inat_0.json'
out1  = path + '/inat_1.html'
out2  = path + '/inat_2.html'
out3  = path + '/inat_3.html'
out4  = path + '/inat_1.txt'
outp  = path + '/photos_large8'


# Disable print buffering, so we can watch results in real time
print = partial(print, flush=True) 

obs = []

# Allow for quicker runs by re-loading previous data
if (False):
    print('Loading observation data for ' + user);
    f = open(out0)
    obs = json.load(f)
else:
    # If > 200 observatsion, need to loop through multiple 'pages'
    for x in [1, 2] :
        print('Downloading observation data for user=' + user + ' page=' + str(x));
        url = 'https://api.inaturalist.org/v1/observations?user_id=%s&order=desc&order_by=created_at&per_page=200&page=%s' % (user, str(x))
        response = requests.get(url)
        c_user = json.loads(response.content)
        obs += c_user['results']
    with open(out0, 'w') as out:   out.write(json.dumps(obs, sort_keys=True, indent=4))
    

count  = 0
counts = {}
data   = {}
hlist1 = {}


for c_obs in obs:
    count += 1
#   if count < 55: continue
#   if count > 5: break
    id = c_obs['id']
#   print(c_obs)
    url_obs = 'https://www.inaturalist.org/observations/'  + str(id)
    if c_obs['observed_on_details'] :
        date = c_obs['observed_on_details']['date']
    else :
        date = c_obs['created_at_details']['date']
    photos = c_obs['photos']
    if c_obs['taxon']:
        taxon   = c_obs['taxon'].get('iconic_taxon_name', '')
        name1   = c_obs['taxon'].get('name', '')
        name2   = c_obs['taxon'].get('preferred_common_name', '')
        wiki    = 'wiki data placeholder'
#       wiki    = c_obs['taxon'].get('wikipedia_summary', '')
    else:
        print('No taxon found: ' + date + ' url=' + url_obs)
        continue

# Limit to just plants, animals, etc?
#   if not taxon == 'Plantae' : continue
#   if not (taxon == 'Amphibia' or taxon == 'Aves' or taxon == 'Mammalia' or taxon == 'Reptilia'): continue
    if not (taxon == 'Fungi' or taxon == 'Protozoa') : continue
#   if not (taxon == 'Insecta' or taxon == 'Mollusca' or taxon == 'Arachnida') : continue
    
    print(str(count) + ' id=' + str(id) + ' ' + date + ' ' + name1 + ' ' + name2)
    
    name1a = name1.replace(' ', '_')
    name1b = name1.replace(' ', '%20')

    # plantnet requires species (e.g. x y L.).  Inatualist only has Genus (e.g. x y)
    links = ''
#   links  += '<a href=https://identify.plantnet.org/species/the-plant-list/%s>Plantnet</a>  ' % (name1)  
    links  += '<a href=https://en.wikipedia.org/wiki/%s>Wikipedia</a>  ' % (name1a)
    links  += '<a href=https://www.inaturalist.org/taxa/search?q=%s>iNaturalist</a>  ' % (name1b)
    links  += '<a href=%s>Observation</a>  ' % (url_obs)

    html1 = '<hr>\n<h2 id=%s>%s: %s %s</h2>\n' % (id, date, name1, links)
    html2 = '<div class="container"></a>\n'
    html2 = '<div class="container" style="cursor: pointer;" onclick="window.location=\'%s\'">\n' % (url_obs)

    if not os.path.isdir(outp):         os.mkdir(outp)
    if not os.path.isdir(outp + '/1'):  os.mkdir(outp + '/1')
    if not os.path.isdir(outp + '/2'):  os.mkdir(outp + '/2')
    
    url3 = ''
    pc = 0
    for p in photos:
        pc += 1
        url2 = p['url'].replace('square', 'large')
        url2 = url2.replace('https', 'http') # this did not work:  --no-check-certificate
        if not url3: url3 = url2
        html1 += '<img width=500 src="%s">\n' % (url2)

        # Download the first 2 photos
        if (pc < 3):
            html2 += '<img width=200 src="%s">\n' % (url2)
            file = outp + '/' + str(pc) + '/' + name1 + '     ' + name2 + '.jpg'
            print('Checking photo: ' + file)
            if not os.path.isfile(file):
                print('Downloading: ' + url2)
                response = requests.get(url2)
                with open(file, 'wb') as out:   out.write(response.content)

# Get wiki data.  Could also do this through inaturalist, but it returns a lot of data per observation and it is rate limited, so would need to loop on 429 return code
# Also, we can keep the html formating when we get directly from wikapedia
#    url = 'https://api.inaturalist.org/v1/observations/' + str(id)
#    response = requests.get(url)
#    if response.status_code == 200 :
#        c_obs = json.loads(response.content)['results'][0]
#        wiki    = c_obs['taxon'].get('wikipedia_summary', '')
    url = 'https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&redirects=1&titles=' + name1b
    response = requests.get(url)
    if response.status_code == 200 :
        wiki = response.text
#       wiki = response.content
        i = wiki.find('"extract":')
        if i: 
            wiki = wiki[i+10 : ]
            wiki = wiki.replace('}',   '')
            wiki = wiki.replace('\"',  '')
            wiki = wiki.replace('\\n', '')

    html1 += '<h2><i>%s</i>: %s  </h2>%s\n' % (name1, name2, wiki)
    html2 += '<div class="top-center">%s</div>\n</div>\n' % (name2)

    counts[taxon] = counts.get(taxon, 0) + 1
    data[id]   = {'date'  : date, 'name1' : name1, 'name2' : name2, 'taxon' : taxon, 'wiki' : wiki}
    hlist1[id] = {'h1' : html1, 'h2' : html2}

    
print('Sorting data...')
ids_by_date = sorted(data, key=lambda x:  data[x]['date'], reverse=True)
ids_by_name = sorted(data, key=lambda x: (data[x]['taxon'], data[x]['name1']))
counts2 = 'Count totals: '
for t in sorted(counts) : counts2 += t + '=' + str(counts[t]) + ',  '

hlist2 = ''
for id in ids_by_date:
    hlist2 += hlist1[id]['h1'] + '\n'

toc    = ''
tlist  = ''
hlist3 = ''
hlist4 = ''
for id in ids_by_name:
    toc    += '<li><a href=#%s>%s %s</a>  %s</li>\n' % (id, data[id]['taxon'], data[id]['name1'], data[id]['name2'])
    tlist  += '%s, %s\n' % (data[id]['name1'], data[id]['name2'])
    hlist3 += hlist1[id]['h1'] + '\n'
    hlist4 += hlist1[id]['h2'] + '\n'


html3 = '''\
<!DOCTYPE html>
<html>
<head>
<style>
  .container {
      position: relative;
      display: inline-block;
      text-align: center;
      color: white;
  }
  .top-left {
      position: absolute;
      top: 8px;
      left: 16px;
      background-color: #ffffff;
  }
  .top-center {
      position: absolute;
      top: 8px;
      left: 50%;
      transform: translate(-50%);
      background-color: black;
  }
}
</style>
</head>
'''

html4 = '''\
%s
<body>
<h1>iNaturalist observations sorted by date</h1>
<h2>%s</h2>
%s
<ul>
%s
</ul>
</body>
''' % (html3, counts2, hlist2, toc)
    
html5 = '''\
%s
<body>
<h1>iNaturalist observations sorted by name</h1>
<h2>%s</h2>
%s
<ul>
%s
</ul>
</body>
''' % (html3, counts2, hlist3, toc)
    
html6 = '''\
%s
<body>
<h1>iNaturalist observations sorted by name</h1>
<h2>%s</h2>
%s
</body>
''' % (html3, counts2, hlist4)
    

with open(out1, 'w', encoding='utf-8') as out:  out.write(html4)
with open(out2, 'w', encoding='utf-8') as out:  out.write(html5)
with open(out3, 'w', encoding='utf-8') as out:  out.write(html6)
with open(out4, 'w', encoding='utf-8') as out:  out.write(tlist)

        
