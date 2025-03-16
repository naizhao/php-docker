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

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS 0B96609E270F565C13292B24C13C70B87267B52D F38252826ACD957EF380D39F2F7956BC5DA04B5D 0BD78B5F97500D450838F95DFE857D9A90D90EC1

ENV PHP_VERSION=5.5.38
ENV PHP_URL="https://www.php.net/distributions/php-5.5.38.tar.gz" PHP_ASC_URL="https://www.php.net/distributions/php-5.5.38.tar.gz.asc"
ENV PHP_SHA256="4f458c9b504269615715a62f182b7c2f89bb8284f484befc221b56a1571b506e"

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
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
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
      org.opencontainers.image.description="PHP 5.5.38 with extensions for ServBay" \
      org.opencontainers.image.vendor="ServBay" \
      org.opencontainers.image.url="https://www.servbay.com" \
      org.opencontainers.image.source="https://github.com/ServBay/ServBay-Docker-Images" \
      org.opencontainers.image.version="5.5.38" \
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


RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends nginx; \
	rm -rf /var/lib/apt/lists/*; \
	mkdir -p /var/www/html/public

COPY default /etc/nginx/sites-enabled/default
COPY index.php /var/www/html/public

RUN set -eux; \
	rm /var/www/html/index.nginx-debian.html; \
	\
	cd /usr/local/php/etc; \
	if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; echo '; '; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; '; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/servbay-docker-fpm.ini"

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
