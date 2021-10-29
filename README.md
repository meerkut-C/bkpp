# bkpp
A "tar" based backup program that allows you to add patterns and literal entries
to ".bkp_ignore" file for stuff that doesn't need to be backed up.

bkpp is an Open Source backup software available under the GNU General
Public License.

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

```
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
```


## Worked examples

see `./examples/1/`. Unpack into `/tmp/very_important`. The bkpp-script 
has a manually set path to this example. Run `./bkpp.sh -k`.

#### Footnote

This script is about 2 times shorter in terms of the number of additional
procedures that I personally use. Hopefully, shortening and generalizing this
script didn't break anything.
