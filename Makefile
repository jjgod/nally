# Mengjuei Hsieh, University of California Irvine

all:
	xcodebuild

clean:
	xcodebuild clean;	\
	rm -fr build;		\
	rm -f MacBlueTelnet.xcodeproj/${USER}.*

install: all
	rm -r /Applications/Nally.app; mv build/Release/Nally.app /Applications/

release: all
	hdiutil create -srcfolder build/Release -volname "Nally 1.4.2b" build/Nally142b.dmg; \
	hdiutil internet-enable -yes build/Nally142b.dmg
