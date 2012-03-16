#!/bin/sh

cd ~/code/folio

# build archive
xcodebuild -scheme Deployment archive

# cd to archive
cd ~/Library/Developer/Xcode/Archives/
cd "`ls -1t | head -1`"
cd "`ls -1t | head -1`"
cd Products/Users/rgreen/Applications

# delete bad symbolic links
rm Folio.app/Contents/Frameworks/MacRuby.framework/Headers
rm Folio.app/Contents/Frameworks/MacRuby.framework/MacRuby
rm Folio.app/Contents/Frameworks/MacRuby.framework/Resources
rm Folio.app/Contents/Frameworks/MacRuby.framework/Versions/0.10/Headers

# sign archive
codesign -f -s "3rd Party Mac Developer Application: Ron Green" Folio.app/


#
# Submitting to the App Store
#
# First, install Developer certs from Apple's Developer portal
#
# To Build the Application:
#
#    - Select "Your App" from your Scheme menu, NOT "Deployment"
#    - Select Product > Archive to build for Release
#    - Once completed, the Organizer window will open
#    - Select your recent build and press the "Validate" button - make sure this passes!
#    - Press the "Share" button, select "Application" and save to your filesystem
#
# Second, Compile and Sign:

# Embed MacRuby and compile
macruby_deploy --embed --compile /Users/rgreen/Desktop/Folio.app/

# Delete bad symbolic links
rm /Users/rgreen/Desktop/Folio.app/Contents/Frameworks/MacRuby.framework/Headers
rm /Users/rgreen/Desktop/Folio.app/Contents/Frameworks/MacRuby.framework/MacRuby
rm /Users/rgreen/Desktop/Folio.app/Contents/Frameworks/MacRuby.framework/Resources
rm /Users/rgreen/Desktop/Folio.app/Contents/Frameworks/MacRuby.framework/Versions/0.10/Headers

# Sign the app with the Developer Application certificate
codesign -f -s "3rd Party Mac Developer Application: Ron Green" Folio.app/

# Build an installer package
productbuild --component /Users/rgreen/Desktop/Folio.app/ /Applications --sign "3rd Party Mac Developer Installer: Ron Green" /Users/rgreen/Desktop/Folio.pkg

# Last, launch "Application Loader"
# Enter your credentials and select the correct app and version you want to submit
# Select the .pkg file you just created, and hit upload.

# show info
codesign --display --verbose=4 Folio.app/