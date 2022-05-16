#! /bin/bash

TEAM_NAME="LineageOS++"
TARGET=beryllium
LOS_VER=19.1
VERSION_BRANCH=lospp-19.1
OUT="out/target/product/beryllium"
ROM_VERSION=1.0
export ANDROID_HOME=~/Android/Sdk
# you may also need:
#sudo mkdir /mnt/ccache
sudo mount --bind /home/$(whoami)/.ccache /mnt/ccache
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/mnt/ccache
buildTest()
{
	export z=`date "+%H%M%S-%d%m%y"`
	export LINEAGEOSPP_VERSION="$ROM_VERSION - BETA"
	export LOS_VER=19.1
	echo "Building..."
	make -j16 otapackage
	#time schedtool -B -n 1 -e ionice -n 1 make otapackage -j10 "$@"
	if [ "$?" == 0 ]; then
		echo "Build done"
		mv $OUT/lineage*.zip $OUT/LineageOSPP-$LOS_VER-V$ROM_VERSION-$z.zip 
	else
		echo "Build failed"
	fi
	croot
}
buildRelease()
{
	export LINEAGEOSPP_VERSION="$ROM_VERSION - Release"
	export LOS_VER=19.1
	echo "Building..."
	make -j16 otapackage
	#time schedtool -B -n 1 -e ionice -n 1 make otapackage -j10 "$@"
	if [ "$?" == 0 ]; then
		echo "Build done"
		mv $OUT/lineage*.zip LineageOSPlusPlus-$LOS_VER-V$ROM_VERSION.zip
	else
		echo "Build failed"
	fi
	croot
}

upstreamMerge() {

	croot
	#echo "Refreshing manifest"
	#repo init -u git://github.com/"$TEAM_NAME"/manifests.git -b "$VERSION_BRANCH"
	#echo "Syncing projects"
	#repo sync --force-sync
	
        echo "Upstream merging"
        ## Our snippet/manifest
        ROOMSER=.repo/manifests/snippets/lineageplusplus.xml
        # Lines to loop over
        CHECK=$(cat ${ROOMSER} | grep -e "<remove-project" | cut -d= -f3 | sed 's/revision//1' | sed 's/\"//g' | sed 's|/>||g')

        ## Upstream merging for forked repos
        while read -r line; do
            echo "##### Upstream merging for $line #####"
	    rm -rf $line
	    repo sync $line
	    cd "$line"
	    git branch -D "$VERSION_BRANCH"
	    git checkout -b "$VERSION_BRANCH"
            UPSTREAM=$(sed -n '1p' UPSTREAM)
            BRANCH=$(sed -n '2p' UPSTREAM)

            git pull https://www.github.com/"$UPSTREAM" "$BRANCH"
            git push origin "$VERSION_BRANCH"
            croot
        done <<< "$CHECK"


}
 
 
 
anythingElse() {
    echo " "
    echo " "
    echo "Anything else?"
    select more in "Yes" "No"; do
        case $more in
            Yes ) bash build.sh; break;;
            No ) exit 0; break;;
        esac
    done ;
}


echo " "
echo -e "\e[1;91mWelcome to the $TEAM_NAME build script"
echo -e "\e[0m "
echo "Setting up build environment for $TARGET.."
. build/envsetup.sh && lunch lineage_$TARGET-userdebug
echo -e "\e[1;91mPlease make your selections carefully"
echo -e "\e[0m "
echo " "
select build in "Upstream merge" "Build Test" "Build Release" "Exit"; do
	case $build in
		"Upstream merge" ) upstreamMerge; anythingElse; break;;
		"Build Test" ) buildTest; anythingElse; break;;
		"Build Release" ) buildRelease; anythingElse; break;;
		"Exit" ) exit 0; break;;
	esac
done
exit 0

