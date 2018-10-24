ls -ARl | sort -rnk 5 | awk 'BEGIN { dirNum = 0; fileNum = 0; totalSize = 0 ;} {if(NR <= 5) { printf NR ":" $5 " "; for(i = 9;i <= NF;i++){printf " " $i }; printf "\n"}; if(NF >= 9 && $1 ~ /^-/){ fileNum ++ ; totalSize += $5} else if(NF >= 9 && $1 ~ /^d/){dirNum ++}; }END{printf "Dir num" ": " dirNum "\n" "File num" ": " fileNum "\n" "Total" ": " totalSize "\n"}'