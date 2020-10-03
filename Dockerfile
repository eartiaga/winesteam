################
# BUILD 64-bit #
################

FROM debian:sid-slim as build64
MAINTAINER Ernest Artiaga <ernest.artiaga@eartiam.net>

ARG wine_tag="wine-5.17"

# Avoid issues with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# Enable repos and install packages
COPY ./enable-repos.sh /tmp/
COPY ./deps /tmp/deps
RUN /bin/sh /tmp/enable-repos.sh && \
        apt-get update -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/all.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/build.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/wine.dep | \
        xargs apt-get install -qy && \
        apt-get autoremove -qy && \
        rm -rf /var/lib/apt/lists/*

# Download wine
ENV WINEHQ /opt/src/winehq
RUN mkdir -p "$WINEHQ" && cd "$WINEHQ" && \
        git clone git://source.winehq.org/git/wine.git && \
        cd "$WINEHQ/wine" && \
        git checkout "$wine_tag"

# Build wine 64
ENV WINEHQ64 "$WINEHQ/wine/_build64"
ENV WINE_CONFIGURE_OPTIONS "--without-capi --without-hal"
RUN mkdir "$WINEHQ64" && cd "$WINEHQ64" && \
        "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS --enable-win64 && \
        make

################
# BUILD 32-bit #
################

FROM debian:sid-slim as build32
MAINTAINER Ernest Artiaga <ernest.artiaga@eartiam.net>

# Avoid issues with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# Enable repos and install packages
COPY ./enable-repos.sh /tmp/
COPY ./deps /tmp/deps
RUN /bin/sh /tmp/enable-repos.sh && \
        apt-get update -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/all.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/build.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/ {print $1 ":i386"}' /tmp/deps/wine.dep | \
        xargs apt-get install -qy && \
        apt-get autoremove -qy && \
        rm -rf /var/lib/apt/lists/*

# Copy build environment
ENV WINEHQ /opt/src/winehq
COPY --from=build64 ${WINEHQ} ${WINEHQ}

# Build wine 32
ENV WINEHQ32 "$WINEHQ/wine/_build32"
ENV WINE_CONFIGURE_OPTIONS "--without-capi --without-hal"
RUN mkdir "$WINEHQ32" && cd "$WINEHQ32" && \
        "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS && \ 
        make

# Build wine combo
ENV WINEHQ_COMBO "$WINEHQ/wine/_build"
ENV WINE_CONFIGURE_OPTIONS "--without-capi --without-hal"
RUN mkdir "$WINEHQ_COMBO" && cd "$WINEHQ_COMBO" && \
        "$WINEHQ/wine/configure" $WINE_CONFIGURE_OPTIONS \
        --with-wine64="$WINEHQ64" --with-wine-tools="$WINEHQ32" && \
        make

########
# WINE #
########

FROM debian:sid-slim as wine
MAINTAINER Ernest Artiaga <ernest.artiaga@eartiam.net>

ARG gecko_tag="2.47.1"
ARG mono_tag="5.1.0"
ARG steam_user="steam"
ARG steam_uid="1001"

# Avoid issues with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# Enable repos and install packages
COPY ./enable-repos.sh /tmp/
COPY ./deps /tmp/deps
RUN /bin/sh /tmp/enable-repos.sh && \
        apt-get update -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/all.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/tools.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/' /tmp/deps/runtime.dep | \
        xargs apt-get install -qy && \
        awk '$1 ~ /^[^#]/ {print $1 ":i386"}' /tmp/deps/runtime.dep | \
        xargs apt-get install -qy && \
        apt-get autoremove -qy && \
        rm -rf /var/lib/apt/lists/*

# Copy build environment
ENV WINEHQ /opt/src/winehq
ENV WINEHQ64 "$WINEHQ/wine/_build64"
ENV WINEHQ32 "$WINEHQ/wine/_build32"
ENV WINEHQ_COMBO "$WINEHQ/wine/_build"
COPY --from=build32 ${WINEHQ} ${WINEHQ}

# Install wine32
RUN cd "$WINEHQ_COMBO" && make install

# Install wine64
RUN cd "$WINEHQ64" && make install

# Download winetricks
RUN mkdir -p "/usr/local/bin" && cd "/usr/local/bin" && \
        curl -O https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
        chmod a+x winetricks

# Download wine gecko
ENV GECKO_VERSION "$gecko_tag"
RUN mkdir -p "/usr/local/share/wine/gecko" && cd "/usr/local/share/wine/gecko" && \
        curl -O \
        http://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine_gecko-$GECKO_VERSION-x86.msi && \
        curl -O \
        http://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine_gecko-$GECKO_VERSION-x86_64.msi

# Download wine mono
ENV MONO_VERSION "$mono_tag"
RUN mkdir -p "/usr/local/share/wine/mono" && cd "/usr/local/share/wine/mono" && \
        curl -O http://dl.winehq.org/wine/wine-mono/$MONO_VERSION/wine_mono-$MONO_VERSION.msi

# Download steam installer
RUN mkdir -p "/usr/local/share/wine/steam" && cd "/usr/local/share/wine/steam" && \
        curl -O "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe" && \
        chmod a+rx /usr/local/share/wine/steam/SteamSetup.exe

# Set up sudo
RUN echo "$steam_user ALL = NOPASSWD: ALL" > /etc/sudoers.d/winesteam && \ 
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

# Set up dnsmasq
COPY ./dnsmasq.conf /etc/dnsmasq.conf

## <OPTIONAL STARTS>
## Note: the following is not strictly necessary: it provides some pre-set
## environments useful for testing, but not persistent across launches...
## You may want to create your wine prefixes on the host, so they persist.
## The launch script assumes $HOME/data is used for that purpose.

## Setup wine prefixes and install core fonts
## Note that winecfg will complain about X not available,
## but it will initialize the wine settings anyway
ENV WINEPREFIX32 "$HOME/wn32"
RUN mkdir "$WINEPREFIX32" && chown "${USER}.${USER}" "$WINEPREFIX32" && \
        su "$USER" -c "WINEARCH=win32 WINEPREFIX=$WINEPREFIX32 winecfg" && \
        su "$USER" -c "WINEPREFIX=$WINEPREFIX32 winetricks corefonts"
ENV WINEPREFIX64 "$HOME/wn64"
RUN mkdir "$WINEPREFIX64" && chown "${USER}.${USER}" "$WINEPREFIX64" && \
        su "$USER" -c "WINEPREFIX=$WINEPREFIX64 winecfg" && \
        su "$USER" -c "WINEPREFIX=$WINEPREFIX64 winetricks corefonts"

## <OPTIONAL ENDS>

# Start
COPY ./launch /launch
USER $USER
WORKDIR $HOME
ENTRYPOINT [ "/bin/bash", "/launch" ]

