echo Downloading latest from git repository...
# set -x

BUILDDISTRIBUTION=$1
GITSOURCE='https://github.com/FrodoVDR/svg-channellogos.git'

DEB_SOURCE_PACKAGE=`egrep '^Source: ' debian/control | cut -f 2 -d ' '`
DISTRIBUTION=`dpkg-parsechangelog | grep ^Distribution: | sed -e 's/^Distribution:\s*//'`
VERSION_UPSTREAM=`dpkg-parsechangelog | grep ^Version: | sed -e 's/^Version:\s*//' -e s/-[^-]*$// -e s/\.git.*//`
GIT_SHA_OLD=`git show --pretty=format:"%h" --quiet | head -1 || true`

if [ -d ${DEB_SOURCE_PACKAGE} ] ; then
        rm -rf ${DEB_SOURCE_PACKAGE}
fi

if [ -d ".git" ] ; then
	git pull
fi

VERSION_DATE=`/bin/date --utc +%0Y%0m%0d`
GITHEAD=`git rev-list HEAD | wc -l`
GITBUILD="$(printf '%04d' "$GITHEAD")"
BUILD=`/bin/date --utc +%H%M`

VERSION_FULL="${VERSION_UPSTREAM}.git${VERSION_DATE}.${BUILD}"

git clone --depth 1 ${GITSOURCE} ${DEB_SOURCE_PACKAGE}

cd ${DEB_SOURCE_PACKAGE}
GIT_SHA=`git show --pretty=format:"%h" --quiet | head -1 || true`
cd ..

CHKMAKE="/tmp/${DEB_SOURCE_PACKAGE}.make"
CHKFILE="/tmp/${DEB_SOURCE_PACKAGE}.exist"
[ -f ${CHKFILE} ] && rm ${CHKFILE}
	
if [ "x${GIT_SHA_OLD}" == "x${GIT_SHA}" ] ; then
        echo "Keine neue Version von ${DEB_SOURCE_PACKAGE} gefunden: ${GIT_SHA_OLD} = ${GIT_SHA}" | tee ${CHKFILE}
	if [ -f ${CHKMAKE} ] ; then
#		exit 1
		echo
	fi
fi

if [ $DISTRIBUTION != 'trusty' ] ; then
        DISTRIBUTION='trusty'
else
        DISTRIBUTION='precise'
fi

if [ ! -z $BUILDDISTRIBUTION ] ; then
        DISTRIBUTION=$BUILDDISTRIBUTION
fi

ARCHTYPEN="xz:J bz2:j gz:z"
for archtyp in  ${ARCHTYPEN}
do
	arch=`echo $archtyp | cut -d: -f1`
	pack=`echo $archtyp | cut -d: -f2`
	DEBSRCPKGFILE="../${DEB_SOURCE_PACKAGE}_${VERSION_FULL}.orig.tar.${arch}"
	DEBSRCPKGFILEBAK="${DEBSRCPKGFILE}.1"

	if [ -f ${DEBSRCPKGFILE} ] ; then
		mv ${DEBSRCPKGFILE} ${DEBSRCPKGFILEBAK}
	fi

	if [ -f ${DEBSRCPKGFILE} -o -f ${DEBSRCPKGFILEBAK} ] ; then
		echo "$DEBSRCPKGFILE or $DEBSRCPKGFILEBAK exists";
		continue;
	else
		echo $DEBSRCPKGFILE
		tar --exclude=.git --exclude=debian -c${pack}f ${DEBSRCPKGFILE} ${DEB_SOURCE_PACKAGE}
		rm -rf ${DEB_SOURCE_PACKAGE}

		dch -b -D ${DISTRIBUTION} -v "${VERSION_FULL}-0frodo0~${DISTRIBUTION}" "New upstream snapshot (commit ${GIT_SHA}), build ${GITBUILD}"
		break;
	fi
done

exit 0
