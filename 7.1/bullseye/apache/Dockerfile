#
# Automatically generated config file, please do not edit or modify.
# All changes to this file will be overwritten.
# For more information, please visit https://www.ServBay.com/.
#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#

FROM debian:bullseye-slim AS builder

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -eux; \
	{ \
		echo 'Package: php*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-php

# dependencies required for running "phpize"
# (see persistent deps below)
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkg-config \
		re2c

# persistent / runtime deps
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
		ca-certificates \
		curl \
		xz-utils \
		wget \
        unzip \
	; \
	rm -rf /var/lib/apt/lists/*

ENV PHP_INI_DIR=/usr/local/php/etc
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

ENV APACHE_CONFDIR=/etc/apache2
ENV APACHE_ENVVARS=$APACHE_CONFDIR/envvars

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends apache2; \
	rm -rf /var/lib/apt/lists/*; \
	\
# generically convert lines like
#   export APACHE_RUN_USER=www-data
# into
#   : ${APACHE_RUN_USER:=www-data}
#   export APACHE_RUN_USER
# so that they can be overridden at runtime ("-e APACHE_RUN_USER=...")
	sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS"; \
	\
# setup directories and permissions
	. "$APACHE_ENVVARS"; \
	for dir in \
		"$APACHE_LOCK_DIR" \
		"$APACHE_RUN_DIR" \
		"$APACHE_LOG_DIR" \
	; do \
		rm -rvf "$dir"; \
		mkdir -p "$dir"; \
		chown "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$dir"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
		chmod 1777 "$dir"; \
	done; \
	\
# delete the "index.html" that installing Apache drops in here
	rm -rvf /var/www/html/*; \
	\
# logs should go to stdout / stderr
	ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log"; \
	ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log"; \
	ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log"; \
	chown -R --no-dereference "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$APACHE_LOG_DIR"

# Apache + PHP requires preforking Apache for best results
RUN a2dismod mpm_event && a2enmod mpm_prefork

# PHP files should be handled by PHP, and should be preferred over any other file type
RUN { \
		echo '<FilesMatch \.php$>'; \
		echo '\tSetHandler application/x-httpd-php'; \
		echo '</FilesMatch>'; \
		echo; \
		echo 'DirectoryIndex disabled'; \
		echo 'DirectoryIndex index.php index.html'; \
		echo; \
		echo '<Directory /var/www/>'; \
		echo '\tOptions -Indexes'; \
		echo '\tAllowOverride All'; \
		echo '</Directory>'; \
	} | tee "$APACHE_CONFDIR/conf-available/docker-php.conf" \
	&& a2enconf docker-php

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS A917B1ECDA84AEC2B568FED6F50ABC807BD5DCD0 528995BFEDFBA7191D46839EF9BA0ADA31CBD89E 1729F83938DA44E27BA0F4D3DBDB397470D12172

ENV PHP_VERSION=7.1.33
ENV PHP_URL="https://www.php.net/distributions/php-7.1.33.tar.gz" PHP_ASC_URL="https://www.php.net/distributions/php-7.1.33.tar.gz.asc"
ENV PHP_SHA256="0055f368ffefe51d5a4483755bd17475e88e74302c08b727952831c5b2682ea2"

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends gnupg; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -fsSL -o php.tar.gz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.gz" | sha256sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		curl -fsSL -o php.tar.gz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.gz.asc php.tar.gz; \
		gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

COPY docker-php-source /usr/local/bin/
COPY *.patch /tmp/patches/

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		apache2-dev \
		libargon2-dev \
		libcurl4-openssl-dev \
		libicu-dev \
		libonig-dev \
		libreadline-dev \
		libsodium-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
		zlib1g-dev \
	; \
	\
	export \
		PATH="$PATH:/usr/local/php/bin:/usr/local/php/sbin" \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
# https://github.com/php/php-src/blob/d6299206dd828382753453befd1b915491b741c6/configure.ac#L1496-L1511
		PHP_BUILD_PROVIDER='https://github.com/ServBay/PHP-Docker-Image' \
		PHP_UNAME='Linux - Docker (ServBay)' \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	# Apply PHP patches
	find /tmp/patches/ -maxdepth 1 -name "*.patch" -print0 | sort -zV | xargs -0 -I {} sh -c 'patch -p1 < "{}" && echo "Applied {}" || (echo "Failed to apply {}" >&2 && exit 0)'; \
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
# https://bugs.php.net/bug.php?id=74125
	if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi; \
	./configure \
		--prefix=/usr/local/php \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors instead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# https://github.com/docker-library/php/issues/822
		--with-pic \
		\
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash
# https://wiki.php.net/rfc/libsodium
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-curl \
		--with-iconv \
		--with-openssl \
		--with-readline \
		--with-zlib \
		--with-xsl \
		--enable-intl \
		--enable-mbregex \
		--enable-xml \
		\
# https://github.com/bwoebi/phpdbg-docs/issues/1#issuecomment-163872806 ("phpdbg is primarily a CLI debugger, and is not suitable for debugging an fpm stack.")
		--disable-phpdbg \
		\
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
		--with-pear \
		\
		--with-libdir="lib/$debMultiarch" \
		\
		--disable-cgi \
		\
		--with-apxs2 \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
# create symlinks for php-fpm and php-cli
	ln -s /usr/local/php/bin/* /usr/local/bin/; \
	ln -s /usr/local/php/sbin/* /usr/local/sbin/; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
# update pecl channel definitions https://github.com/docker-library/php/issues/443
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	\
# smoke test
	php --version

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

RUN	apt update && apt install -y --no-install-recommends \
	libargon2-dev \
	libcurl4-openssl-dev \
	libonig-dev \
	libreadline-dev \
	libsodium-dev \
	libsqlite3-dev \
	libssl-dev \
	libxml2-dev \
	libxslt-dev \
	zlib1g-dev

# GD
RUN apt update && apt install -y \
	zlib1g-dev \
	libfreetype-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd

# Imagick
RUN apt-get update && apt-get install -y \
    imagemagick \
    libmagickwand-dev \
    --no-install-recommends \
	&& curl -L -o /tmp/imagick.tar.gz https://github.com/Imagick/imagick/archive/7088edc353f53c4bc644573a79cdcd67a726ae16.tar.gz \
    && tar --strip-components=1 -xf /tmp/imagick.tar.gz \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && echo "extension=imagick.so" > /usr/local/php/etc/conf.d/docker-php-ext-imagick.ini \
    && rm -rf /tmp/* \

# Memcached
RUN apt update && apt install -y \
	libmemcached-dev \
	&& pecl install memcached-3.2.0 \
	&& docker-php-ext-enable memcached

# PGSQL
RUN apt update && apt install -y \
	libpq-dev \
	&& docker-php-ext-install pdo_pgsql pgsql \
	&& docker-php-ext-enable pdo_pgsql pgsql

# MySQL
RUN docker-php-ext-install mysqli pdo_mysql \
	&& docker-php-ext-enable mysqli pdo_mysql

# Redis
RUN pecl install redis \
	&& docker-php-ext-enable redis

# IMAP
RUN apt update && apt install -y \
	libc-client-dev \
	libkrb5-dev \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-install imap \
    && docker-php-ext-enable imap

# Misc modules
RUN apt update && apt install -y \
	libzip-dev \
	libtidy-dev \
	&& docker-php-ext-install zip opcache exif ftp sockets bcmath calendar gettext pcntl tidy \
    && docker-php-ext-enable zip opcache exif ftp sockets tidy bcmath calendar gettext pcntl


# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN docker-php-ext-enable sodium

# Runtime Image
FROM debian:bullseye-slim

ENV PHP_INI_DIR=/usr/local/php/etc
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/php/bin:/usr/local/php/sbin"

LABEL org.opencontainers.image.title="ServBay PHP Web Server" \
      org.opencontainers.image.description="PHP 7.1.33 with extensions for ServBay" \
      org.opencontainers.image.vendor="ServBay" \
      org.opencontainers.image.url="https://www.servbay.com" \
      org.opencontainers.image.source="https://github.com/ServBay/ServBay-Docker-Images" \
      org.opencontainers.image.version="7.1.33" \
    #   org.opencontainers.image.created="${BUILD_DATE}" \
    #   org.opencontainers.image.revision="${VCS_REF}"
      com.servbay.component="php-web-runtime" \
      com.servbay.maintainer="dev-team@servbay.com" \
      com.servbay.quality-tier="production"

# Install dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        redis \
        supervisor \
        curl \
		xz-utils \
		wget \
        unzip \
        libargon2-1 \
        libcurl4 \
        libonig5 \
        libsodium23 \
        libsqlite3-0 \
		libssl1.1 \
        libicu67 \
        libreadline8 \
        libxml2 \
        libxslt1.1 \
        zlib1g \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libmagickwand-6.q16-6 \
        libmemcached11 \
        libpq5 \
        libzip4 \
        libtidy5deb1 \
        libgssapi-krb5-2 \
        libc-client2007e \
        libodbc1; \
	\
	# Download the package to configure the Microsoft repo \
	curl -sSL -O https://packages.microsoft.com/config/debian/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2 | cut -d '.' -f 1)/packages-microsoft-prod.deb; \
	# Install the package \
	dpkg -i packages-microsoft-prod.deb; \
	# Delete the file \
	rm packages-microsoft-prod.deb; \
	\
	apt-get update; \
	ACCEPT_EULA=Y apt-get install -y --no-install-recommends unixodbc-dev; \
	\
	rm -rf /var/lib/apt/lists/*

# Copy files from builder
COPY --from=builder /usr/local/php /usr/local/php
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/sbin /usr/local/sbin

# Composer
RUN <<EOF
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
	chmod +x /usr/local/bin/composer
EOF

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/

RUN set -eux; \
	sed -i 's#daemonize yes#daemonize no#g' /etc/redis/redis.conf;

ENV APACHE_CONFDIR=/etc/apache2
ENV APACHE_ENVVARS=$APACHE_CONFDIR/envvars

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends apache2; \
	rm -rf /var/lib/apt/lists/*; \
	rm /var/www/html/*; \
	mkdir -p /var/www/html/public;

COPY --from=builder /etc/apache2 /etc/apache2
COPY --from=builder /usr/lib/apache2 /usr/lib/apache2
COPY index.php /var/www/html/public

RUN a2dismod mpm_event && a2enmod mpm_prefork

RUN set -eux; \
	sed -i 's#webmaster@localhost#docker-image@servbay.host#g' /etc/apache2/sites-enabled/000-default.conf; \
	sed -i 's#/var/www/html#/var/www/html/public#g' /etc/apache2/sites-enabled/000-default.conf;

# https://httpd.apache.org/docs/2.4/stopping.html#gracefulstop
STOPSIGNAL SIGWINCH

COPY apache2-foreground /usr/local/bin/
WORKDIR /var/www/html

EXPOSE 80 443


CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
