FROM debian:sid
MAINTAINER Ernest Artiaga <ernest.artiaga@eartiam.net>

ARG wine_tag
ARG gecko_tag
ARG mono_tag
ARG steam_user
ARG steam_uid

# Avoid issues with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# Enable contrib and non-free packages
RUN echo "deb http://deb.debian.org/debian sid contrib non-free" \
      >> /etc/apt/sources.list && \
    apt-get update -qy

# Install some useful packages
RUN apt-get install -qy apt zenity curl gnupg net-tools attr xattr

# Set up dnsmasq
RUN apt-get install -qy dnsmasq
COPY ./dnsmasq.conf /etc/dnsmasq.conf

# Install nvidia support files
RUN apt-get install -qy \
      libgl1-nvidia-glvnd-glx \
      nvidia-cg-dev \
      nvidia-driver \
      nvidia-opencl-dev

# Set up sudo
RUN apt-get install -qy sudo && \
    echo "$steam_user ALL = NOPASSWD: ALL" > /etc/sudoers.d/winesteam && \
    chmod 440 /etc/sudoers.d/winesteam

# User setup
ENV USER "$steam_user"
ENV UID "$steam_uid"
ENV HOME "/home/$steam_user"
RUN adduser --disabled-password --gecos 'Steam User' \
      --home "$HOME" --uid "$UID" "$USER" && \
    adduser "$USER" video && \
    adduser "$USER" audio && \
    mkdir -p "$HOME/data" && \
    chown "${USER}.${USER}" "$HOME/data"

# Build tools
RUN apt-get install -qy git build-essential autoconf-archive

# Download wine
ENV WINEHQ /opt/src/winehq
RUN mkdir -p "$WINEHQ" && cd "$WINEHQ" && \
    git clone git://source.winehq.org/git/wine.git && \
    cd "$WINEHQ/wine" && \
    git checkout "$wine_tag"

# Wine build dependencies
RUN apt-get install -qy flex bison
RUN apt-get install -qy \
      gettext \
      gstreamer1.0-plugins-base \
      libasound2-dev \
      libattr1-dev \
      libcdio-dev \
      libcups2-dev \
      libdbus-1-dev \
      libgegl-dev \
      libgettextpo-dev \
      libglu1-mesa-dev \
      libgnutls28-dev \
      libgphoto2-dev \
      libgsm1-dev \
      libgss-dev \
      libgstreamer-plugins-base1.0-dev \
      libgstreamer1.0-dev \
      libkrb5-dev \
      libjpeg-dev \
      liblcms2-dev \
      libldap2-dev \
      libmpg123-dev \
      libncurses-dev \
      libopenal-dev \
      libosmesa-dev \
      libpcap-dev \
      libpng-dev \
      libpulse-dev \
      libquicktime-dev \
      libsane-dev \
      libsdl2-dev \
      libtiff-dev \
      libudev-dev \
      libv4l-dev \
      libvkd3d-dev \
      libvulkan-dev \
      libx11-dev \
      libxcb-xinput-dev \
      libxcomposite-dev \
      libxcursor-dev \
      libxfixes-dev \
      libxft-dev \
      libxi-dev \
      libxinerama-dev \
      libxml2-dev \
      libxrandr-dev \
      libxrender-dev \
      libxslt1-dev \
      libxxf86dga-dev \
      libxxf86vm-dev \
      oss4-dev \
      zlib1g-dev

# Build wine 64
ENV WINEHQ64 "$WINEHQ/wine/_build64"
ENV WINE_CONFIGURE_OPTIONS "--without-capi --without-hal"
RUN mkdir "$WINEHQ64" && cd "$WINEHQ64" && \
    "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS --enable-win64 && \
    make

# Wine 32 build dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update -qy && \
    apt-get install -qy multiarch-support

RUN apt-get install -qy \
    gcc-multilib

RUN apt-get -o Dpkg::Options::="--force-overwrite" install -qy \
      gettext:i386 \
      gir1.2-ibus-1.0:i386 \
      gstreamer1.0-plugins-base:i386 \
      libasound2-dev:i386 \
      libattr1-dev:i386 \
      libcdio-dev:i386 \
      libcups2-dev:i386 \
      libdbus-1-dev:i386 \
      libgettextpo-dev:i386 \
      libglu1-mesa-dev:i386 \
      libgnutls28-dev:i386 \
      libgphoto2-dev:i386 \
      libgsm1-dev:i386 \
      libgstreamer-plugins-base1.0-dev:i386 \
      libgstreamer1.0-dev:i386 \
      libkrb5-dev:i386 \
      libjpeg-dev:i386 \
      liblcms2-dev:i386 \
      libldap2-dev:i386 \
      libmpg123-dev:i386 \
      libncurses-dev:i386 \
      libopenal-dev:i386 \
      libosmesa-dev:i386 \
      libpcap-dev:i386 \
      libpng-dev:i386 \
      libpulse-dev:i386 \
      libquicktime-dev:i386 \
      libsane-dev:i386 \
      libsdl2-dev:i386 \
      libtiff-dev:i386 \
      libudev-dev:i386 \
      libv4l-dev:i386 \
      libvkd3d-dev:i386 \
      libvulkan-dev:i386 \
      libx11-dev:i386 \
      libxcb-xinput-dev:i386 \
      libxcomposite-dev:i386 \
      libxcursor-dev:i386 \
      libxfixes-dev:i386 \
      libxft-dev:i386 \
      libxi-dev:i386 \
      libxinerama-dev:i386 \
      libxml2-dev:i386 \
      libxrandr-dev:i386 \
      libxrender-dev:i386 \
      libxslt1-dev:i386 \
      libxxf86dga-dev:i386 \
      libxxf86vm-dev:i386 \
      zlib1g-dev:i386

# Build wine 32
ENV WINEHQ32 "$WINEHQ/wine/_build32"
RUN mkdir "$WINEHQ32" && cd "$WINEHQ32" && \
    "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS && \
    make

# Build wine combo
ENV WINEHQ_COMBO "$WINEHQ/wine/_build"
RUN mkdir "$WINEHQ_COMBO" && cd "$WINEHQ_COMBO" && \
    "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS \
      --with-wine64="$WINEHQ64" --with-wine-tools="$WINEHQ32" && \
    make

# Install wine32
RUN cd "$WINEHQ_COMBO" && make install

# Install wine64
RUN cd "$WINEHQ64" && make install

# Install tools useful for wine and related tools
RUN apt-get install -qy \
      cabextract \
      lxterminal \
      mscompress

# Download winetricks
RUN mkdir -p "/usr/local/bin" && cd "/usr/local/bin" && \
    curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod a+x winetricks

# Download wine gecko
ENV GECKO_VERSION "$gecko_tag"
RUN mkdir -p "/usr/local/share/wine/gecko" && cd "/usr/local/share/wine/gecko" && \
    curl -O http://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine_gecko-$GECKO_VERSION-x86.msi && \
    curl -O http://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine_gecko-$GECKO_VERSION-x86_64.msi

# Download wine mono
ENV MONO_VERSION "$mono_tag"
RUN mkdir -p "/usr/local/share/wine/mono" && cd "/usr/local/share/wine/mono" && \
    curl -O http://dl.winehq.org/wine/wine-mono/$MONO_VERSION/wine_mono-$MONO_VERSION.msi

# Download steam installer
RUN mkdir -p "/usr/local/share/wine/steam" && cd "/usr/local/share/wine/steam" && \
    curl -O http://cdn.steampowered.com/download/SteamInstall.msi

# <OPTIONAL STARTS>
# Note: the following is not strictly necessary: it provides some pre-set
# environments useful for testing, but not persistent across launches...
# You may want to create your wine prefixes on the host, so they persist.
# The launch script assumes $HOME/data is used for that purpose.

# Setup wine prefixes and install core fonts
# Note that winecfg will complain about X not available,
# but it will initialize the wine settings anyway
ENV WINEPREFIX32 "$HOME/wn32"
RUN mkdir "$WINEPREFIX32" && chown "${USER}.${USER}" "$WINEPREFIX32" && \
    su "$USER" -c "WINEARCH=win32 WINEPREFIX=$WINEPREFIX32 winecfg" && \
    su "$USER" -c "WINEPREFIX=$WINEPREFIX32 winetricks corefonts"
ENV WINEPREFIX64 "$HOME/wn64"
RUN mkdir "$WINEPREFIX64" && chown "${USER}.${USER}" "$WINEPREFIX64" && \
    su "$USER" -c "WINEPREFIX=$WINEPREFIX64 winecfg" && \
    su "$USER" -c "WINEPREFIX=$WINEPREFIX64 winetricks corefonts"

# Force WinXP for steam
RUN su "$USER" -c "WINEPREFIX=$WINEPREFIX32 wine reg.exe ADD \"HKEY_CURRENT_USER\Software\Wine\AppDefaults\Steam.exe\" /v \"Version\" /t \"REG_SZ\" /d \"winxp\" /f" && \
    su "$USER" -c "WINEPREFIX=$WINEPREFIX32 wine reg.exe ADD \"HKEY_CURRENT_USER\Software\Wine\AppDefaults\steamwebhelper.exe\" /v \"Version\" /t \"REG_SZ\" /d \"winxp\" /f"
RUN su "$USER" -c "WINEPREFIX=$WINEPREFIX64 wine reg.exe ADD \"HKEY_CURRENT_USER\Software\Wine\AppDefaults\Steam.exe\" /v \"Version\" /t \"REG_SZ\" /d \"winxp64\" /f" && \
    su "$USER" -c "WINEPREFIX=$WINEPREFIX64 wine reg.exe ADD \"HKEY_CURRENT_USER\Software\Wine\AppDefaults\steamwebhelper.exe\" /v \"Version\" /t \"REG_SZ\" /d \"winxp64\" /f"

# <OPTIONAL ENDS>

# Start
COPY ./launch /launch
USER $USER
WORKDIR $HOME
ENTRYPOINT [ "/bin/bash", "/launch" ]

