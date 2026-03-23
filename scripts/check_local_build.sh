#!/bin/bash

echo "--- EAS Build --local Setup Verification ---"
echo ""

# --- Core Development Tools ---

echo "Checking Core Development Tools..."

# 1. Node.js & npm/Yarn
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✅ Node.js is installed ($NODE_VERSION)"
else
    echo "❌ Node.js is NOT installed. Please install Node.js (LTS recommended)."
    echo "   (Download from: https://nodejs.org/)"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo "✅ npm is installed ($NPM_VERSION)"
elif command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn -v)
    echo "✅ Yarn is installed ($YARN_VERSION)"
else
    echo "❌ npm or Yarn is NOT installed. Please install one."
    echo "   (npm: npm install -g npm@latest)"
    echo "   (Yarn: npm install -g yarn)"
fi

# # 2. Expo CLI
# if command -v expo &> /dev/null; then
#     EXPO_VERSION=$(expo --version)
#     echo "✅ Expo CLI is installed ($EXPO_VERSION)"
# else
#     echo "❌ Expo CLI is NOT installed. Please install it: npm install -g expo-cli"
# fi

# 3. EAS CLI
if command -v eas &> /dev/null; then
    EAS_VERSION=$(eas --version)
    echo "✅ EAS CLI is installed ($EAS_VERSION)"
    if eas whoami &> /dev/null; then
        echo "✅ Logged into Expo account."
    else
        echo "⚠️ Not logged into Expo account. Run 'eas login'."
    fi
else
    echo "❌ EAS CLI is NOT installed. Please install it: npm install -g eas-cli"
fi

# 4. Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo "✅ Git is installed ($GIT_VERSION)"
else
    echo "❌ Git is NOT installed. Please install Git."
    echo "   (Download from: https://git-scm.com/downloads)"
fi

echo ""
echo "--- Android Specific Tools ---"

# 1. JDK and JAVA_HOME
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "✅ Java (JDK) is installed ($JAVA_VERSION)"
else
    echo "❌ Java (JDK) is NOT installed. Please install OpenJDK 17 or later."
    echo "   (Adoptium Temurin is a good choice: https://adoptium.net/)"
fi

if [ -n "$JAVA_HOME" ]; then
    echo "✅ JAVA_HOME is set: $JAVA_HOME"
    if [ ! -d "$JAVA_HOME" ]; then
        echo "⚠️ JAVA_HOME directory does not exist: $JAVA_HOME"
    fi
else
    echo "❌ JAVA_HOME is NOT set. Please set it to your JDK installation directory."
fi

# 2. Android Studio (basic check for common installation paths)
if [ -d "/Applications/Android Studio.app" ] || [ -d "$HOME/Android/Sdk" ] || [ -d "/usr/local/android-studio" ]; then
    echo "✅ Android Studio (or Android SDK) directory found."
else
    echo "⚠️ Android Studio might not be installed or in a standard location. Please verify manually."
    echo "   (Download from: https://developer.android.com/studio)"
fi

# 3. ANDROID_HOME / ANDROID_SDK_ROOT
if [ -n "$ANDROID_HOME" ]; then
    echo "✅ ANDROID_HOME is set: $ANDROID_HOME"
    if [ ! -d "$ANDROID_HOME" ]; then
        echo "⚠️ ANDROID_HOME directory does not exist: $ANDROID_HOME"
    fi
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    echo "✅ ANDROID_SDK_ROOT is set: $ANDROID_SDK_ROOT"
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        echo "⚠️ ANDROID_SDK_ROOT directory does not exist: $ANDROID_SDK_ROOT"
    fi
else
    echo "❌ ANDROID_HOME or ANDROID_SDK_ROOT is NOT set. Please set one to your Android SDK directory."
    echo "   (Usually located in Android Studio settings or $HOME/Library/Android/sdk on macOS, $HOME/Android/Sdk on Linux/Windows)"
fi

# 4. sdkmanager (part of Android SDK Tools)
if command -v sdkmanager &> /dev/null; then
    echo "✅ sdkmanager is found (Android SDK Platform-Tools likely installed)."
else
    echo "❌ sdkmanager is NOT found. Ensure Android SDK Platform-Tools are installed and in your PATH."
    echo "   (Check Android Studio SDK Manager -> SDK Tools tab)"
fi

# # 5. gradle (optional, often invoked via gradlew)
# if command -v gradle &> /dev/null; then
#     GRADLE_VERSION=$(gradle -v | grep 'Gradle ' | awk '{print $2}')
#     echo "✅ Gradle is installed ($GRADLE_VERSION)"
# else
#     echo "⚠️ Gradle command not found. This is often fine as projects use './gradlew'."
# fi

echo ""
echo "--- iOS Specific Tools (macOS Only) ---"

# Check if OS is macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS, checking iOS tools..."

    # 1. Xcode
    if xcode-select -p &> /dev/null; then
        XCODE_PATH=$(xcode-select -p)
        echo "✅ Xcode Command Line Tools are installed ($XCODE_PATH)"
        if command -v xcodebuild &> /dev/null; then
            XCODE_VERSION=$(xcodebuild -version | grep 'Xcode' | awk '{print $2}')
            echo "✅ xcodebuild is available (Xcode version: $XCODE_VERSION)"
        else
            echo "❌ xcodebuild is NOT available. Something is wrong with Xcode installation."
        fi
    else
        echo "❌ Xcode Command Line Tools are NOT installed. Run 'xcode-select --install'."
    fi

    # 2. CocoaPods
    if command -v pod &> /dev/null; then
        POD_VERSION=$(pod --version)
        echo "✅ CocoaPods is installed ($POD_VERSION)"
    else
        echo "❌ CocoaPods is NOT installed. Install it: sudo gem install cocoapods"
    fi

else
    echo "Skipping iOS checks: Not on macOS."
fi

echo ""
echo "--- Project Specific Checks ---"

# Check for eas.json
if [ -f "eas.json" ]; then
    echo "✅ eas.json found in current directory."
else
    echo "❌ eas.json NOT found. Run 'eas build:configure' in your project root."
fi

# Check for expo-dev-client (if you plan to build dev clients)
if grep -q "expo-dev-client" package.json; then
    echo "✅ expo-dev-client found in package.json (good for development builds)."
else
    echo "⚠️ expo-dev-client NOT found in package.json. Install it if you need development builds: npx expo install expo-dev-client"
fi

echo ""
echo "--- Verification Complete ---"
echo "Review the output above. '✅' means good, '❌' means critical issue, '⚠️' means warning."
echo "Address any '❌' or '⚠️' items before attempting 'eas build --local'."