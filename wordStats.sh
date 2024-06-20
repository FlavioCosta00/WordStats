#!/usr/bin/env bash

#Global Variables

MODE=$1 #Cc|Pp|Tt
INPUT=$2  
ISO3166=$3
STOP_WORDS_FILE=""

#Functions

func_INPUT(){
	if [[ -e "$INPUT" ]];then
    		local TYPE="$(file -b --mime-type $INPUT)"
    		if [[ "$TYPE" == "application/pdf" ]];then
        		echo "'$INPUT': PDF file"
        		echo "[INFO] Processing '$INPUT'"
				pdftotext $INPUT $INPUT.txt
				INPUT="$INPUT.txt"
    		elif [[ "$TYPE" == "text/plain" ]];then
        		echo "'$INPUT': TXT file"
        		echo "[INFO] Processing '$INPUT'"
    		else
       			echo "[ERROR] incompatible file type"
       			exit
    		fi
	else
    	echo "[ERROR] can't find file '$INPUT'"
    	exit
    exit
fi
}

func_ISO3166(){
    echo "STOP WORDS will be filtered out"
    if [[ "$ISO3166" == "en" ]];then
        STOP_WORDS_FILE="en.stop_words.txt"
    elif [[ $ISO3166 == "pt" ]]; then
        STOP_WORDS_FILE="pt.stop_words.txt"                
    else
        ISO3166="en"
        STOP_WORDS_FILE="en.stop_words.txt"
    fi
    local WORDS="$(wc -w $STOP_WORDS_FILE)"
    echo "StopWords file '$ISO3166': '$STOP_WORDS_FILE' (${WORDS% *} words)"
}

func_top_words(){ 
	if [[ -z "$WORD_STATS_TOP" ]]; then
		echo "Environment variable 'WORD_STATS_TOP' is empty (using default 10)"
		WORD_STATS_TOP="10"
	elif ! [[ "$WORD_STATS_TOP" =~ ^[0-9]+$ ]]; then
		echo "'$WORD_STATS_TOP' not a number (using default 10)"
		WORD_STATS_TOP="10"
	else
		echo "WORD_STATS_TOP=$WORD_STATS_TOP"
	fi
}

func_Pp(){
	
	gnuplot << graph
	set terminal png
	set output "result---$INPUT.png"
	set boxwidth 0.4 relative
	set size 1, 1
	set grid x y
	set style textbox opaque border lc "black"
	set term png size 750, 750
	set title "Graphic"
	set xlabel "words"
	set linetype 1 lc rgb "dark-red" 
	set ylabel "number of occurrences" 
	set style fill solid
	plot "result---$INPUT.dat" using 1:2:xtic(3) t "# of occurrences" with boxes, "result---$INPUT.dat" using 1:2:2 t "" with labels center boxed
graph
	

	cat > result---$INPUT.html << EOF

	<!DOCTYPE html>	
	<html>
	<head>
	<title>Gráfico</title>
	</head>
	<body>
	<center>
	<img src="result---$INPUT.png" alt="graphic" width="750" height="750">
	</center>
	</body>
	</html>

EOF

ls -l result---$INPUT.dat
ls -l result---$INPUT.png 
ls -l result---$INPUT.html

display result---$INPUT.png

}

#Main

if [[ -n "$MODE" && -n "$INPUT" ]];then

	if  [[ "$MODE" == "c" ]];then
		func_INPUT
		func_ISO3166
		echo "COUNT MODE"
		grep -oE '[[:alpha:]]+' $INPUT | grep -vwFf $STOP_WORDS_FILE | sort | uniq -c | sort -nr | awk '{print NR, $0}' | cat > result---$INPUT
		echo "RESULTS: 'result---$INPUT'"
		ls -l result---$INPUT
		DISTINCT_WORDS="$(wc -w result---$INPUT)"
		echo "$((${DISTINCT_WORDS% *}/3)) distinct words"
	elif [[ "$MODE" == "C" ]];then
		func_INPUT
		echo "STOP WORDS will be counted"
		echo "COUNT MODE"
		grep -oE '[[:alpha:]]+' $INPUT | sort | uniq -c | sort -nr | awk '{print NR, $0}' | cat > result---$INPUT
		echo "RESULTS: 'result---$INPUT'"
		ls -l result---"$INPUT"
		DISTINCT_WORDS="$(wc -w result---$INPUT)"
		echo "$((${DISTINCT_WORDS% *}/3)) distinct words"
	elif [[ "$MODE" == "p" ]];then
		func_INPUT
		func_ISO3166
		func_top_words
		grep -oE '[[:alpha:]]+' $INPUT | grep -vwFf $STOP_WORDS_FILE | sort | uniq -c | sort -nr | sed -n 1,"$WORD_STATS_TOP"p | awk '{print NR, $0}' | cat > result---$INPUT.dat
		func_Pp
	elif [[ "$MODE" == "P" ]];then
		func_INPUT
		echo "STOP WORDS will be counted"
		func_top_words
		grep -oE '[[:alpha:]]+' $INPUT | sort | uniq -c | sort -nr | sed -n 1,"$WORD_STATS_TOP"p | awk '{print NR, $0}' | cat > result---$INPUT.dat
		func_Pp
	elif [[ "$MODE" == "t" ]];then
		func_INPUT
		func_ISO3166
		func_top_words
		echo "# TOP $WORD_STATS_TOP elements"
		grep -oE '[[:alpha:]]+' $INPUT | grep -vwFf $STOP_WORDS_FILE | sort | uniq -c | sort -nr | awk '{print NR, $0}' | sed -n 1,"$WORD_STATS_TOP"p | tee result---$INPUT
		ls -l result---"$INPUT" 
	elif [[ "$MODE" == "T" ]];then
		func_INPUT
		echo "STOP WORDS will be counted"
		func_top_words
		echo "# TOP $WORD_STATS_TOP elements"
		grep -oE '[[:alpha:]]+' $INPUT | sort | uniq -c | sort -nr | awk '{print NR, $0}' | sed -n 1,"$WORD_STATS_TOP"p | tee result---$INPUT
		ls -l result---"$INPUT"
	else
		echo "[ERROR] unknown command '$MODE'"
		exit
	fi

else
	echo "[ERROR] insufficient parameters"
	echo "./word_stats.sh Cc|Pp|Tt INPUT [iso3166]"
fi
