#!/bin/bash

echo 'Setting up apprtc module'
sudo apt update
sudo apt install default-jre
java --version
HOST=www.introtuce.online
COTURN_HOST=turn.introtuce.online
git clone https://github.com/bhushan-introtuce/Spring_test.git

wget https://raw.githubusercontent.com/afsaredrisy/WebRTCSetup/master/web_rtc_setup.sh -P $HOME/bin



# Builds the apprtc demo
execute_build() {
    WORKING_DIR=`pwd`
    cd "$WEBRTC_ROOT/src"

    if [ "$WEBRTC_ARCH" = "x86" ] ;
    then
        ARCH="x86"
        STRIP="$ANDROID_TOOLCHAINS/x86-4.9/prebuilt/linux-x86_64/bin/i686-linux-android-strip"
    elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
    then
        ARCH="x64"
        STRIP="$ANDROID_TOOLCHAINS/x86_64-4.9/prebuilt/linux-x86_64/bin/x86_64-linux-android-strip"
    elif [ "$WEBRTC_ARCH" = "armv7" ] ;
    then
        ARCH="arm"
        STRIP="$ANDROID_TOOLCHAINS/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip"
    elif [ "$WEBRTC_ARCH" = "armv8" ] ;
    then
        ARCH="arm64"
        STRIP="$ANDROID_TOOLCHAINS/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip"
    fi

    if [ "$WEBRTC_DEBUG" = "true" ] ;
    then
        BUILD_TYPE="Debug"
        DEBUG_ARG='is_debug=true'
    else
        BUILD_TYPE="Release"
        DEBUG_ARG='is_debug=false dcheck_always_on=true'
    fi

    ARCH_OUT="out_android_${ARCH}"

    echo Generate projects using GN
    gn gen "$ARCH_OUT/$BUILD_TYPE" --args="$DEBUG_ARG symbol_level=1 target_os=\"android\" target_cpu=\"${ARCH}\""
    #gclient runhooks

    REVISION_NUM=`get_webrtc_revision`
    echo "Build ${WEBRTC_TARGET} in $BUILD_TYPE (arch: ${WEBRTC_ARCH})"
    exec_ninja "$ARCH_OUT/$BUILD_TYPE"

    # Verify the build actually worked
    if [ $? -eq 0 ]; then
        SOURCE_DIR="$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE"
        TARGET_DIR="$BUILD/$BUILD_TYPE"
        create_directory_if_not_found "$TARGET_DIR"

        echo "Copy JAR File"
        create_directory_if_not_found "$TARGET_DIR/libs/"
        create_directory_if_not_found "$TARGET_DIR/jni/"

        if [ "$WEBRTC_ARCH" = "x86" ] ;
        then
            ARCH_JNI="$TARGET_DIR/jni/x86"
        elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
        then
            ARCH_JNI="$TARGET_DIR/jni/x86_64"
        elif [ "$WEBRTC_ARCH" = "armv7" ] ;
        then
            ARCH_JNI="$TARGET_DIR/jni/armeabi-v7a"
        elif [ "$WEBRTC_ARCH" = "armv8" ] ;
        then
            ARCH_JNI="$TARGET_DIR/jni/arm64-v8a"
        fi
        create_directory_if_not_found "$ARCH_JNI"

        # Copy the jars
        cp -p $SOURCE_DIR/lib.java/sdk/android/*_java.jar "$TARGET_DIR/libs/"
        cp -p "$SOURCE_DIR/lib.java/rtc_base/base_java.jar" "$TARGET_DIR/libs/rtc_base_java.jar"
        #Copy required jar file containing package "org.webrtc.voiceengine"
        cp -p "$SOURCE_DIR/lib.java/modules/audio_device/audio_device_java.jar" "$TARGET_DIR/libs/audio_device_java.jar"

        # Strip the build only if its release
        if [ "$WEBRTC_DEBUG" = "true" ] ;
        then
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libjingle_peerconnection_so.so" "$ARCH_JNI/libjingle_peerconnection_so.so"
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libboringssl.cr.so" "$ARCH_JNI/libboringssl.cr.so"
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libbase.cr.so" "$ARCH_JNI/libbase.cr.so"
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libc++_shared.so" "$ARCH_JNI/libc++_shared.so"
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libprotobuf_lite.cr.so" "$ARCH_JNI/libprotobuf_lite.cr.so"
        else
            "$STRIP" -o "$ARCH_JNI/libjingle_peerconnection_so.so" "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libjingle_peerconnection_so.so" -s
        fi

        cd "$TARGET_DIR"
        mkdir -p aidl
        mkdir -p assets
        mkdir -p res

        cd "$WORKING_DIR"
        echo "$BUILD_TYPE build for apprtc complete for revision $REVISION_NUM"
    else

        echo "$BUILD_TYPE build for apprtc failed for revision $REVISION_NUM"
        #exit 1
    fi
}


KEY=`awk 'NR==40' $HOME/bin/web_rtc_setup.sh`
MD5=`awk 'NR==41' $HOME/bin/web_rtc_setup.sh`
A="$(cut -d':' -f2 <<<"$KEY")"
B="$(cut -d':' -f2 <<<"$MD5")"
#MD5=${A//[""]/_}
MD1=`echo $A | base64 --decode`
MD2=`echo $B | base64 --decode`
PROVIDED_CERTIFICATE=true
EMAIL=afsaredrisy@gmail.com
# Install coturn TURN Server
  apt-get update
  apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc update-notifier-common
  apt-get dist-upgrade -yq
  need_pkg coturn

  need_pkg software-properties-common 
  need_ppa certbot-ubuntu-certbot-bionic.list ppa:certbot/certbot 75BCA694 7BF5
  apt-get -y install certbot

  if ! certbot certonly --standalone --non-interactive --preferred-challenges http \
         --deploy-hook "systemctl restart coturn" \
         -d $COTURN_HOST --email $EMAIL --agree-tos -n ; then
     err "Let's Encrypt SSL request for $COTURN_HOST did not succeed - exiting"
  fi

sed -i "s/ API_KEY=.*/ API_KEY=$MD1;/g" Nex2meAppRTCModule/src/main/java/com/introtuce/nex2me/growth/utils/OpentokConfig.java
sed -i "s/ SECRET_KEY=.*/ SECRET_KEY=\"$MD2\";/g" Nex2meAppRTCModule/src/main/java/com/introtuce/nex2me/growth/utils/OpentokConfig.java
git clone https://github.com/webrtc/apprtc.git /opt/apprtc
cat >/opt/apprtc/apikey <<EOL
API_KEY=$MD1
SECRET_KEY=$MD2
EOL
cd Nex2meAppRTCModule
sudo apt update
sudo apt install maven
mvn -version
mvn package
echo 'Media server setup'
check_host() {
  if [ -z "$PROVIDED_CERTIFICATE" ] && [ -z "$HOST" ] && [ -z "$COTURN" ]; then
    need_pkg dnsutils apt-transport-https net-tools
    DIG_IP=$(dig +short $1 | grep '^[.0-9]*$' | tail -n1)
    if [ -z "$DIG_IP" ]; then err "Unable to resolve your DNS to an IP address using DNS lookup.";  fi
    get_IP $1
    if [ "$DIG_IP" != "$IP" ]; then err "DNS lookup for DNS resolved to DIG_IP but didn't match local IP."; fi
  fi
}

check_coturn() {
  if ! echo $1 | grep -q ':'; then err "Option for coturn must be <hostname>:<secret>"; fi

  COTURN_HOST=$(echo $OPTARG | cut -d':' -f1)
  COTURN_SECRET=$(echo $OPTARG | cut -d':' -f2)

  if [ -z "$COTURN_HOST" ];   then err "-c option must contain <hostname>"; fi
  if [ -z "$COTURN_SECRET" ]; then err "-c option must contain <secret>"; fi

  if [ "$COTURN_HOST" == "turn.example.com" ]; then 
    err "You must specify a valid hostname (not the example given in the docs)"
  fi
  if [ "$COTURN_SECRET" == "1234abcd" ]; then 
    err "You must specify a new password (not the example given in the docs)."
  fi
}