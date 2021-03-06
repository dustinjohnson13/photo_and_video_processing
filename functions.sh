#!/usr/bin/env bash

export MISC_VIDEO_DIR="/data/archives/video/misc"
export PICTURES_DIR="/data/archives/Pictures"
export PAR2_DIR="/data/archives/video/par2"

verifyRequiredSoftwareExists() {
    # Checks that all required software is installed and present

    which exiftool || (echo "Cannot find exiftool!" && exit 1)
    which par2create || (echo "Cannot find par2create!" && exit 1)
    which rename || (echo "Cannot find the perl rename script!" && exit 1)
#    ls /usr/sbin/rclone || (echo "Cannot find rclone!" && exit 1)
}

importPhotosAndVideos() {
    DIR="/data/archives/DCIM"

    # If there are no photos/videos to process, just exit
    [ -d "${DIR}" ] || { echo "No photos/videos to process" && exit 0; }

    # Remove spaces from all directories and files
    find "$DIR" -depth -name "* *" -execdir rename 's/ /_/g' "{}" \;

    # Find all files, ignoring metadata files
    for f in `find "$DIR" -type f -not -name "*.AAE" -not -name "._*"`
    do
       unset basedir
       unset date
       unset subdir
       unset found

       exiftool $f | grep MIME | grep video && basedir="$MISC_VIDEO_DIR"
       [ -z ${basedir+x} ] && exiftool $f | grep MIME | grep image && basedir="$PICTURES_DIR"

       # If we don't have a target directory, fail
       [ -z ${basedir+x} ] && echo "Unable to determine file type of $f!" && exit 1

       date=`exiftool $f | grep "^Create" || exiftool $f | grep "^Modifi" || exiftool $f | grep "^File Modifi"`

       # If we don't have a date, fail
       [ -z ${date+x} ] && echo "Unable to determine date of $f!" && exit 1

       subdir=`echo $date | perl -pe 's/.*(\d{4}[:-]\d{2}[:-]\d{2}).*/\1/g' | sed 's|[:-]|/|g'`
       found=`echo $subdir | perl -pe 's|\d{4}/\d{2}/\d{2}|found|g'`

       # If we didn't find a proper date format, fail
       [ $found = 'found' ] || { echo "$subdir is not a proper date format for $f!" && exit 1; }

       mkdir -p "${basedir}/${subdir}"
       cp "$f" "${basedir}/${subdir}"
    done

    time=`date +'%Y%m%d%H%M%S'`
    mv "$DIR" "${DIR}_processed_at_${time}"
}

createPar2FilesForMiscVideos() {
    # Creates par2 archives for videos

    DIRS="$MISC_VIDEO_DIR"

    for dir in `echo "$DIRS"`
    do
        (cd "$dir" && find . -type f -not -name "*.par2" -exec bash -c "ls \"$PAR2_DIR/{}.par2\" > /dev/null || par2create \"{}\"" \;)
        # Copy over the par2 files and delete the originals
        rsync -rv --remove-source-files --include="*/" --include="*.par2" --exclude="*" --prune-empty-dirs "$dir/" "$PAR2_DIR"
    done
}

copyPhotosAndVideosToTheCloud() {
    # Copy new files to Amazon Cloud Drive

    DIRS="$MISC_VIDEO_DIR $PICTURES_DIR $PAR2_DIR"

    for dir in `echo "$DIRS"`
    do
       name=`basename "$dir"`
       /usr/sbin/rclone copy "$dir" "remote:$name"
    done
}
