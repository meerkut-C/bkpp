#!/bin/sh
USAGE='Usage: %s [-h|--help] [-q] [-k]'
HELP=' Web site: https://github.com/meerkut-C/bkpp

OPTIONS
=======

    ! arguments can not be ganged together;

    -h|--help          Print this text.
    -k                 Keep. Suppress the normal deletion of temp files.
    -q                 Quiet. Suppress normal result or diagnostic output.

DESCRIPTION
===========

bkpp is a "tar" based backup program that allows you to add patterns and literal
entries to ".bkp_ignore" file for stuff that doesn`t need to be backed up.

Most of this script just creates three lists:
  - main input list (white list)
  - a list of pattern exclusions (black list)
  - a list of literal file paths exclusions (black list)
and then feeds them to the archiving program "tar".

Due to the nature of the tar program, empty directories are not archived. This
simplifies the bkpp logic. If an empty is necessary, leave an empty file in an
empty directory. dot_bkp_ignore files themselves are archived by default too.
You can anytime add them to exclusions.

Some measures have been put in place to ensure that common mistakes will be 
noticed on time, before you spend your precious time debugging, or worse,
your archive will be incomplete.

bkpp forces you to insert all your paths in quotes. Shell script is notorious
for unnoticed whitespace ending up in a string content. bkpp then checks itself
by polling all entry points for their existence (you may have changed the
structure of the archived files and forgot to map those changes to the archive
commands.) Every nonexistent path will be printed to STDERR. An exception to
this is made for absolute paths to files that you enter yourself in the body of
function "add_literal_files_to_the_archiving()". I use bkpp to backup some of 
my directories and have been using this for 2 years now, and strongly advise 
against putting command-line option "-q".

To familiarize yourself with the logic of the program, you need to go down the
code to the section that begins with the comment ####### MAIN ###########. The
program is organized into procedures, and the order of procedure calls is the
logic of the program.

USAGE
=====

Pattern rules
-------------
All patterns, including the pattern from the dot_bkp_ignore file is copied to
the exclusion file for the "tar" command. Therefore, all questions about how to
get the desired effect from using pattern shall be found in the documentation
for "tar" command.

dot_bkp_ignore file
-------------------
  - where to place
    The dot_bkp_ignore file should be placed in that node of the file tree (in
    the directory), from where, further, relative to this node, exclusion for
    archiving will be indicated. In what follows, we will say that there is a
    prefix. The prefix is the part of path to the left of this node.
      - Patterns are written taking into account the path
        prefix to the dot_bkp_ignore file.
      - The prefix ends with "/".
      - Note: spaces at the end on a line will be included
        in the resulting path.

  - comment rules, empty lines
    Blank lines are accepted.
    Only the entire line is considered as a comment. Part of the line is not
    supposed to be a comment. Hash # at the beginning of a line (excluding
    spaces at the beginning of a line) opens a comment, a symbol of line ending
    ends the comment. The # anywhere in the string is considered to be # itself.

  - the section wildcards=yes
    The section is looked up using awk-regex  /[ ]*wildcards=yes/
    This section always comes first, the "wildcards=no" section goes below.
    Each path should be placed on a separate line. 
    Paths are written taking into account the path prefix to the dot_bkp_ignore
    file.
    Prefix ends with "/".
    
  - the section wildcards=no
    The section is looked up using awk-regex  /[ ]*wildcards=no/
    This section always comes after the "wildcards=yes" section.
    Each path should be placed on a separate line. 
    Paths are written taking into account the path prefix to the dot_bkp_ignore
    file.
    Prefix ends with "/".    
    

Example of dot_bkp_ignore file
------------------------------
  - Suppose we placed a dot_bkp_ignore file in "/tmp/very_important" directory, 
    and its content is:
    
    $ cat /tmp/very_important/.bkp_ignore
    #### In this section: implicit_prefix/ + patterns for paths
    wildcards=yes

    222*
    444/44/4/*
    444/44/5/*hh

    #### In this section: implicit_prefix/ + exact further path to the file
    wildcards=no

    .bkp_ignore
    
  - Then, we put an entry point in the body of the function
    set_entry_points_in_a_file_tree():
    
    echo "/tmp/very_important"                   >&3

  - Contents of the "/tmp/very_important":
    $ tree -a -v /tmp/very_important
    /tmp/very_important
    ├── .bkp_ignore
    ├── 111
    ├── 222
    │   └── an_empty
    ├── 333
    │   ├── file_cc
    │   ├── file_dd
    │   └── file_ee
    ├── 444
    │   └── 44
    │       ├── 4
    │       │   ├── file_ff
    │       │   └── file_gg
    │       └── 5
    │           ├── an_empty
    │           └── file_hh
    ├── file_A
    └── file_B

    7 directories, 11 files
    
  - As a result, we will get the following contents of the archive:

    $ tree  -a -v
    ...
    └── very_important
        ├── 333
        │   ├── file_cc
        │   ├── file_dd
        │   └── file_ee
        ├── 444
        │   └── 44
        │       └── 5
        │           └── an_empty
        ├── file_A
        └── file_B

    5 directories, 6 files    
'

            # ARCH_DEST_DIR + ARCH_NAME
            # is the path of the resulting archive file
ARCH_NAME='mywork_arch.tar'
ARCH_DEST_DIR="${HOME}"/'tmp'


            # INCLUDEs
            # dirs-only list of entry points in filesystem trees
set_entry_points_in_a_file_tree(){
  local fname="${TEMPDIR}"/'ENTRY_POINTS_from_user.list'
  : > "${fname}"; exec 3<> "${fname}"
  # - - - - - - - - - - - - - - - - - - - - - - - -

  #echo "${HOME}"/'.config/geany'              >&3
  #echo "${HOME}"/'.textadept'                 >&3
  echo '/tmp/very_important'                   >&3  

  # - - - - - - - - - - - - - - - - - - - - - - - -
  ENTRY_POINTS=$(cat "${fname}")
}


            # INCLUDEs
            # files-only list of
add_literal_files_to_the_archiving() {
  local fname="${TEMPDIR}"/'INCLUDE_literal_files.list'
  : > "${fname}"; exec 4<> "${fname}"
  INCLUDE_FILES="${fname}"
  # - - - - - - - - - - - - - - - - - - - - - - - -
            # Append manually some files.
            # Find all hidden files in the "${HOME}"
  # find "${HOME}" -maxdepth 1 -type f -name '\.*' | sort >&4
  # - - - - - - - - - - - - - - - - - - - - - - - -
}


            # EXCLUDEs <-- PATTERN
            # sets explicit patterns for exclusion
set_excludes_with_pattern() {
  local fname="${TEMPDIR}"/'EXCLUDEs_PATTERN.list'
  : > "${fname}"; exec 5<> "${fname}";
  EXCL_PATT="${fname}"
  # - - - - - - - - - - - - - - - - - - - - -
  #echo '*__pycache__*'                     >&5
  #echo '*.o'                               >&5
  #echo '*.ppu'                             >&5
  #echo '*.dbg'                             >&5
  # - - - - - - - - - - - - - - - - - - - - -
}


            # EXCLUDEs <-- absolute paths
            # commands should produce files-only list of absolute paths
set_excludes_literal() {
  local fname="${TEMPDIR}"/'EXCLUDEs_LITERAL.list'
  : > "${fname}"; exec 7<> "${fname}";
  EXCL_LITERAL="${fname}"
  # - - - - - - - - - - - - - - - - - - - - - - - - - -
             # assuming that your working files are source files and
             # scripts files, and they are usually smaller, ...
             # find all files of type "-executable", more than 300kb
             # and write them to the end of the file 'EXCLUDEs_LITERAL.list'
             
  #find "${HOME}"/'my-work'  -type f -executable -size +300k >&7
  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  report r2 "${fname}";
}

#######
####### the END of user space ##################################################
#######




make_a_temp_dir() {
  TEMPDIR=`mktemp -t -d bkpp.XXXXXXXXXX` || {
      echo >&2 "${LIGHTRED}""can't create temp folder.""${NC}"; exit 1
      }
  report r1 "${TEMPDIR}";
}


            # check_the_correctness_of_entry_points_in_a_file_tree( text )
            # Reads text from $1.
            # Expects text, which contains an LF-delimited list. That means
            #   - text must be passed in double quotes to prevent dash
            #     expand the LF list by the current IFS at the time
            #     of the call.
            # - Prints in red paths where there are no files in FS
check_if_exist_entry_points_in_the_file_tree(){
  local old_IFS
  local ii
  old_IFS="${IFS}"; ii=0
  IFS="${NEWL}"
  for file in $1 ; do
      ii=$((ii+1))
      test -e "${file}" ||
        echo >&2 "${LIGHTRED}"'No such file or directory:'"${NC}" "${file}"
  done
  IFS="${old_IFS}"
}

            # white.list may be quite sizeable. It is used twice:
            #   - when searching for dot-ignores by grep_dot_bkp_ignores()
            #   - as the main INPUT_LIST for tar
make_temp_list_about_searching_dotignores(){
  local fname="${TEMPDIR}"/'white.list'
  local dd  old_IFS
  : > "${fname}"; exec 9<> "${fname}";
  INPUT_LIST="${fname}"
  old_IFS="${IFS}"
  IFS="${NEWL}"
  for dd in ${ENTRY_POINTS} ; do
      find "${dd}" -type f >&9
  done
  IFS="${old_IFS}"
  report r3 "${fname}"
}
            # Collects from "white.list" all ".bkp_ignore"
grep_dot_bkp_ignores() {
  local fname="${TEMPDIR}"/'all_bkp_ignore_files.list'
  : > "${fname}";
  grep '.bkp_ignore$' -- "${TEMPDIR}"/'white.list' >"${fname}"
  TMPLI=$(cat "${fname}")
  report r4 "${fname}"
}
            # The awk program in a loop examines every ".bkp_ignore"
handle_dot_bkp_ignores_append_them_to_excludes() {
  local   ii  file  old_IFS
  local awk_program=' BEGIN{ WICA=0; fpath=ARGV[1] }
   /[ ]*#/ { next }                      # IF comment THEN continue...
   /[ ]*wildcards=yes/ { WICA=1; next }  # IF key=value THEN +flag+continue...
   /[ ]*wildcards=no/ { WICA=0; next }   # IF key=value THEN -flag+continue...
   NF==0 { next }                        # IF empty THEN continue...

   1 {
     sub(".bkp_ignore","", fpath)    # delete from fpath
     dirp=fpath                      # a prefix
     if (WICA==1) {
        print dirp $0 >"/dev/fd/5";  # prefix+pattern -> abs pattern
     } else {
        print dirp $0 >"/dev/fd/7";  # prefix+"relative path" -> abs path
     }
     next
     }
'
  old_IFS="${IFS}"; ii=0
  IFS="${NEWL}"
  for file in ${TMPLI} ; do
      ii=$((ii+1))
      gawk "${awk_program}" "${file}"
  done
  IFS="${old_IFS}"
  report r5 "${ii}"
}

merge_into_one_input_file(){
  cat "${INCLUDE_FILES}" >&9
}

            # order of arguments is important !
            #     "--exclude" comes first
            #     "--no-wildcards" needs to go before the "--exclude-from"
tartar(){
  BACKUP_FILE="${TEMPDIR}"/'mybackup_data'
  tar --exclude-from="${EXCL_PATT}"                     \
      --no-wildcards                                    \
      --exclude-from="${EXCL_LITERAL}"                  \
      --files-from="${INPUT_LIST}"                      \
      -zvcf "${BACKUP_FILE}"'.tar' >/dev/null
  report r6 "${BACKUP_FILE}"'.tar'
}

copy_created_archive_to_destination(){
  cp --preserve=all "${TEMPDIR}"'/mybackup_data.tar' "${ARCH_DEST_DIR}"/"${ARCH_NAME}"
  if [ $? -ne 0 ]
  then
    KEEP_FILES='yes'
    echo >&2 "${LIGHTRED}"'!   '"${NC}" 'the cp command could not copy the file'
    echo >&2 "${LIGHTRED}"'!   '"${NC}" "${TEMPDIR}"'/mybackup_data.tar'
    echo >&2 "${LIGHTRED}"'!   '"${NC}" 'to specified path: ' "${ARCH_DEST_DIR}"
    echo >&2 "${LIGHTRED}"'!   '"${NC}" 'Do it yourself.'
  else
    report r7 "${ARCH_DEST_DIR}"/"${ARCH_NAME}"
  fi
}

cleanup(){
  if [ -d "${TEMPDIR}" -a x"${KEEP_FILES}" != x"yes" ]; then
    rm -rf "${TEMPDIR}" 2>/dev/null
    report 8
  else
    report r9 "${TEMPDIR}"
  fi
  exec 3>&-
  exec 4>&-
  exec 5>&-
  exec 7>&-
  exec 9>&-
}


report() {
test x"${VERBOSE}" = x'no' && return
local msg1  msg2  msg3
case "$1" in
r1) msg1='ok     ';
    msg2='TEMPDIR="'"$2"'" was created ...'
;;
r2) msg1='ok     ';
    msg2='files larger than 300kb were added to the list "'"$2"'" ...'
;;
r3) msg1='ok     ';
    msg2='the main INPUT_LIST for tar "'"$2"'" was created...'
;;
r4) msg1='ok     ';
    msg2='"'"$2"'" was created...'
    ;;
r5) msg1='ok     ';
    msg2='''content from '"$2"' '
   msg3='files ".bkp_ignore" processed and the result was added to EXCLUDEs ...'
;;
r6) msg1='ok     ';
    msg2='resulting archive file "'"$2"'" was created ...'
;;
r7) msg1='ok     ';
    msg2='a copy created: '"$2"' ...'
;;
r8) msg1='ok     ';
    msg2='temporary files were removed...'
;;
r9) msg1='ok     ';
    msg2='temporary files are left for further analysis here: '
    msg3="$2"
;;
r10) msg1='ok     ';
     msg2='done.'
;;
esac
  echo >&2 "${msg1}""${msg2}""${msg3}"
}

handle_commandline_options(){
while case "$#" in 0) break ;; esac
  do
  case "$1" in
    -h|--h|--he|--hel|--help)
      printf "${USAGE}""\n" "$0"
      echo "${HELP}"
      exit 0 ;;

    -q)
       VERBOSE='no' ;;

    -k) # (yes|no) whether to leave temporary files for analysis
      KEEP_FILES='yes' ;;

     *)
      echo  'item' "$1" 'on the command line is not an option.'
      printf "${USAGE}""\n" "$0"
      exit 1 ;;
  esac
  shift
done
}


# Define a few colors
BLACK='\e[0;30m'
BLUE='\e[0;34m'
GREEN='\e[0;32m'
CYAN='\e[0;36m'
RED='\e[0;31m'
PURPLE='\e[0;35m'
BROWN='\e[0;33m'
LIGHTGRAY='\e[0;37m'
DARKGRAY='\e[1;30m'
LIGHTBLUE='\e[1;34m'
LIGHTGREEN='\e[1;32m'
LIGHTCYAN='\e[1;36m'
LIGHTRED='\e[1;31m'
LIGHTPURPLE='\e[1;35m'
YELLOW='\e[1;33m'
WHITE='\e[1;37m'
NC='\e[0m' # No Color

# Global vars
NEWL='
'
TEMPDIR=''
ENTRY_POINTS=''
TMPLI=''
BACKUP_FILE=''
EXCL_PATT=''
EXCL_LITERAL=''
INPUT_LIST=''
VERBOSE='yes'
KEEP_FILES='no'

####### MAIN ###################################################################
handle_commandline_options "$@";
make_a_temp_dir;
set_entry_points_in_a_file_tree;
check_if_exist_entry_points_in_the_file_tree   "${ENTRY_POINTS}";
add_literal_files_to_the_archiving;
set_excludes_with_pattern;
set_excludes_literal;
make_temp_list_about_searching_dotignores;
grep_dot_bkp_ignores;
handle_dot_bkp_ignores_append_them_to_excludes;
merge_into_one_input_file;
tartar;
copy_created_archive_to_destination;
cleanup;
report r10    # done.
