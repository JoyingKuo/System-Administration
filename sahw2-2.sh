#! usr/bin/sh

processCosData(){

[ -e course.json ] && echo "Data exist" || curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crsname=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**' > course.json

sed -i '' 's/","/ \
/g' course.json

grep -i "cos_time" course.json > cos_time.json
grep -i "cos_ename" course.json > cos_ename.json
paste cos_time.json cos_ename.json > cos_table.json

sed -i '' 's/cos_time":/ /g' cos_table.json
sed -i '' 's/cos_ename":"/ : /g' cos_table.json
sed -i '' 's/$/" off/' cos_table.json
sed -i '' 's/\\r//' cos_table.json
awk '{printf("f%d %s\n", NR, $0)}' cos_table.json> cos_table.tmp && mv -f cos_table.tmp course.json
rm -f cos_time.json cos_ename.json cos_table.json


}

selectCourse(){
dialog --buildlist "Add Class" 50 200 30 --file course.json 2>temp.json

value=`cat temp.json`
#echo $value
result=$?
if [ -e selected_cos.txt ]; then	
	truncate -s 0 selected_cos.txt
fi

for word in $value 
do
	content=$( grep -i "$word " course.json )
	echo $content >> selected_cos.txt
done	

handleCollision

}


handleCollision(){

sed -i '' 's/^[A-Za-z0-9_]* "//' selected_cos.txt
sed -i '' 's/" off//g' selected_cos.txt
sed -i '' 's/" on//g' selected_cos.txt

if [ -e collision_cos.txt ]; then	
	truncate -s 0 collision_cos.txt
fi
for i in 1 2 3 4 5 6 7
do
	for j in M N A B C D X E F G H Y I J K L
	do
		
		yoyo=$(grep -i "$i""[A-Z]*""$j" selected_cos.txt)
		yaya=$(grep -i "$yoyo" collision_cos.txt )
		duplicate_line=$(echo -n "$yoyo" | wc -l| xargs echo )
		dup_in_yaya=$(echo -n "$yaya" | wc -l| xargs echo)
	        
		if [ $dup_in_yaya -eq 0 ] && [ $duplicate_line -gt 0 ];then
			echo "$yoyo" >> collision_cos.txt
			echo "" >> collision_cos.txt
		elif [ $duplicate_line -gt $dup_in_yaya ];then
			echo "$yoyo" >> collision_cos.txt
			echo "" >> collision_cos.txt
		fi
	done

done
#sed -i '' '/^\s*$/d' collision_cos.txt 去掉空白行
#sort -u collision_cos.txt > collision_cos.tmp && mv -f collision_cos.tmp collision_cos.txt
sed -i '' 's/-[A-Za-z0-9]*//g' collision_cos.txt
#sed -i '' 's/[1-7][A-Z]*/& /g' collision_cos.txt
if [ -e collision_output.txt ]; then	
	truncate -s 0 collision_output.txt
fi
awk ' BEGIN{temp=""; temp_cos="";}{ if(NF==0){printf temp" :"temp_cos"\n\n" ; temp_cos = ""; temp=""; } else if(NF>0){ temp = temp" "$1; for( i=3; i<=NF; i++){temp_cos=temp_cos" "$i}; temp_cos=temp_cos" AND"} } ' collision_cos.txt >> collision_output.txt
sed -i '' 's/....$//' collision_output.txt
sed -i '' 's/[1-7][A-Z]*/& /g' collision_output.txt
sed -i '' 's/,//g' collision_output.txt

if [ -e collision_output2.txt ]; then	
	truncate -s 0 collision_output2.txt
fi
awk ' BEGIN{concate_time="";count = 1; cos_record="";}{ if(NF==0){printf concate_time cos_record"\n" ; count = 1; cos_record=""; concate_time="";} else if(NF>0){ for(i=1 ; $i!=":" ;i++){ for(j=i+1 ; $j!=":"; j++){ concate_time = concate_time$i$j" "; } count++;} for(k = count ; k<=NF ; k++){cos_record = cos_record" "$k}}}' collision_output.txt >> collision_output2.txt


if [ -e final.txt ]; then	
	truncate -s 0 final.txt
fi

while read line
do
	for time in $line
	do
		if [ "$time" == ":" ];then
			#final=$(echo "$concate" | xargs -n1 | sort -u | xargs)
			echo "$concate" | tr '[:space:]' '[\n*]' | grep -v "^\s*$" | sort | uniq -c | sort -bnr >> final.txt
			concate=""
			echo "$line" | cut -d":" -f2 >> final.txt
			echo "" >> final.txt
			break
		fi
		value=$(echo "$time" | grep -o . | sort | uniq -d | tr -d "\n" | grep -i "[0-9][A-Z]")
		charlen=${#value}
		concate=$concate" "$value
	
	done	
done < collision_output2.txt


if [ -e final2.txt ]; then	
	truncate -s 0 final2.txt
fi

awk '{ if(NF==0){max=0; concate="";} if($1 ~ /^[0-9]+$/){if($1 >= max){ max=$1; concate=concate$2" "}}else{print concate"\n"$0}  }' final.txt >> final2.txt

if [ -s final2.txt ];then
	msgbox	
elif [ -s selected_cos.txt ];then  
	cp -f selected_cos.txt class.txt
  	updateCourse
else
	type=`cat option.tmp`
	if [ "$type" == "SE1" ] || [ "$type" == "HC2" ] || [ "$type" == "ES" ] || [ "$type" == "F3" ] || [ "$type" == "G3" ];then
		syllabusShowExtraColumn
	elif [ "$type" == "HC1" ] || [ "$type" == "HE1" ] || [ "$type" == "HA" ] || [ "$type" == "SS" ] || [ "$type" == "F1" ] || [ "$type" == "G1" ];then
		syllabus
	elif [ "$type" == "SC1" ] || [ "$type" == "HE2" ]  || [ "$type" == "CS" ] || [ "$type" == "F2" ] || [ "$type" == "G2" ];then
		syllabusShowClassroom
	elif  [ "$type" == "SC2" ] || [ "$type" == "SE2" ] ||[ "$type" == "SA" ] || [ "$type" == "DS" ] || [ "$type" == "F4" ] || [ "$type" == "G4" ];then
		detailSyllabus
	else
		syllabus
	
	fi


fi
}
msgbox(){
msg=`cat final2.txt`

dialog --title "collision"  --msgbox "$msg" 30 100 
selectCourse

}
updateCourse(){


sed -i '' 's/" on/" off/g' course.json
value=`cat temp.json`
for word in $value 
do
	number=$( grep -n "$word " course.json | cut -d : -f 1 )
	
	sed -i '' "${number}s/\" off/\" on/" course.json
	#content=$( grep -i "$word " course.json )
	#echo $content >> selected_cos.txt
done	

type=`cat option.tmp`
if [ "$type" == "SE1" ] || [ "$type" == "HC2" ] || [ "$type" == "ES" ] || [ "$type" == "F3" ] || [ "$type" == "G3" ];then
	syllabusShowExtraColumn
elif [ "$type" == "HC1" ] || [ "$type" == "HE1" ] || [ "$type" == "HA" ] || [ "$type" == "SS" ] || [ "$type" == "F1" ] || [ "$type" == "G1" ];then
	syllabus
elif [ "$type" == "SC1" ] || [ "$type" == "HE2" ]  || [ "$type" == "CS" ] || [ "$type" == "F2" ] || [ "$type" == "G2" ] ;then
	syllabusShowClassroom
elif  [ "$type" == "SC2" ] || [ "$type" == "SE2" ] || [ "$type" == "SA" ] ||[ "$type" == "DS" ] || [ "$type" == "F4" ] || [ "$type" == "G4" ];then
	detailSyllabus
else
	syllabus
	
fi

}
syllabus(){
	
for i in 1 2 3 4 5
do

	if [ -e $i.txt ]; then	
	truncate -s 0 $i.txt
	fi
	
	case $i in
	1)	
		if [ -e 1_line.txt ]; then	
			truncate -s 0 1_line.txt
		fi
		echo ".Mon          "  >> $i.txt
		echo "xA...=B...=C...=D...=E...=F...=G...=H...=I...=J...=K...=" | fold -w 1 >> 1_line.txt
	;;
	2)
		echo ".Thu          "  >> $i.txt

	;;
	3)
		echo ".Wed          "  >> $i.txt

	;;
	4)
		echo ".The          "  >> $i.txt

	;;
	5)
		if [ -e 5_line.txt ]; then	
			truncate -s 0 5_line.txt
		fi

		echo ".Fri          "  >> $i.txt
		echo " ||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=" | fold -w 1 >> 5_line.txt

	;;
	*)
	;;

	esac

	for j in  A B C D E F G H I J K
	do
		#grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13
	       	
		grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | awk '{printf("|%-13s\n", $0)}' >> $i.txt
		
		line_num=$(grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | wc -l | xargs echo) 
		if [ $line_num -eq 0 ];then
			printf "%-13s\n" "|x." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 1 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 2 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 3 ];then
			printf "%-13s\n" "|." >> $i.txt
		fi

		echo "==============" >> $i.txt

	done
done
paste 1_line.txt 1.txt 2.txt 3.txt 4.txt 5.txt 5_line.txt > syllabus_cat.txt


dialog                                          \
   --title "Syllabus"   --ok-label " Add Class " --cancel-label " Exit " --extra-button --extra-label " Option " --no-collapse                   \
   --yesno "`cat syllabus_cat.txt`"  \
  100 100 

result=$?
echo "$result"
if [ $result -eq  0 ];then
	selectCourse
elif [ $result -eq 3 ];then
	syllabusSelectOption
else
	exit
fi

}

detailSyllabus(){
for i in 1 2 3 4 5 6 7
do

	if [ -e $i.txt ]; then	
	truncate -s 0 $i.txt
	fi
	
	case $i in
	1)	
		if [ -e 1_line.txt ]; then	
			truncate -s 0 1_line.txt
		fi
		echo ".Mon          "  >> $i.txt
		echo "xM....=N....=A....=B....=C....=D....=X....=E....=F....=G....=H....=Y....=I....=J....=K....=L....=" | fold -w 1 >> 1_line.txt
	;;
	2)
		echo ".Thu          "  >> $i.txt
	;;
	3)
		echo ".Wed          "  >> $i.txt
	;;
	4)
		echo ".The          "  >> $i.txt
	;;
	5)
		echo ".Fri          "  >> $i.txt	
	;;
	6)
		echo ".Sat          "  >> $i.txt
	;;
	7)
		if [ -e 7_line.txt ]; then	
			truncate -s 0 7_line.txt
		fi

		echo ".Sun          "  >> $i.txt
		echo " |||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=" | fold -w 1 >> 7_line.txt

	;;
	*)
	;;

	esac

	for j in  M N A B C D X E F G H Y I J K L
	do
		grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | awk '{printf("|%-13s\n", $0)}' >> $i.txt
		line_num=$(grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | wc -l | xargs echo) 
		if [ $line_num -eq 0 ];then
			printf "%-13s\n" "|x." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 1 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 2 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 3 ];then
			printf "%-13s\n" "|." >> $i.txt
		fi
		grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f1 | tr , '\n' | grep -i "$i""[A-Z]*""$j" | cut -d"-" -f2 | awk '{printf("|.%12s\n", $0)}'>> $i.txt 
		echo "==============" >> $i.txt

	done
done
paste 1_line.txt 1.txt 2.txt 3.txt 4.txt 5.txt 6.txt 7.txt 7_line.txt > syllabus_cat.txt


dialog                                          \
   --title "Syllabus with Extra Column"   --ok-label " Add Class " --cancel-label " Exit " --extra-button --extra-label " Option " --no-collapse                   \
   --yesno "`cat syllabus_cat.txt`"  \
  100 130 

result=$?
if [ $result -eq  0 ];then
	selectCourse
elif [ $result -eq 3 ];then
	detailSelectOption
else
	exit
fi


}

detailSelectOption (){

dialog --title "Pick a choice" --menu "Choose one" 12 35 5 \
HC2 "Hide Classroom" HE2 "Hide Extra Column" HA "Hide Both" F4 "Search Class" G4 "Suggest Class" 2>option.tmp 

result=$?
if [ $result -eq 1 ];then
	echo "DS" > option.tmp
	detailSyllabus
else
	option=`cat option.tmp`
	if [ "$option" == "HE2" ];then
		syllabusShowClassroom	
	elif [ "$option" == "HC2" ];then 
		syllabusShowExtraColumn
	elif [ "$option" == "HA" ];then
		syllabus
	elif [ "$option" == "F4" ];then
		SearchClass
	else
		suggestClass
	fi
fi
}



syllabusSelectOption(){
dialog --title "Pick a choice" --menu "Choose one" 12 35 5 \
SC1 "Show Classroom" SE1 "Show Extra Column" SA "Show both" F1 "Search Class" G1 "Suggest Class" 2>option.tmp 

result=$?
if [ $result -eq 1 ];then
	echo "S" > option.tmp
	syllabus
else
	option=`cat option.tmp`
	if [ "$option" == "SC1" ];then
		syllabusShowClassroom
	elif [ "$option" == "SE1" ];then
		syllabusShowExtraColumn
	elif [ "$option" == "SA" ];then 
		detailSyllabus
	elif  [ "$option" == "F1" ];then
		SearchClass
	else
		suggestClass	
	fi
fi

}

syllabusShowClassroom(){
for i in 1 2 3 4 5
do

	if [ -e $i.txt ]; then	
	truncate -s 0 $i.txt
	fi
	
	case $i in
	1)	
		if [ -e 1_line.txt ]; then	
			truncate -s 0 1_line.txt
		fi
		echo ".Mon          "  >> $i.txt
		echo "xA....=B....=C....=D....=E....=F....=G....=H....=I....=J....=K....=" | fold -w 1 >> 1_line.txt
	;;
	2)
		echo ".Thu          "  >> $i.txt

	;;
	3)
		echo ".Wed          "  >> $i.txt

	;;
	4)
		echo ".The          "  >> $i.txt

	;;
	5)
		if [ -e 5_line.txt ]; then	
			truncate -s 0 5_line.txt
		fi

		echo ".Fri          "  >> $i.txt
		echo " |||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=|||||=||||||=" | fold -w 1 >> 5_line.txt

	;;
	*)
	;;

	esac

	for j in  A B C D E F G H I J K
	do
		
		grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | awk '{printf("|%-13s\n", $0)}' >> $i.txt
		line_num=$(grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | wc -l | xargs echo) 
		if [ $line_num -eq 0 ];then
			printf "%-13s\n" "|x." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt	
		elif [ $line_num -eq 1 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 2 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 3 ];then
			printf "%-13s\n" "|." >> $i.txt 
		fi
		grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f1 | tr , '\n' | grep -i "$i""[A-Z]*""$j" | cut -d"-" -f2 | awk '{printf("|.%12s\n", $0)}'>> $i.txt 

		echo "==============" >> $i.txt

	done
done
paste 1_line.txt 1.txt 2.txt 3.txt 4.txt 5.txt 5_line.txt > syllabus_cat.txt


dialog                                          \
   --title "Syllabus"   --ok-label " Add Class " --cancel-label " Exit " --extra-button --extra-label " Option " --no-collapse                   \
   --yesno "`cat syllabus_cat.txt`"  \
  100 100 

result=$?
if [ $result -eq  0 ];then
	selectCourse
elif [ $result -eq 3 ];then
	ClassroomSelectOption
else
	exit
fi

}
ClassroomSelectOption(){
dialog --title "Pick a choice" --menu "Choose one" 12 35 5 \
 HC1 "Hide Classroom" SE2 "Show Extra Column" F2 "Search Class" G2 "Suggest Class" 2>option.tmp 

result=$?
if [ $result -eq 1 ];then
	echo "CS" > option.tmp
	syllabusShowClassroom
else
	option=`cat option.tmp`
	if [ "$option" == "HC1" ];then
		syllabus
	elif [ "$option" == "SE2" ];then
		detailSyllabus
	elif  [ "$option" == "F2" ];then
		SearchClass
	else
		suggestClass
	fi
fi

}
syllabusShowExtraColumn(){
for i in 1 2 3 4 5 6 7
do

	if [ -e $i.txt ]; then	
	truncate -s 0 $i.txt
	fi
	
	case $i in
	1)	
		if [ -e 1_line.txt ]; then	
			truncate -s 0 1_line.txt
		fi
		echo ".Mon          "  >> $i.txt
		echo "xM...=N...=A...=B...=C...=D...=X...=E...=F...=G...=H...=Y...=I...=J...=K...=L...=" | fold -w 1 >> 1_line.txt
	;;
	2)
		echo ".Thu          "  >> $i.txt

	;;
	3)
		echo ".Wed          "  >> $i.txt

	;;
	4)
		echo ".The          "  >> $i.txt

	;;
	5)
		
		echo ".Fri          "  >> $i.txt
		
	;;
	6)
		echo ".Sat          "  >> $i.txt
	;;
	7)
		if [ -e 7_line.txt ]; then	
			truncate -s 0 7_line.txt
		fi

		echo ".Sun          "  >> $i.txt
		echo " ||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=||||=" | fold -w 1 >> 7_line.txt

	;;
	*)
	;;

	esac

	for j in  M N A B C D X E F G H Y I J K L
	do
		#grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13
	       	if [ $i -eq 7 ];then
			grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | awk '{printf("|%-13s\n", $0)}' >> $i.txt
		else		
			grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | awk '{printf("|%-13s\n", $0)}' >> $i.txt
		fi
		line_num=$(grep -i "$i""[A-Z]*""$j" class.txt | cut -d":" -f2 | fold -w 13 | wc -l | xargs echo) 
		if [ $line_num -eq 0 ];then
			printf "%-13s\n" "|x." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 1 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 2 ];then
			printf "%-13s\n" "|." >> $i.txt
			printf "%-13s\n" "|." >> $i.txt
		elif [ $line_num -eq 3 ];then
			printf "%-13s\n" "|." >> $i.txt
		fi

		echo "==============" >> $i.txt

	done
done
paste 1_line.txt 1.txt 2.txt 3.txt 4.txt 5.txt 6.txt 7.txt 7_line.txt > syllabus_cat.txt


dialog                                          \
   --title "Syllabus with Extra Column"   --ok-label " Add Class " --cancel-label " Exit " --extra-button --extra-label " Option " --no-collapse                   \
   --yesno "`cat syllabus_cat.txt`"  \
  100 130 

result=$?
if [ $result -eq  0 ];then
	selectCourse
elif [ $result -eq 3 ];then
	ExtraColumnSelectOption
else
	exit
fi

}
ExtraColumnSelectOption(){
dialog --title "Pick a choice" --menu "Choose one" 12 35 5 \
 SC2 "Show Classroom" HE1 "Hide Extra Column" F3 "Search Class" G3 "Suggest Class" 2>option.tmp 

result=$?
if [ $result -eq 1 ];then
	echo "ES" > option.tmp
	syllabusShowExtraColumn
else
	option=`cat option.tmp`
	if [ "$option" == "SC2" ];then
		detailSyllabus
	elif [ "$option" == "HE1" ];then
		syllabus
	elif  [ "$option" == "F3" ];then
		SearchClass
	else
		suggestClass
	fi
fi


}
suggestClass(){
cp course.json suggest.txt
if [ -s time ];then
	truncate -s 0 time
fi
#cat class.txt | cut -d":" -f1 | tr , '\n' | cut -d"-" -f1 | sed 's/[1-7][A-Z]*/&,/g' | tr , '\n' | awk '{ print length, $0 }' | sort -nr | cut -d" " -f2- |cut -c1,2 | sed '/^\s*$/d' >> time 
cat class.txt | cut -d":" -f1 | tr , '\n' | cut -d"-" -f1 | sed 's/[1-7][A-Z]*/&,/g' | tr , '\n' |cut -c1,2 | sed '/^\s*$/d' >> time 
cat class.txt | cut -d":" -f1 | tr , '\n' | cut -d"-" -f1 | sed 's/[1-7][A-Z]*/&,/g' | tr , '\n' |cut -c1,3 | sed '/^\s*$/d' >> time
cat class.txt | cut -d":" -f1 | tr , '\n' | cut -d"-" -f1 | sed 's/[1-7][A-Z]*/&,/g' | tr , '\n' |cut -c1,4 | sed '/^\s*$/d' >> time

while read line
do
	word_num=$(echo "$line" | wc -m | xargs echo)
	if [ $word_num -eq 3 ];then
		grep -v "$line" suggest.txt > suggest.tmp && mv -f suggest.tmp suggest.txt
	fi
	sed -i '' 's/^[A-Za-z0-9_]*  "//' suggest.txt
	sed -i '' 's/" off//g' suggest.txt
	sed -i '' 's/" on//g' suggest.txt
	
done < time

msg=`cat suggest.txt`
dialog --title "Suggest Course"  --msgbox "$msg" 30 100

type=`cat option.tmp`
if  [ "$type" == "G3" ];then
	syllabusShowExtraColumn
elif [ "$type" == "G1" ];then
	syllabus
elif [ "$type" == "G2" ];then
	syllabusShowClassroom
elif [ "$type" == "G4" ];then
	detailSyllabus
else
	syllabus
	
fi

}

SearchClass(){
dialog                                          \
   --title 'Search for class'                   \
   --inputbox 'Enter the key word or time '  \
   0 0  2>input.txt

if [ -s search_class_output.txt ]; then	
	truncate -s 0 search_class_output.txt
fi 

if [ -s input.txt ];then
	key_word=`cat input.txt`
	grep -i "$key_word" course.json >> search_class_output.txt
	sed -i '' 's/^[A-Za-z0-9_]*  "//' search_class_output.txt
	sed -i '' 's/" off//g' search_class_output.txt 
	sed -i '' 's/" on//g' search_class_output.txt
	sed -i '' '/^\s*$/d' input.txt 

fi

if [ -s search_class_output.txt ] ;then
	msg=`cat search_class_output.txt`
	dialog --title "match Course"  --msgbox "$msg" 30 100
else
	dialog --title "match Course"  --msgbox "NO COURSE MATCH" 30 100

fi

type=`cat option.tmp`
if  [ "$type" == "F3" ];then
	syllabusShowExtraColumn
elif [ "$type" == "F1" ];then
	syllabus
elif [ "$type" == "F2" ];then
	syllabusShowClassroom
elif [ "$type" == "F4" ];then
	detailSyllabus
else
	syllabus
	
fi

}


[ -e course.json ] && echo "Data exist" || processCosData
syllabus
#suggestClass

