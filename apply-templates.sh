#!/usr/bin/env bash
set -Eeuo pipefail

[ -f versions.json ] # run "versions.sh" first

jqt='.jq-template.awk'
if [ -n "${BASHBREW_SCRIPTS:-}" ]; then
	jqt="$BASHBREW_SCRIPTS/jq-template.awk"
elif [ "$BASH_SOURCE" -nt "$jqt" ]; then
	# https://github.com/docker-library/bashbrew/blob/master/scripts/jq-template.awk
	wget -qO "$jqt" 'https://github.com/docker-library/bashbrew/raw/9f6a35772ac863a0241f147c820354e4008edf38/scripts/jq-template.awk'
fi

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

generated_warning() {
	cat <<-EOH
		#
		# Automatically generated config file, please do not edit or modify.
		# All changes to this file will be overwritten.
		# For more information, please visit https://www.ServBay.com/.
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
		#

	EOH
}

for version; do
	export version

	rm -rf "$version"

	if jq -e '.[env.version] | not' versions.json > /dev/null; then
		echo "deleting $version ..."
		continue
	fi

	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"

	for dir in "${variants[@]}"; do
		suite="$(dirname "$dir")" # "buster", etc
		variant="$(basename "$dir")" # "cli", etc
		export suite variant

		alpineVer="${suite#alpine}" # "3.12", etc
		if [ "$suite" != "$alpineVer" ]; then
			from="alpine:$alpineVer"
		else
			from="debian:$suite-slim"
		fi
		export from alpineVer

		case "$variant" in
			apache) cmd='["apache2-foreground"]' ;;
			nginx) cmd='["php-fpm"]' ;;
			*) cmd='["php", "-a"]' ;;
		esac
		export cmd

		echo "processing $version/$dir ..."
		mkdir -p "$version/$dir"

		{
			generated_warning
			gawk -f "$jqt" 'Dockerfile-linux.template'
		} > "$version/$dir/Dockerfile"

		cp -a \
			docker-php-entrypoint \
			docker-php-ext-* \
			docker-php-source \
			index.php \
			supervisord.conf \
			"$version/$dir/"
		if [ "$variant" = 'apache' ]; then
			cp -a apache2-foreground "$version/$dir/"
		fi
		if [ "$variant" != 'apache' ]; then
			cp -a default "$version/$dir/"
		fi

		if [ "$variant" == 'apache' ]; then
			cat <<EOF >> "$version/$dir/supervisord.conf"

[program:apache2]
command=/usr/local/bin/apache2-foreground

EOF
		else
			cat <<EOF >> "$version/$dir/supervisord.conf"

[program:php]
command=/usr/local/php/sbin/php-fpm --nodaemonize

[program:nginx]
command=/usr/sbin/nginx -g 'daemon off;'

EOF
		fi

		IFS=. read -r major_version minor_version <<< "$version"
		if [[ "$major_version" -gt 8 ]] || { [[ "$major_version" -eq 8 ]] && [[ "$minor_version" -ge 1 ]]; }; then
			buildextra=true
		else
			buildextra=false
		fi

		if [[ "$version" == "8.0" ]]; then
			cp -a patch/php-openssl3/* "$version/$dir/"
		fi

		if [[ "$major_version" -le 7 ]]; then
			cp -a patch/php-openssl3/openssl.patch "$version/$dir/"
			if [[ "$minor_version" -ge 1 ]]; then
				cp -a patch/php-openssl3/openssl-2.patch "$version/$dir/"
			fi
		fi

		if [[ -d "./patch/php$version" ]]; then
			cp -a ./patch/php$version/* "$version/$dir/"
		fi

		cmd="$(jq <<<"$cmd" -r '.[0]')"
		if [ "$cmd" != 'php' ]; then
			os=$(uname -s)
			if [ "$os" = "Darwin" ]; then
				sed -i '' 's! php ! '"$cmd"' !g' "$version/$dir/docker-php-entrypoint"
			else
				sed -i -e 's! php ! '"$cmd"' !g' "$version/$dir/docker-php-entrypoint"
			fi
		fi
	done
done
