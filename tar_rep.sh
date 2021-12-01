#!/bin/bash

# This script handles 3 modes, [c]reate, e[x]tract, lis[t]. We use numbers 1, 2, 3 to represent these modes respectively.
MODE=0; # not set right now.

# [v]erbose?
Verbose=0; # will turn on based on command line arguments.

# Name of the archive [f]ile
ARCHIVE_NAME="";

# Array containing names of files to be operated on.
FILES=(); 

# Taking in input: 
while [[ $# -gt 0 ]]; do # while there are things to read, do:
    val="$1"
    case $val in
        -c)
            MODE=1
            shift # pass
            ;;
        -x)
            MODE=2
            shift # pass
            ;;
        -t)
            MODE=3
            shift # pass
            ;;
        -f)
            shift # pass
            ARCHIVE_NAME="$1" # next to -f tag we get the ARCHIVE_NAME.
            shift # pass
            ;;
        -v)
            Verbose=1
            shift # pass
            ;;
        *) # default
            FILES+=("$1") # if its a not a tag we assume its name of a file.
            shift # pass
            ;;
    esac
done

# Error handling if archive name not given
if [ -z "$ARCHIVE_NAME" ]; then
    echo "Error: Please specify name of archive file."
    echo "Exiting with failure status"
    exit 1
fi

# Checking the mode and running accordingly ##############
##########################################################

if [[ $MODE == 0 ]]; then 
    # Error handling
    echo "Error: No mode specified. Try one of the following: -c , -t , -x ."
    echo "Exiting with failure status"
    exit 1

##############################################################################
##############################################################################

elif [[ $MODE == 1 ]]; then
    # This is the [c]reate mode.
    
    # If an archive with the same name already exists we'll prompt an error.
    if [[ -f "$ARCHIVE_NAME" ]]; then
        echo "Error: An archive with same name \"$ARCHIVE_NAME\" exists"
        echo "Exiting with failure status"
        exit 1
    fi

    flen=${#FILES[@]}
    # If no file is provided, error prompt:
    if [[ $flen == 0 ]]; then
        echo "Error: No file provided to archive"
        echo "Exiting with failure status"
        exit 1
    fi

    # Create the archive 
    touch $ARCHIVE_NAME

    # For separating contents of files we maintain cumulative line count.
    Lines_total=$(( 2* flen));
    Lines_total=$(( Lines_total + 2 ));

    # METADATA
    #--------------
    echo "$flen" > $ARCHIVE_NAME # number of files to be archived

    # 1. Number of lines in the file and the line number at which its stored
    for i in "${FILES[@]}"; do

        Lines_this_file="$(wc -l $i | cut -f1 -d' ')"  # getting number of lines in current file
        Lines_this_file=$((Lines_this_file + 1)); # For newline issues, maintaining an extra line.
        # lines_total is position of contents of file in archive.
        echo "$Lines_total $Lines_this_file $i">>$ARCHIVE_NAME  
        Lines_total=$(( Lines_total + Lines_this_file + 1)) # updating for next iteration (+1 for newline)
    done
    #2. Detaled information of the file
    for i in "${FILES[@]}"; do
        ls -l $i >>$ARCHIVE_NAME   
    done

    # Concatanating
    # -----------------
    for i in "${FILES[@]}"; do
        # If verbose is on we'll print names of files we're archiving.
        if [[ $Verbose == 1 ]]; then
            echo $i
        fi
        cat $i >>$ARCHIVE_NAME # Printing content of the file
        echo -e "\n" >>$ARCHIVE_NAME # echo will introduce newline to separate contents of different files
    done
    exit 0;

##############################################################################
##############################################################################

elif [[ $MODE == 2 ]]; then
    # This is e[x]tract mode
    
    # Error handling
    if [[ ! -f "$ARCHIVE_NAME" ]]; then
        echo "Error: Archive ${ARCHIVE_NAME} not found";
        echo "Exiting with failure status"
        exit 1;
    fi
    # This script extracts files all at once only.
    if [[ ${#FILES[@]} != 0 ]]; then
        echo "Error: This script extracts all files at once only";
        echo "Exiting with failure status"
        exit 1;
    fi

    # First we need to check number of files in the archive.
    # Since in creating metadata we wrote the number of files at first line of file, we'll extract that number here.
    num_in_arch="$(head -n 1 "$ARCHIVE_NAME" | cut -f1 -d' ')";

    # after the first line, the next ${num_in_arch} lines that follows contains info regarding where the contents of the files are stored.
    j=2;
    last_info_line=$((2+num_in_arch))
    while [ $j -lt $last_info_line ]; do
        # each line is of the form starting_line total_lenght name_of_file
        # so using cut we get each field and we store it in the following variables.
        starting_line="$(sed "${j}q;d" $ARCHIVE_NAME | cut -f1 -d' ')"
        total_lenght="$(sed "${j}q;d" $ARCHIVE_NAME | cut -f2 -d' ')"
        name_of_file="$(sed "${j}q;d" $ARCHIVE_NAME | cut -f3 -d' ')"
        
        if [[ $Verbose == 1 ]]; then
            echo $name_of_file ; # verbose: list the files
        fi

        # we'll use head tail piped to get the content, but first we need line number of last line
        ending_line=$((starting_line+total_lenght));
        total_lenght=$((total_lenght+1)); # handling newlines
        head -n ${ending_line} $ARCHIVE_NAME | tail -n ${total_lenght} >$name_of_file ;

        # incrementing j for next iteration of loop
        j=$((j+1));
    done

    exit 0;

##############################################################################
##############################################################################

elif [[ $MODE == 3 ]]; then
    # This is lis[t] mode

    # Error handling
    if [[ ! -f "$ARCHIVE_NAME" ]]; then
        echo "Error: Archive ${ARCHIVE_NAME} not found";
        echo "Exiting with failure status"
        exit 1;
    fi

    # First we need to check number of files in the archive.
    # Since in creating metadata we wrote the number of files at first line of file, we'll extract that number here.
    num_in_arch="$(head -n 1 "$ARCHIVE_NAME" | cut -f1 -d' ')";

    # In our metadata, we basically have lines 2 to n+1 lising line numbers and names of files.
    # if verbose is off, we need only the names of files, so we extract that data:
    if [[ $Verbose == 0 ]]; then

        end_file_name=$((num_in_arch+1)); # line n+1 where n is number of archived files
        
        if [[ ${#FILES[@]} == 0 ]]; then
            # Print all files 
            # using head we get first n+1 lines, but since we need to cut off first line, we use tail, and then finally cut to get third col.
            head -n ${end_file_name} "$ARCHIVE_NAME" | tail -n ${num_in_arch} | cut -f3 -d' ';
            err=$?
            if [[ $err -ne 0 ]]; then
                # we got some error
                echo "Error with code: $err";
                echo "Exiting with failure status"
                exit 1;
            fi
        else
            # Since certian files needs to be listed, we'll just use grep piped with prev case to find their names in the list.
            for i in "${FILES[@]}"; do
                head -n ${end_file_name} "$ARCHIVE_NAME" | tail -n ${num_in_arch} | cut -f3 -d' '| grep -w "$i" ;
                err=$?
                if [[ $err -ne 0 ]]; then
                    # we got some error
                    echo "Error with code: $err"
                    if [[ $err == 1 ]]; then
                        echo "$i not found in $ARCHIVE_NAME" # grep exits with code 1 when there's no match
                    fi
                    echo "Exiting with failure status"
                    exit 1
                fi
            done 
        fi
    elif [[ $Verbose == 1 ]]; then
        # In our metadata we stored output of ls -l {{file}} 
        # from lines n+2 to 2n+1. We thus output these lines here (verbose is on)

        end_file_info=$((2*num_in_arch +1)); # line 2n+1
        
        if [[ ${#FILES[@]} == 0 ]]; then
            # Print all files info
            # using head we get first 2n+1 lines, then tail to get the last n lines only.
            head -n ${end_file_info} $ARCHIVE_NAME | tail -n ${num_in_arch};
            err=$?;
            if [[ $err -ne 0 ]]; then
                # we got some error
                echo "Error with code: $err";
                echo "Exiting with failure status"
                exit 1;
            fi
            exit 0;
        else
        # some file names provided, we just use grep to get them.
            for i in "${FILES[@]}"; do
                head -n ${end_file_info} $ARCHIVE_NAME | tail -n ${num_in_arch} | grep -w "$i" ;
                err=$?
                if [[ $err -ne 0 ]]; then
                    # we got some error
                    echo "Error with code: $err";
                    if [[ $err == 1 ]]; then
                        echo "$i not found in $ARCHIVE_NAME"; # grep exits with code 1 when there's no match
                    fi
                    echo "Exiting with failure status"
                    exit 1
                fi
            done 
        fi
    fi
fi
