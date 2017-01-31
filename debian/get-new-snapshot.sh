#!/bin/bash
# set -x

DISTRIBUTION=trusty
GITSOURCE='https://github.com/FrodoVDR/channellogos.git'
BUILDPREFIX=yavdr
FORCEVERSION=''

DEB_SOURCE_PACKAGE=$(egrep '^Source: ' debian/control | cut -f 2 -d ' ')

PKGVERSION=$(dpkg-parsechangelog | sed -n 's/^Version: \(.*\)-.*/\1/p')
SUBVERSION=$(dpkg-parsechangelog | grep ^Version: | sed -e 's/^Version:\s*//' -e 's/~.*//g' | awk -F'-' '{ print $4 }' | sed -e "s/${BUILDPREFIX}.*//g")
if [ "$SUBVERSION" = '' ] ; then
	SUBVERSION=$(dpkg-parsechangelog | grep ^Version: | sed -e 's/^Version:\s*//' -e 's/~.*//g' | awk -F'-' '{ print $2 }' | sed -e "s/${BUILDPREFIX}.*//g")
fi

git pull origin
CHANGES=$(git log --pretty=format:"%h: %s" -1)

UPSTREAMVERSION="$(git describe --tags)"

GIT_SHA=$(git show --pretty=format:"%h" --quiet | head -1 || true)
test=$(grep ${GIT_SHA} debian/changelog)
if [ $? -eq 0 ] ; then
        SUBVERSION=$((SUBVERSION +1))
else
        SUBVERSION=0
fi

NEWVERSION=${UPSTREAMVERSION}-${SUBVERSION}${BUILDPREFIX}0~${DISTRIBUTION}

if [ ! -f ../${DEB_SOURCE_PACKAGE}_${VERSION_FULL}.orig.tar.xz ] ; then
        test=$(git config -l | grep xz)
        if [ $? -ne 0 ] ; then
                git config tar.tar.xz.command "xz -c"
        fi
        git archive --format=tar.xz --prefix=${DEB_SOURCE_PACKAGE}-${UPSTREAMVERSION}/ --output=../${DEB_SOURCE_PACKAGE}_${UPSTREAMVERSION}.orig.tar.xz origin/master
fi
dch -v ${FORCEVERSION}${NEWVERSION} -u medium -D ${DISTRIBUTION} --force-distribution "new upstream snapshot"
[ $? -ne 0 ] && exit 1
while read -r line ; do dch -a "${line}" ; done <<< "${CHANGES}"
debuild -S -sa

OTHERDISTRIBUTION=precise
OTHERVERSION=${UPSTREAMVERSION}-${SUBVERSION}${BUILDPREFIX}0~${OTHERDISTRIBUTION}
dch -v ${FORCEVERSION}${OTHERVERSION} --force-bad-version -u medium -D ${OTHERDISTRIBUTION} --force-distribution "rebuild for ${OTHERDISTRIBUTION}"
while read -r line ; do dch -a "${line}" ; done <<< "${CHANGES}"
debuild -S -sa

OTHERDISTRIBUTION=xenial
OTHERVERSION=${UPSTREAMVERSION}-${SUBVERSION}${BUILDPREFIX}0~${OTHERDISTRIBUTION}
dch -v ${FORCEVERSION}${OTHERVERSION} --force-bad-version -u medium -D ${OTHERDISTRIBUTION} --force-distribution "rebuild for ${OTHERDISTRIBUTION}"
while read -r line ; do dch -a "${line}" ; done <<< "${CHANGES}"
debuild -S -sa

exit 0
