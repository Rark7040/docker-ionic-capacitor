ARG JAVA_VERSION=17
ARG NODEJS_VERSION=20
# See https://developer.android.com/studio/index.html#command-tools
ARG ANDROID_SDK_VERSION=11076708
# See https://developer.android.com/tools/releases/build-tools
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
# See https://developer.android.com/studio/releases/platforms
ARG ANDROID_PLATFORMS_VERSION=34
# See https://gradle.org/releases/
ARG GRADLE_VERSION=8.2.1
# See https://www.npmjs.com/package/@ionic/cli
ARG IONIC_VERSION=7.2.0
# See https://www.npmjs.com/package/@capacitor/cli
ARG CAPACITOR_VERSION=6.0.0


FROM debian:trixie-slim AS base

ARG JAVA_VERSION

# General packages
RUN apt-get update -qy && \
    apt-get install -qy \
    apt-utils \
    locales \
    gnupg2 \
    build-essential \
    curl \
    usbutils \
    git \
    unzip \
    p7zip p7zip-full \
    python3 \
    openjdk-${JAVA_VERSION}-jre \
    openjdk-${JAVA_VERSION}-jdk \
    android-tools-adb && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*


FROM base AS gradle-resource

ARG GRADLE_VERSION

RUN mkdir /opt/gradle \
    && curl -sL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle-${GRADLE_VERSION}-bin.zip \
    && unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip \
    && rm gradle-${GRADLE_VERSION}-bin.zip


FROM base AS android-resource

ARG ANDROID_SDK_VERSION

RUN curl -sL https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -o commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip \
    && unzip commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip \
    && mkdir /opt/android-sdk && mv cmdline-tools /opt/android-sdk \
    && yes | /opt/android-sdk/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk --licenses \
    && rm commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip


FROM base AS final

LABEL MAINTAINER="Robin Genz <mail@robingenz.dev>"

ARG NODEJS_VERSION
ARG GRADLE_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORMS_VERSION
ARG IONIC_VERSION
ARG CAPACITOR_VERSION

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=ja_JP.UTF-8

# Set locale
RUN locale-gen ${LANG} && update-locale

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - && \
    apt-get update -qy && \
    apt-get install -qy nodejs && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
ENV NPM_CONFIG_PREFIX=${HOME}/.npm-global
ENV PATH=$PATH:${HOME}/.npm-global/bin

# Install Ionic CLI and Capacitor CLI
RUN npm install -g @ionic/cli@${IONIC_VERSION} \
    && npm install -g @capacitor/cli@${CAPACITOR_VERSION}

# Install Gradle
ENV GRADLE_HOME=/opt/gradle
COPY --from=gradle-resource /opt/gradle ${GRADLE_HOME}
ENV PATH=$PATH:/opt/gradle/gradle-${GRADLE_VERSION}/bin

# Install Android SDK tools
ENV ANDROID_HOME=/opt/android-sdk
COPY --from=android-resource /opt/android-sdk ${ANDROID_HOME}
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" "platforms;android-${ANDROID_PLATFORMS_VERSION}"
ENV PATH=$PATH:${ANDROID_HOME}/cmdline-tools/bin:${ANDROID_HOME}/platform-tools
