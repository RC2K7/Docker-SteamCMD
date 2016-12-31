FROM debian:latest
MAINTAINER Ruben Castaneda <rubennc1994@gmail.com>

# Build Arguments
ARG GOSU_VERSION
ENV GOSU_VERSION ${GOSU_VERSION:-1.10}

ARG STEAM_USER
ENV STEAM_USER ${STEAM_USER:-"steam"}

ARG STEAM_HOME
ENV STEAM_HOME ${STEAM_HOME:-"/opt/steam"}

ARG STEAM_URL
ENV STEAM_URL ${STEAM_URL:-"http://media.steampowered.com/installer/steamcmd_linux.tar.gz"}

# Setup steam Account
RUN groupadd -r $STEAM_USER && useradd -rm -d $STEAM_HOME -g $STEAM_USER $STEAM_USER

# Install Dependencies
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget ca-certificates lib32gcc1

# Install Gosu
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Install SteamCMD
RUN set -x \
    && wget -qO- $STEAM_URL | gosu $STEAM_USER tar -xzvC $STEAM_HOME \
	&& gosu $STEAM_USER $STEAM_HOME/steamcmd.sh \
		+quit


# Cleanup
RUN set -x \
	&& rm -rf $STEAM_HOME/Steam/logs $STEAM_HOME/appcache/httpcache \
	&& find $STEAM_HOME/package -type f ! -name "steam_cmd_linux.installed" ! \
		-name "steam_cmd_linux.manifest" -delete \
	&& apt-get purge -y --auto-remove \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy Scripts
COPY scripts/* /usr/local/bin/

# Copy Entrypoint
COPY docker-entrypoint.sh /

# Set Entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["steamcmd"]