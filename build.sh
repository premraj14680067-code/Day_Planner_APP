#!/bin/bash
# Clone the Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable flutter_sdk

# Configure Flutter for Web
./flutter_sdk/bin/flutter config --enable-web

# Only create the web folder if it doesn't exist
if [ ! -d "web" ]; then
  ./flutter_sdk/bin/flutter create . --platforms web
fi

# Build the project
./flutter_sdk/bin/flutter build web