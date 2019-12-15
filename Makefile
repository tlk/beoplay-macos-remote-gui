Release.xcarchive:
	xcodebuild -workspace BeoplayRemoteGUI.xcodeproj/project.xcworkspace -scheme BeoplayRemoteGUI clean archive -configuration Release -archivePath Release.xcarchive
release: Release.xcarchive
release-unsigned:
	xcodebuild -workspace BeoplayRemoteGUI.xcodeproj/project.xcworkspace -scheme BeoplayRemoteGUI clean archive -configuration Release -archivePath Release.xcarchive DEVELOPMENT_TEAM="" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
	ln -s /Applications Release.xcarchive/Products/Applications/
	hdiutil create -srcfolder Release.xcarchive/Products/Applications -volname BeoplayRemoteGUI BeoplayRemoteGUI.dmg
clean:
	rm -rf Release.xcarchive BeoplayRemoteGUI.dmg
uninstall:
	rm -rf /Applications/BeoplayRemoteGUI.app
install: uninstall release
	cp -rp Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app /Applications
