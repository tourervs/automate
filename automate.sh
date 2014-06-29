#!/bin/bash
#
# Run remote bash commands through sudo or not via ssh and printing color report
# author: sendmailwith@gmail.com
#

##
## Setting variables
##
SERVER_LST_FILE=""
COMMAND_FILE=""
SCRIPT_FILE=""
CRED_LINE=""
##
##
##




RUNNING_EXAMPLE_1=" \e[0;34mExample 1 : \n\t \e[1;36mautomate.sh -l server_list.txt -c commands.txt\e[00m\n\t\e[1;36m server_list.txt\e[00m \e[0;34m- Should contain servers hostnames \e[00m\n\t \e[1;36mcommands.txt\e[00m \e[0;34m- simple command list without '#!/bin/bash' at the top\e[00m\e[00m"
RUNNING_EXAMPLE_2=" \e[0;34mExample 2 : \n\t \e[1;36mautomate.sh -l server_list.txt -s script.sh\e[00m\n\t\e[1;36m server_list.txt\e[00m \e[0;34m- Should contain servers hostnames \e[00m\n\t \e[1;36mscript.sh\e[00m \e[0;34m- path to script with single-line commands . \e[0;31m!!! set bash as shell for remote user on remote mashine !!! \e[00m \e[00m\e[00m"
##
## Check keys of command
##

FIRST_KEY=$1
SECOND_KEY=$3
NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE=""
KEY_WARNING_MESSAGE1="\n\e[0;34mPlease specify correct key . Following keys is avilable  :\e[00m \n\e[1;36m-s\e[00m\t\e[0;34m#Then provide path to script\e[00m\n\e[1;36m-c\e[00m\t\e[0;34m#Then provide path to command file\e[00m\n\e[1;36m-l\e[00m\t\e[0;34m#Then provide path to server list\n   \e[00m\n"$RUNNING_EXAMPLE_1"\n"$RUNNING_EXAMPLE_2
KEY_WARNING_MESSAGE2="\e[33mError. Server list key not specified .\e[00m"
KEY_WARNING_MESSAGE3="\e[33mError. Command file key OR Script key  not specified .\e[00m"

case $FIRST_KEY in
        -l) SERVER_LST_FILE=$2  ;;
        -s) SCRIPT_FILE=$2 ; NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE=$SCRIPT_FILE   ;;
        -c) COMMAND_FILE=$2 ; NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE=$COMMAND_FILE   ;;
        *) echo -e $KEY_WARNING_MESSAGE1 ; exit 1  ;;  esac ;

case $SECOND_KEY in
        -l) SERVER_LST_FILE=$4  ;;
        -s) SCRIPT_FILE=$4 ; NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE=$SCRIPT_FILE  ;;
        -c) COMMAND_FILE=$4 ; NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE=$COMMAND_FILE  ;;
        *) echo -e $KEY_WARNING_MESSAGE1 ; exit 1  ;;  esac ;

case $FIRST_KEY$SECOND_KEY in
        -s-c) echo -e  $KEY_WARNING_MESSAGE2 $KEY_WARNING_MESSAGE1 ; exit 1 ;;
        -c-s) echo -e  $KEY_WARNING_MESSAGE2 $KEY_WARNING_MESSAGE1 ; exit 1  ;;
        -l) echo -e  $KEY_WARNING_MESSAGE3 $KEY_WARNING_MESSAGE1 ; exit 1   ;; esac ;



##
##Check server names file
##
if [ -z "$SERVER_LST_FILE" ] ;
        then
                echo -e "\n\e[33mServer list is not specified . Please provide servers list \e[00m\n\t" $RUNNING_EXAMPLE_1"\n\n\t"$RUNNING_EXAMPLE_2;
                exit 0;
        else if [ ! -f $SERVER_LST_FILE ];
                then
                        echo -e  "\n\e[33mServer list file not found !\e[00m\n\t" $RUNNING_EXAMPLE_1"\n\n\t"$RUNNING_EXAMPLE_2;
                        exit 0;
        fi
fi
##
##
##

##
## Check command file
##


if [ -z "$NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE" ] ;
        then
                echo -e "\n\e[33mCommands file or Script file is not specified . Please provide path to command file or script\e[00m\n\t" $RUNNING_EXAMPLE_1 "\n\n\t"$RUNNING_EXAMPLE_2;
        exit 0;
        else if [ ! -f $NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE ];
                then
                        echo -e  "\n\e[33mCommands file or Script file not found !\e[00m\n\t" $RUNNING_EXAMPLE_1"\n\n\t"$RUNNING_EXAMPLE_2;
                exit 0;
        fi
fi
##
##
##



##
## Looking for errors in command file
##
CHECKING_ERRORS=$(bash -n $NAME_OF_COMMAND_FILE_OR_SCRIPT_FILE 2>&1 )
if [ -n "$CHECKING_ERRORS" ] ;
        then
                echo -e "\n\e[33mFollowing mistakes were found in input commands file : \n \e[00m";
        echo "$CHECKING_ERRORS"
        exit 1 ;
fi
##
##
##



##
## Getting credentials
##
function get_credential {
echo -n "enter user name:"
read USER
echo -n "enter password:"
stty -echo
read PW ;  echo
stty echo
#echo "user name is " $USER
if [ -z $USER ] ; then
CRED_LINE="";
else
CRED_LINE=$USER"@"
#####echo $CRED_LINE
fi;





}
get_credential
##
##
##



##
## Checking that expect is installed
##
echo -n  "Checking that expect is installed : "
if [ "$(which expect 2>/dev/null 1>/dev/null ; echo $? )" == '1' ] ;
        then
                echo -e "\e[0;31m[NO]\e[00m";
                echo " Please install expect first ";
        exit ;
        else
                echo -e "\e[0;32m[YES]\e[00m";
        fi
##
##
##


##
## Adding additional headers to each command from COMMAND_FILE . Are you ready for devilry ?
##

if [ ! -z "$COMMAND_FILE" ] ;
then


COMMANDS=$( export CNT=0 ; grep . $COMMAND_FILE | sed "s/[\]/\\\\\\\\\\\\\\\/g"  | sed "s/'/\\\\\\\\\\\'/g" | sed 's/"/\\\\\\\"/g' | sed 's/`/\\\\\\\`/g' | sed 's/[$]/\\\\\\\$/g' |  sed "s/[[]/\\\\\\\\\\\[/g"| sed "s/[]]/\\\\\\\\\\\]/g" | sed 's/[?]/\\\\\\\?/g' | while read command ; do ((CNT+=1)) ; echo -e  ' exec 124>&1 ; exec > /tmp/au_comout_'$CNT' 2>&1  ; \\\$(exit \\\$PREVIOUS_STATUS)  ;  '$command' ; PREVIOUS_STATUS=\\\$?  ; echo \\\$PREVIOUS_STATUS > /tmp/au_result_'$CNT' ;  exec 1>&124 2>&124 124>&- ;  ' ; done)


COMMANDS_CLEAR_OLD_REPORT=`echo " rm -rf /tmp/au_result_* ; rm -rf /tmp/au_comout_*    "`

##
##
##
echo $COMMANDS
fi ;





##
##
##


for server_name in `cat $SERVER_LST_FILE` ; do
    echo
    echo "###    Hostname    ###"
    echo
    echo $server_name
    echo
    SSH_EXIT_STATUS=""


    function script_run {
        SCP=$(echo -e 'spawn scp '$SCRIPT_FILE' '$CRED_LINE$server_name':/tmp/au_'$SCRIPT_FILE' ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]}  \n { \n send_user "Login complete" \n } \n } ' | expect)
  
       

        #
        SSH_EXIT_STATUS=$(echo "$SCP" | grep -i  "Permission denied" 1>/dev/null 2>/dev/null ; echo $?)


        SSH=$(echo -e 'spawn ssh -tt  '$CRED_LINE$server_name' "chmod +x /tmp/au_'$SCRIPT_FILE' ; exec 124>&1 ; exec > /tmp/au_comout_script 2>&1  ; /tmp/au_'$SCRIPT_FILE' ; echo \$?> /tmp/au_result_script ; rm -f /tmp/au_'$SCRIPT_FILE' ; exec 1>&124 2>&124 124>&- " ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]}  \n { \n send_user "Login complete" ;  exp_continue \n } \n "assword for '$USER':" { \n send "'$PW'\\r" ; exp_continue \n } \n } ' | expect )




        LOG_DIR=`pwd`/$server_name

        rm -rf $LOG_DIR

        mkdir $LOG_DIR


        SCP=$(echo -e 'spawn scp '$CRED_LINE$server_name':/tmp/au_*_script '$LOG_DIR'/ ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]}  \n { \n send_user "Login complete" \n } \n } ' | expect)



        if [ "$(ls -A $LOG_DIR)" ]; then


                COMMANDS_CLEAR_OLD_REPORT_SCRIPT=`echo " rm -rf /tmp/au_*_script ; rm -rf /tmp/au_*_result    "`


                SSH_CLEAR_OLD_REPORT=$(echo -e 'spawn ssh -tt  '$CRED_LINE$server_name' "'$COMMANDS_CLEAR_OLD_REPORT_SCRIPT'" ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]} \n{\nsend_user "Login complete" \n } \n } ' | expect )

                STATUS='[ \e[0;31mUnsuspected error\e[00m ]'


                case `cat $LOG_DIR/au_result_script` in 1) STATUS='[ \e[0;31mFailed\e[00m ]' ;; 0) STATUS='[ \e[0;32mOK\e[00m ]' ;; 127) STATUS='[ \e[0;31mCommand not found\e[00m ]'  ;;  esac ;


                echo "#------------------------------------------------------------------------------------------"

                echo -e  "#\t"$SCRIPT_FILE"\t"$STATUS

                echo "#------------------------------------------------------------------------------------------"


                cat $LOG_DIR/au_comout_script




        fi ;

    }




    function command_run {

        SSH=$(echo -e 'spawn ssh -tt  '$CRED_LINE$server_name' "'$COMMANDS'" ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]}  \n { \n send_user "Login complete" ;  exp_continue \n } \n "assword for '$USER':" { \n send "'$PW'\\r" ; exp_continue \n } \n } ' | expect )

        SSH_EXIT_STATUS=$(echo "$SSH" | grep -i  "Permission denied" 1>/dev/null 2>/dev/null ; echo $?)



        LOG_DIR=`pwd`/$server_name

        rm -rf $LOG_DIR

        mkdir $LOG_DIR

        SCP=$(echo -e 'spawn scp '$CRED_LINE$server_name':/tmp/au_*_* '$LOG_DIR'/ ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]}  \n { \n send_user "Login complete" \n } \n } ' | expect)

        SEEK_VAR=1

        if [ "$(ls -A $LOG_DIR)" ]; then

                for i in `ls -1 $LOG_DIR/*result*` ; do

                        COMMAND_NAME=$(cat $COMMAND_FILE | head -$SEEK_VAR | tail -1)

                        ((SEEK_VAR+=1))

                        STATUS='[ \e[0;31mUnsuspected error\e[00m ]'

                        case `cat $i` in 1) STATUS='[ \e[0;31mFailed\e[00m ]' ;; 0) STATUS='[ \e[0;32mOK\e[00m ]' ;; 127) STATUS='[ \e[0;31mCommand not found\e[00m ]'  ;;  esac ;

                        echo "#------------------------------------------------------------------------------------------"

                        echo -e  "#\t"$COMMAND_NAME"\t"$STATUS

                        echo "#------------------------------------------------------------------------------------------"

                        cat $LOG_DIR/au_comout*$(echo $i | rev | cut -f 1  -d "_")

                done ;

        fi ;

        SSH_CLEAR_OLD_REPORT=$(echo -e 'spawn ssh -tt  '$CRED_LINE$server_name' "'$COMMANDS_CLEAR_OLD_REPORT'" ; \n   expect { \n"(yes/no)? " {\nsend "yes\\n" ;  exp_continue \n}\n"assword:" { \n send "'$PW'\\r" ; exp_continue \n } \n -re {[#>$]} \n{\nsend_user "Login complete" \n } \n } ' | expect )


        echo $server_name;
    }

    #
    #
    #
    #
    #
    GET_KEY=$(echo "$FIRST_KEY$SECOND_KEY" | grep "s" 1>/dev/null 2>/dev/null  ; echo $?)


    if [ $GET_KEY -ne 0  ] ; then


    command_run

    while [ $SSH_EXIT_STATUS -ne 1 ] ; do  echo -e  "\e[33m---\n Connection to "$server_name" failed \n Permission denied \n Please try again \n---\e[00m"  ; get_credential ; command_run ; done ;

    else

    script_run

    while [ $SSH_EXIT_STATUS -ne 1 ] ; do  echo -e  "\e[33m---\n Connection to "$server_name" failed \n Permission denied \n Please try again \n---\e[00m"  ; get_credential ; script_run ; done ;

    fi ;

    #
    #
    #
    #


done


### clear log file
for server_name in `cat $SERVER_LST_FILE` ; do
    LOG_DIR=`pwd`/$server_name ;
    rm -rf $LOG_DIR ;
done
