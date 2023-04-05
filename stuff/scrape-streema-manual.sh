#!/bin/bash

# find main-genres and regions
curl -s https://streema.com/radios | htmlq -a href a | grep "/main-genre/" | cut -c20- > main-genres.txt
curl -s https://streema.com/radios | htmlq -a href a | grep "/region/" | cut -c16- > region.txt

# find sub-genres and countries
for i in $(cat main-genre.txt) ; do curl -s https://streema.com/radios/main-genre/$i | htmlq -a href a | grep "/genre/" | cut -c15- >> sub-genres.txt ; done
for i in $(cat region.txt) ; do curl -s https://streema.com/radios/region/$i | htmlq -a href a | grep "/country/" >> countries.txt ; done

# find the stream page for sub-genres and countries
for i in "" \?page={2..10} ; do for j in $(cat sub-genres.txt) ; do curl -s https://streema.com/radios/genre/$j$i | htmlq -a href a | grep "/radios/" | grep -v "/social/\|page=\|genre/" | cut -c9- >> A-$j.txt ; echo -e "$j - $i" ; done ; done
for i in "" \?page={2..10} ; do for j in $(cat countries.txt) ; do curl -s https://streema.com/radios/country/$j$i | htmlq -a href a | grep "/radios/" | grep -v "/social/\|page=\|country/" | cut -c9- >> A-$j.txt ; echo -e "$j - $i" ; done ; done

# scarpe the streams from each page
for i in A-*.txt ; do for j in $(cat $i) ; do curl -s http://streema.com/radios/play/$j | grep "data-src=" | awk -F "'" '{print $2}' | sed 's/https:\/\/stream.streema.com\/?url=//g' | sed 's/\;//g' | grep -v "<div id" | sed '/^$/d' >> A$i ; echo -e "$i - $j" ; done ; done

# remove possible duplicates in streams
for i in AA-*.txt ; do cat $i | awk '!seen[$0]++' > A$i ; echo -e $i ; done

# convert links to m3u streams
for i in AAA-*.txt ; do sed "s/^/#EXTINF:-1\n/" $i | sed '1s/^/#EXTM3U\n/' > $i.m3u ; done

# remove AAA- and double extensions in streams
for i in *.m3u ; do mv "$i" "`echo $i | sed -e 's/AAA-//' -e 's/.txt//'`" ; done

# remove temp and empty files 
rm main-genres.txt region.txt sub-genres.txt countries.txt
find . -type f -empty -delete

# move stream to git folder
mv *.m3u c:/git/m3u-radio-music-playlists/streema/

# add, commit and push
git -C c:/git/m3u-radio-music-playlists/ add .
git -C c:/git/m3u-radio-music-playlists/ commit -m "`date +'%b/%d - %I:%M %p'`"
git -C c:/git/m3u-radio-music-playlists/ push
