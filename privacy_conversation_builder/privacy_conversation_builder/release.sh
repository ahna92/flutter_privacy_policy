osName="$(uname -s)"
input="index.html"
lineCounter=0

#flutter build web

cd build/web
#grep echo $a | '<pre>(.*?)</pre>' $input
# READ CONFIG FILE
while IFS= read -r line; do
  lineCounter=$((lineCounter + 1))

  if [[ "$line" == *script*src=\"main.dart.js* ]]; then
#    s='<some text> from=someuser@somedomain.com, <some text>'
#    por="$(grep -oP '(?<=from=).*?(?=,)' <<< "$s")"
#    totalVersion="$(cut -d'src' -f1 <<<"$line")"
#    US/Central - 10:26 PM (CST)
    ddd=$( echo $line |
         sed 's/<script src="\([^"]+\)".*/\1/p')

    echo $ddd
    break
  fi

done <"$input"