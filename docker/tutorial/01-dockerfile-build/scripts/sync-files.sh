HOSTPAIR="rootlike@$1"

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
echo "Current working directory: ${cwd}"
cd $cwd

# rsync -flags <source> <username>@<target>:<path>
rsync -av --progress --stats -e 'ssh' ../ ${HOSTPAIR}:
