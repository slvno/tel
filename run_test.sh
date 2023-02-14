#!/bin/bash

#_DEBUG="on"
_DEBUG="off"
function DEBUG()
{
 [ "$_DEBUG" == "on" ] &&  $@
}
 
DEBUG set -x
DEBUG set -v
DEBUG echo 'Reading files'

#VIRTUAL_ENV=/c/work/yandex/validation_tel_number
if [[ ! -v VIRTUAL_ENV ]]; then
    echo "VIRTUAL_ENV is not set"
    source ./bin/activate
elif [[ -z "$VIRTUAL_ENV" ]]; then
    echo "VIRTUAL_ENV is set to the empty string"
    source ./bin/activate
else
    echo "VIRTUAL_ENV has the value: $VIRTUAL_ENV"
fi

python "./source.py" &
sleep 1

_print_total_runtime="on"
#_print_total_runtime="off"
function print_total_runtime()
{
[ "$_print_total_runtime" == "on" ] && "$@"
}

print_execution_time()
{
  local res1="$1"
  local res2="$2"

  local res1_time=$(echo "$res1" | sed -n "s/^\(.*\)\.\([^\.]*\)$/\1/p")
  local res1_time_ns=$(echo "$res1" | sed -n "s/^\(.*\)\.\([^\.]*\)$/\2/p")
  local res1_time_ns=$(echo "$res1_time_ns" | sed -n "s/^\(0*\)\(.*\)$/\2/p")
		
  local res2_time=$(echo "$res2" | sed -n "s/^\(.*\)\.\([^\.]*\)$/\1/p")
  local res2_time_ns=$(echo "$res2" | sed -n "s/^\(.*\)\.\([^\.]*\)$/\2/p")
  local res2_time_ns=$(echo "$res2_time_ns" | sed -n "s/^\(0*\)\(.*\)$/\2/p")

  local d_time=$((res2_time-res1_time))
  local d_time_ns=$((res2_time_ns-res1_time_ns))

  if ((d_time_ns < 0)) ; then
    ((d_time_ns=1000000000+d_time_ns))
	((d_time-=1))
  fi 

  # всего наносекунд
  local dns=$((d_time_ns))
			
  # наносекунды
  dnanos=$((dns%1000))
  # всего микросекунд
  dns=$(((dns-dnanos)/1000))

  # микросекунды
  dmikros=$((dns/1000))
  # всего миллисекунд
  dns=$(((dns-dmikros)/1000))

  # миллисекунд
  dmillis=$((dns))			

  # время в секундах
  dt=$((d_time))

  # секунды
  ds=$((dt%60))
  # время в минутах
  dt=$(((dt-ds)/60))

  # минуты
  dm=$((dt%60))
  # время в часах
  dt=$(((dt-dm)/60))

  # часы
  dh=$((dt%24))
  # время в днях
  dt=$(((dt-dh)/24))

  # дни
  dd=$dt
						
  #LC_NUMERIC=C 
			
  printf "\nTotal runtime:\n %02d days\n %02d hours\n %02d minutes\n %02d seconds\n %03d milliseconds\n %03d mikroseconds\n %03d nanoseconds\n\n" $dd $dh $dm $ds $dmillis $dmikros $dnanos
}

get_test_files()
{   
   #test_case_files
   
   #for f in $test_case_files; do 
   #     echo "$f"
   #done

  find . -name "$1"|sort -n
}

all_word=($(get_test_files "*.txt"))
count=$(printf "%s\n" $all_word | wc -l)

#echo "$count $all_word"

((i=0))
#for (( i = 0; i < $count; i++ )); do
	#statements
	#gedit "$all_word[i]" &
#done


test_program="test_get_url.py"
echo -e "Testing program $test_program\n"

touch error_tests.log
echo -n > error_tests.log
touch ok_tests.log
echo -n  > ok_tests.log
touch skip_tests.log
echo -n  > skip_tests.log

error_tests_count=
((error_tests_count=0))
ok_tests_count=
((ok_tests_count=0))
skip_tests_count=
((skip_tests_count=0))


for s in "${all_word[@]}"; do

    ((i+=1))
    echo "$i: Open test file $s" 
	#gedit "$s" &

	if [[ ${s:2} =~ .*[\\/].* ]] ; then
	    # echo "Found \ or / in ${s:2} file"
		echo "$i: Skip test file $s"
	  echo "$s" >> skip_tests.log
    ((skip_tests_count++))
	else
	    # echo "Not found \ or / in ${s:2} file"
				

		file_result_expected=$(echo "$s" | sed -n "s/^\(.*\)\.[^\.]*$/\1/p")

# -n      suppress printing
# s       substitute
# ^.*     anything at the beginning
# -       up until the dash
# \s*     any space characters (any whitespace character)
# \(      start capture group
# \S*     any non-space characters
# \)      end capture group
# .*$     anything at the end
# \1      substitute 1st capture group for everything on line
# p       print it


		file_result_expected="${file_result_expected}.result"

		if [ -f $test_program ] 
		then
		    res1=$(date +%s.%N)

			time result=$(cat $s | python $test_program \
			#&& sleep 2
			)

            res2=$(date +%s.%N)

			print_total_runtime echo -e "$(print_execution_time "$res1" "$res2")\n"

			if [ -f $file_result_expected ] ; then
    			result_expected=$(cat "${file_result_expected}")

	    		[ "$result" = "$result_expected" ] && (echo "$i: Run test file $s, resuit is $result - $(if ((ds >= 2)); then echo ' BAD time'; echo "$s" >> error_tests.log;else echo ' OK'; echo "$s" >> ok_tests.log; fi)"; )

		    	( ! [ "$result" = "$result_expected" ] ) && (echo "$i: Run test file $s, resuit='${result}' expected result is '$result_expected' - BAD result"; echo "$s" >> error_tests.log;)
		# elif [ $? -eq 0 ]; then
		#else
            #echo "$i: Skip test file $s"
	    #fi
		    else

			    echo "$i: Run test file $s, resuit is $result - $(if ((ds >= 2)); then echo ' BAD time'; echo "$s" >> error_tests.log; else echo ' OK'; echo "$s" >> ok_tests.log; fi)"


				echo "Expected result not found, create file ${file_result_expected} with expected result"
				echo "$result" > ${file_result_expected}
		    fi

		else
		    echo "$i: Not test file $s or expected test result file $file_result_expected or test program $test_program is not found " 

		fi
	fi
	echo "" 
done


printf "Skip %s tests:\n%s\n\n" "${skip_tests_count}" "$(cat skip_tests.log)"
printf "Ok %s tests:\n%s\n\n" "$(cat ok_tests.log|wc -l)" "$(cat ok_tests.log)"
printf "Error %s tests:\n%s\n\n" "$(cat error_tests.log|wc -l)" "$(cat error_tests.log)"

if (( (($(cat error_tests.log|wc -l)))==0)) ; then echo "All tests - OK!"; else echo "Found errors :("; fi

DEBUG set +x
DEBUG set +v

#for f in $(get_test_files "*.txt"); do 
#        echo "$f"
#done

fn_exists() { declare -F "$1" > /dev/null; }

$(fn_exists deactivate) && echo "run deactivate - $(deactivate)" || echo "function deactivate ${deactivate} - not exists"
