#!/bin/bash

## Variables generales
DirectorioPrincipal="."
FicheroPrincipal="/tmp/partidos_$(date +%Y%m%d).tmp"
FicheroLetras="files/cambioletras.txt"
FicheroCompeticiones="files/competiciones.txt"
URL="https://widgets.futbolenlatv.com/partidos/hoy"

## Variables Telegram
TokenTG=$(cat .env | grep "TELEGRAM_TOKEN" | awk -F"=" '{print $2}')
IDTG=$(cat .env | grep "TELEGRAM_ID" | awk -F"=" '{print $2}')
Icono="⚽"

function telegram {
        URLTG1="https://api.telegram.org/bot$TokenTG/sendMessage?parse_mode=html&disable_web_page_preview=True"
        curl -s -X POST $URLTG1 -d chat_id=$IDTG -d text="Hora: $Hora %0ACompetición: $Torneo $Icono %0APartido: $Partido %0ACanal: $Canal" >/dev/null
}

curl -s $URL | iconv -f ISO-8859-1 -t UTF-8 | grep -A 16 "class=\"p\"" > $FicheroPrincipal
LastLine=$(cat $FicheroPrincipal | wc -l)

IFS=$'\n'
for Sustitucion in $(cat $DirectorioPrincipal/$FicheroLetras)
do
        Error=$(echo $Sustitucion | awk -F" " '{print $1}')
        Letra=$(echo $Sustitucion | awk -F" " '{print $2}')
        sed -i "s/$Error/$Letra/g" $FicheroPrincipal
done

Contador=0
while [ $Contador -lt $LastLine ]
do
        Hora=$(sed -n $((2+$Contador))p $FicheroPrincipal | awk -F">" '{print $NF}')
        Competicion=$(sed -n $((4+$Contador))p $FicheroPrincipal | awk -F">" '{print $2}' | awk -F"<" '{print $1}')
        Partido=$(sed -n $((10+$Contador))p $FicheroPrincipal)
        Canal=$(sed -n $((13+$Contador))p $FicheroPrincipal | sed 's/^[[:space:]]*//')
        for ListaCompeticion in $(cat $DirectorioPrincipal/$FicheroCompeticiones)
        do
                Torneo=$(echo $ListaCompeticion | awk -F":" '{print $1}')
                Icono=$(echo $ListaCompeticion | awk -F":" '{print $2}')
                PrincipioHora=$(echo $Hora | awk -F":" '{print $1}')
                if [[ $PrincipioHora -ge 8 ]] && [[ $Competicion == $Torneo ]]
                then
                        telegram
                        echo "Hora: $Hora %0ACompetición: $Torneo $Icono %0APartido: $Partido %0ACanal: $Canal"
                fi
        done
        let Contador=Contador+18
done