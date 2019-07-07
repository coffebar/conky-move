#!/bin/bash
CONKY_CONFIG_FILE="$HOME/.conkyrc"

# absolute path this script 
SCRIPT=$(readlink -f "$0")
# directory
SCRIPT_DIR=`dirname "$SCRIPT"`

# check window positions every .. secons
INTERVAL_SEC=60

DEBUG_ON=''

if [[ ! -f "$CONKY_CONFIG_FILE" ]]; then
    echo "Fatal error!"
    echo "File $CONKY_CONFIG_FILE not found."
    echo "Please change option CONKY_CONFIG_FILE in this script."
    exit -1
fi

if [[ "$1" == "add" ]]; then
    readarray windows <<< $( wmctrl -l -G | grep conky )
    for i in "${!windows[@]}"
    do
        readarray -d ' ' window <<< $( echo ${windows[i]} | tr -s ' ' )
        win_wm_class_is_conky=$( xprop -id ${window[0]} WM_CLASS | grep '= "conky"' )    
        if [[ ${win_wm_class_is_conky} ]]; then
            x=${window[2]}
            y=${window[3]}
            width=${window[4]}
            height=${window[5]}
            # get option gap_x from config file
            gap_x=$( grep -P '^gap_x=(.+),' $CONKY_CONFIG_FILE | grep -oP '\-?\d+' )
            output=$( echo "$gap_x,$x,$y,$width,$height" | sed 's/ //g' )
            echo $output >> "$SCRIPT_DIR/gap_x"
            echo $output
            exit 0
        fi
    done

    exit -1
elif [[ "$1" == "auto" ]]; then
    if [[ ! -f "$SCRIPT_DIR/gap_x" ]]; then
        echo "No config found!"
        echo "Use 'add' action first."
        exit -1
    fi

    while true
    do

    # get selected workspace number (0, 1, ...)
    workspace_selected=$(wmctrl -d | grep '*' | cut -d ' ' -f1)
    # get window list
    readarray -t windows <<< $( wmctrl -l -G | tr -s ' ' )
    # read config
    readarray -t gap_x_lines <<< $( cat "$SCRIPT_DIR/gap_x" )
    # gap_x to set
    ok_gap=''
    for line_n in "${!gap_x_lines[@]}";
    do
        readarray -t -d ',' geometry <<< ${gap_x_lines[$line_n]}
        conky_gap_x=${geometry[0]}
        #echo "conky_gap_x=$conky_gap_x"
        conky_x=${geometry[1]}
        conky_y=${geometry[2]}
        conky_x2=$(( $conky_x + ${geometry[3]} ))
        conky_y2=$(( $conky_y + ${geometry[4]} ))

        if [[ $DEBUG_ON ]]; then
            echo "conky_x=$conky_x"
            echo "conky_y=$conky_y"
            echo "conky_x2=$conky_x2"
            echo "conky_y2=$conky_y2"
            echo ''
        fi
        overlap=''
        same_here=''

        # loop for each window
        for i in "${!windows[@]}"
        do
            readarray -t -d ' ' window <<< $( echo ${windows[i]} )
            # if this window from current workspace or pinned to all workspaces
            if [[ ${window[1]} == $workspace_selected ]] || [[ ${window[1]} == '-1' ]]; then
                win_xprop=$(xprop -id ${window[0]})                
                state_normal=$( echo ${win_xprop} | grep -o 'window state: Normal' )        
                is_desktop=$( echo ${win_xprop} | grep -o '= _NET_WM_WINDOW_TYPE_DESKTOP' )
                is_conky=$( echo ${win_xprop} | grep 'WM_CLASS(STRING) = "conky"' )

                if [[ ${is_conky} ]]; then
                    x=${window[2]}
                    y=${window[3]}
                    if [[ $conky_x == $x ]] && [[ $conky_y == $y ]]; then
                        # we don't need to move to the position that is already there
                        # skipping this config line
                        same_here="1"
                        continue
                    fi
                fi
 
                # if not minimized and not desktop and not conky
                if [[ ${state_normal} ]] && [[ ! ${is_desktop} ]] && [[ ! ${is_conky} ]]; then
                    x=${window[2]}
                    y=${window[3]}
                    width=${window[4]}
                    height=${window[5]}
                    x2=$(( $x + $width ))
                    y2=$(( $y + $height ))
                                      
                    if (( $conky_x < $x2 && $conky_x2 > $x && $conky_y < $y2 && $conky_y2 > $y )); then
                        if [[ $DEBUG_ON ]]; then
                            echo ''
                            echo 'overlap:'                 
                            echo "'${window[7]}'"
                            echo "x=$x"
                            echo "y=$y"
                            echo "x2=$x2"
                            echo "y2=$y2"
                            echo ''
                        fi
                        overlap="1"
                        # break window loop
                        break
                    fi
                else
                    same_here=""
                fi
            fi
        done

        if [[ $same_here ]] && [[ ! $overlap ]] ; then 
            # fine
            ok_gap="$conky_gap_x"
            break
        elif [[ ! $ok_gap ]] && [[ ! $overlap ]] ; then 
            ok_gap="$conky_gap_x"
        fi
    done 
    current_gap_x=$(grep -P '^gap_x=(.+),' $CONKY_CONFIG_FILE | grep -oP '\-?\d+')
    if [[ $ok_gap ]] && [[ "$ok_gap" != "$current_gap_x" ]]; then 
        # change gap_x to $ok_gap
        if [[ $DEBUG_ON ]]; then
            echo "${current_gap_x} > ${ok_gap}"
        fi
        sed -i "s/gap_x=${current_gap_x},/gap_x=${ok_gap},/" "$CONKY_CONFIG_FILE"
    fi

    sleep $INTERVAL_SEC
    done
else
    if [[ ! `which wmctrl` ]]; then
        echo -e '\v\t\033[0;31mWarning: wmctrl is required!\033[0m'
    fi
    echo ""
    echo "Conky-move - script to automatically move conky to the place not covered by windows"
    echo -e "\v  Config path: $SCRIPT_DIR/gap_x"
    echo -e "\v  Usage: `which bash` $SCRIPT <action>"
    echo -e "\v  Actions:"
    echo -e "  add\t- add current position of conky to config"
    echo -e "  auto\t- move conky using geometry, added to config"
fi
