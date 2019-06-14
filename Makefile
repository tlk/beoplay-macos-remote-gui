Release.xcarchive:
	xcodebuild -workspace BeoplayRemoteGUI.xcodeproj/project.xcworkspace -scheme BeoplayRemoteGUI clean archive -configuration Release -archivePath Release.xcarchive
release: Release.xcarchive
clean:
	rm -rf Release.xcarchive
uninstall:
	rm -rf /Applications/BeoplayRemoteGUI.app
install: uninstall release
	cp -rp Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app /Applications
