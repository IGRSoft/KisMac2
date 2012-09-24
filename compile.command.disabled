#!/bin/bash

if [ "x$1" == "x--help" ]; then
  echo "Usage ./compile.command [Development|Release] [image]"
  exit 0
fi

case $1 in
  "Development")
    configuration=Development;;
  "Release" | "" )
    configuration=Release;;
  *)
    echo "Usage ./compile.command [Development|Release]"
    exit 1
esac

if (! [ -d /Developer/SDKs/MacOSX10.4u.sdk ]) && [ $configuration == "Universal" ]; then
  echo "WARNING! Tried to build for Universal, but SDK is not present. Falling back to Deployment."
  configuration=Deployment
fi

echo "Building for configuration... $configuration"

echo -n "Building install image... "
if [ "x$1" == "ximage" ] || [ "x$2" == "ximage" ]; then
  echo "YES"
  BUILD_IMAGE=1
else
  echo "NO"
	BUILD_IMAGE=0
fi

echo -n "Checking for required enviroment... "
if ! [ -x /usr/bin/tar ]; then
	echo "/usr/bin/tar not found! Make sure you installed the BSD subsystem!"
	exit 1
fi

if ! [ -x /usr/bin/xcodebuild ]; then
	echo "Could not find a valid XCode version!"
	exit 1
fi

XCODEVERSION=`xcodebuild -version  | grep DevToolsCore | sed s/.*DevToolsCore-// | sed  s/..\;.*//`
if [ $XCODEVERSION -lt 658 ]; then
  echo "XCode Version is too old!"
  exit 1
fi

if echo $0 | grep " " > /dev/null; then
	echo "KisMAC source path contains a space character. This will lead to problems!"
	exit 1
fi

cd `dirname "$0"`
echo "ok"

echo -n "Decompressing UnitTest bundle... "
mkdir "./build/KisMACUnitTest.bundle/Contents/Frameworks" 2>/dev/null
cd UnitTest
ln -s "../build/KisMACUnitTest.bundle/Contents/Frameworks" . 2>/dev/null
tar -xjf UnitKit.tbz 2>/dev/null
if ! [ -d UnitKit.framework ]; then
  echo "*FAILED*"
  exit 1
fi
echo "ok"
cd ..

echo -n "Decompressing Growl framework... "
cd Resources
if [ -d Growl.framework ]; then
  rm -rf Growl.framework
fi

tar -xzf growl.tgz
if ! [ -d Growl.framework ]; then
  echo "*FAILED*"
  exit 1
fi
echo "ok"

cd ..

echo -n "Determine Subversion Revision... "
SVNVERS=`svn info | grep Revision | awk '{print $2}'`
echo $SVNVERS
sed -e "s/\\\$Revision.*\\\$/\\\$Revision: $SVNVERS\\\$/" Resources/Info.plist.templ > Resources/Info.plist
sed -e "s/\\\$Revision.*\\\$/\\\$Revision: $SVNVERS\\\$/" Resources/Strings/English.lproj/InfoPlist.strings.templ > Resources/Strings/English.lproj/InfoPlist.strings

echo -n "Preparing Enviroment... "
if [ -f compile.log ]; then
  rm compile.log
fi
touch "./Sources/not public/WaveSecret.h"
touch "./Sources/WindowControllers/CrashReportController.m"
mkdir "./Subprojects/files" 2>/dev/null
cd "./Subprojects/files"
rm -rf *.framework 2>/dev/null
cd ..

echo "ok"

echo -n "Building MACJack driver... "
cd MACJack
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
	exit 1
else
	echo "ok"
fi

echo -n "Building Viha driver... "
cd ../VihaDriver
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

echo -n "Building AtheroJack driver... "
cd ../AtheroJack
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

echo -n "Building AiroJack driver... "
cd ../AiroJack
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

echo -n "Building binaervarianz openGL framework... "
cd ../BIGL
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

echo -n "Building generic binaervarianz framework... "
cd ../BIGeneric
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

cd ../AirPortMenu
echo -n "Building AirPortMenu tool... "
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

cd ../KisMACInstaller
echo -n "Building KisMAC installer application... "
if ! xcodebuild -configuration $configuration >> ../../compile.log; then
        exit 1
else
        echo "ok"
fi

echo -n "Building KisMAC main application... "
cd ../..
if ! xcodebuild -target KisMAC -configuration $configuration >> compile.log; then
        exit 1
else
         echo "ok"
fi

if [ $BUILD_IMAGE == 1 ]; then
  echo -n "Generating KisMAC Disk Image..."
  
  if [ -f /Volumes/KisMAC ]; then
    	if hdiutil unmount /Volumes/KisMAC 2>/dev/null; then
        echo "*FAILED* Could not unmount loaded KisMAC Volume."
        exit 1
      fi
      sleep 10
  fi
  
	cp image/KisMACraw.sparseimage image/KisMAC.dmg
	hdiutil attach image/KisMAC.dmg > /dev/null
	
	sleep 1
	
	if ! [ -d /Volumes/KisMAC ]; then
    echo " *FAILED* Could not mount KisMAC Volume."
    exit 1
  fi 
  
	cp -r "Subprojects/KisMACInstaller/build/$configuration/KisMAC Installer.app/Contents" "/Volumes/KisMAC/KisMAC Installer.app"
  cp "image/WirelessDriver" "/Volumes/KisMAC/KisMAC Installer.app/Contents/Resources"
  
  cp -r build/$configuration/KisMAC.app image
  cd "image/KisMAC.app"
	rm `find . -type f -name .DS_Store` 2>/dev/null
	rm -rf `find . -name .svn`
	cd ..
	tar -czf "/Volumes/KisMAC/KisMAC Installer.app/Contents/Resources/KisMAC.tgz" KisMAC.app>/dev/null
	rm -rf KisMAC.app
	cd ..
  	
	rm `find "/Volumes/KisMAC/KisMAC Installer.app" -type f -name .DS_Store` 2>/dev/null
	rm -rf `find "/Volumes/KisMAC/KisMAC Installer.app" -name .svn`
  #rm /Volumes/KisMAC/Desktop*
  
  while [ -d  /Volumes/KisMAC ]; do
    hdiutil detach /Volumes/KisMAC >/dev/null
    sleep 1
    echo -n .
  done
  
	#trim dumb characters from SVN version
	SVNVERS=`echo $SVNVERS | sed 's/.*://g'`
  SVNVERS=`echo $SVNVERS | sed 's/\]//g'`
  	
	cd image
	zip -9 ../KisMACR$SVNVERS.zip KisMAC.dmg >/dev/null
	cd ..

	rm image/KisMAC.dmg
	echo "ok"
fi
