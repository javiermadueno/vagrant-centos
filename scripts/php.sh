#!/usr/bin/env bash

VERSION="php"
VERSION_STRING="5.6"
PHP_MODULES=(common cli mysql gd mbstring xml tidy pear intl devel pdo pdo_mysql xdebug)
EXTRA_PACKAGES=()
TZ='UTC'
MEMORY_LIMIT=256
QUIET=false
EXEC_TIME=60

while getopts "hqv:t:m:e:" OPTION; do
	case ${OPTION} in
		v ) if [ "${OPTARG}" == "5.4" ]; then
				VERSION="php"
			elif [ "${OPTARG}" == "5.5" ]; then
				VERSION="php55w"
				USE_EPEL=true
			elif [ "${OPTARG}" == "5.6" ]; then
				VERSION="php56"
				USE_EPEL=true
			elif [ "${OPTARG}" == "7.0" ]; then
				VERSION="php70w"
				PHP_MODULES+=('opcache')
				USE_EPEL=true
			elif [ "${OPTARG}" == "7.1" ]; then
				VERSION="php71w"
				PHP_MODULES+=('opcache')
				EXTRA_PACKAGES+=('mod_php71w')
				USE_EPEL=true
			else
				${QUIET} || >&2 echo "Unsupported PHP version '${OPTARG}'"
				exit 1
			fi
			VERSION_STRING=${OPTARG}
			;;
		t ) TZ=${OPTARG}
			;;
		m ) MEMORY_LIMIT=${OPTARG}
			;;
		q ) QUIET=false
			;;
		e ) EXEC_TIME=${OPTARG}
		    ;;
		h ) usage
			exit 0
	esac
done

function usage() {
	echo -e "Syntax `basename $0` [-h] [-v version]
	-h Show this help
	-q Quiet mode
	-t Timezone to use for PHP.ini
	-m Memory limit for PHP.ini (in M)
	-e Max execution time for PHP.ini
	-v Set the version of PHP to install\n"
}

function run() {
	${QUIET} || echo "Installing PHP ${VERSION_STRING} (${VERSION})"
	
	
	yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	yum install -y yum-utils
	yum-config-manager --enable remi-${VERSION}
	#yum update
	
	yum install -y php ${PHP_MODULES[@]/#/php-}
	
	
	#cp -f /usr/share/doc/$VERSION-*/php.ini-development /etc/php.ini
	sed -i "s/;date\.timezone.*/date\.timezone = ${TZ}/g" /etc/php.ini
	sed -i "s/memory_limit.*/memory_limit = ${MEMORY_LIMIT}M/g" /etc/php.ini
	sed -i "s/max_execution_time.*/max_execution_time = ${EXEC_TIME}/g" /etc/php.ini

	${QUIET} || echo "Restarting apache"
	 if [ "`systemctl is-active httpd.service`" != "active" ]; then
		systemctl start httpd.service
	else
		systemctl restart httpd.service
	fi

	${QUIET} || echo "PHP Installed"
}

run
