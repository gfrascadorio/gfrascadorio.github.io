#!/bin/bash 

##
# lost (missing)
#       Find the files in inventory2 missing from inventory1
#       
#       lost -from file1 file2
#       lost -make [ -f ] root [inventory]
#       cd root; md5sum -c inventory
#
# HINTS
#       Find duplicates within an inventory.txt (see -dups)
#       awk '{print $1}' "$1"  | grep -v '\*\*\*' | uniq -d | \
#           join -j 1 - <(grep -v '\*\*\*' "$1")
#
#       Needs /bin/bash for <(cut ..) expressions
#
#       Using 'md5 -r' works, but doesn't verify with md5sum, which
#       seems faster anyway.
#
#       The inventory midsuffix is a fake 'volume id' that is the
#       cksum of the 'ls -sS' of the root'
#

MD5DEEP="/home/gaf/src/md5deep-3.4/md5deep/md5deep"

usage()
{
    echo ""
    echo "usage: $1"
    echo "   lost -from file1 file2           -- files in f2 missing from f1"
    echo "   lost -make [ -f ] root [foo.inv] -- make [force] inventory file"
    echo "   lost -dups foo.inv               -- list dups in inventory"
    echo "   lost -s 100g                     -- skip files larger than this"
    echo ""
    echo "   fdupes -r -f root > foo.dups     -- alternative"
    echo "   cat foo.dups | while read f ; do mv "\$f" ~/.Trash/files; done"
    echo ""
    echo "   md5sum -c inventory              -- check, emit failures"
    echo "   md5deep -r -m inventory root     -- check, emit match files"
    echo "   md5deep -r -M inventory root     -- check, emit match hashes"
    echo ""
    echo "   md5deep -r -x inventory root     -- check, emit failed files"
    echo "   md5deep -r -X inventory root     -- check, emit failed hashes"
    echo ""
    echo "   ln -s /usr/bin/hashdeep md5deep"
    echo "   exec -a md5deep hashdeep ..."
    echo ""
    echo "inventory files:"
    ls -l *.inv.txt *.inv 2>/dev/null
    echo ""
    exit 1
}

if [ $# -lt 2 ]; then
    usage "too few arguments:$*" 
fi

unset nflag               # like make -n: show
unset mdflags
unset fflag
mdflags="-e"              # md5 chatty default
skflags="-I 100m"         # skip files larger than this
while true; do
    subcmd=$1
    case $subcmd in
    -n)
        shift 1
        nflag=1
        ;;
    -q)
        shift 1
        mdflags=""        # tell md5 be quiet
        ;;
    -v)
        vflag="$1"
        mdflags=""        # tell md5 be quiet so tee can spew
        shift 1
        ;;
    -I|-s)
        skflags="-I $2"
        shift 2
        ;;
    -dups)
        shift 1
        awk '{print $1}' "$1"  | grep -v '\*\*\*' | uniq -d | \
            join -j 1 - <(grep -v '\*\*\*' "$1")
        exit $?
        ;;
    -from)
        shift 1
        comm -2 -3 <(cut -d ' ' -f1 $2 ) <(cut -d ' ' -f1 "$1" ) | \
            join -1 1 -2 1 /dev/stdin $2
        exit $?
        ;;
    -make)
        shift 1
        if [ "$1" = "-f" ]; then
            fflag="$1"
            shift
        fi
        ;;
    *)
        break
        ;;
    esac
done

[ $# -ge 1 ] || usage "invalid arguments: $*"

rootfold="$1"
fsid=$(ls -sS "$rootfold" | egrep -v '(^total|inv.txt)' | cksum | cut -d ' ' -f 1)

if [ $# -ge 2 ]; then
    invfile="$2"
    stem="$(basename "$2" | cut -d. -f 1 | tr -d ' ')"
else
    stem="$(basename "$1" | cut -d. -f 1 | tr -d ' ')"
fi

invfile="$stem.$fsid.inv.txt"

if [ -z "$fflag" -a -f "$invfile" ]; then
    usage "$invfile: already exists, use -f"
fi

if [ -n "$nflag" ]; then
    echo $MD5DEEP $mdflags $skflags -o f -l -r "$rootfold" \> "$invfile"

elif [ -n "$vflag" ]; then
    $MD5DEEP $mdflags $skflags -o f -l -r "$rootfold" | \
        grep -v '\.inv.txt' | \
        tee /dev/stderr | sort -k1 > "$invfile"
else
    echo $MD5DEEP $mdflags $skflags -o f -l -r "$rootfold" 
    $MD5DEEP $mdflags $skflags -o f -l -r "$rootfold" | \
        grep -v '\.inv.txt' | \
        sort -k1 > "$invfile"
fi

