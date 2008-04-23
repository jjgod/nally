# Mengjuei Hsieh, University of California Irvine

all:
	xcodebuild

clean:
	xcodebuild clean;	\
	rm -fr build;		\
	rm -f MacBlueTelnet.xcodeproj/${USER}.*

install: all
	rsync -avx --delete build/Release/Nally.app/ /Applications/Nally.app/
