# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit qt4-build-multilib

DESCRIPTION="The Help module for the Qt toolkit"
SRC_URI+="
	compat? (
		ftp://ftp.qt.nokia.com/qt/source/qt-assistant-qassistantclient-library-compat-src-4.6.3.tar.gz
		http://dev.gentoo.org/~pesa/distfiles/qt-assistant-compat-headers-4.7.tar.gz
	)"

if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"
fi

IUSE="compat doc"

DEPEND="
	~dev-qt/qtcore-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	~dev-qt/qtgui-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	~dev-qt/qtsql-${PV}[aqua=,debug=,sqlite,${MULTILIB_USEDEP}]
	compat? (
		~dev-qt/qtdbus-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
		sys-libs/zlib[${MULTILIB_USEDEP}]
	)
"
RDEPEND="${DEPEND}"

QT4_TARGET_DIRECTORIES="
	tools/assistant/lib/fulltextsearch
	tools/assistant/lib
	tools/assistant/tools/qhelpgenerator
	tools/assistant/tools/qcollectiongenerator
	tools/assistant/tools/qhelpconverter
	tools/qdoc3"

pkg_setup() {
	use compat && QT4_TARGET_DIRECTORIES+="
		tools/assistant/compat
		tools/assistant/compat/lib"
}

src_unpack() {
	qt4-build-multilib_src_unpack

	# compat version
	# http://blog.qt.digia.com/blog/2010/06/22/qt-assistant-compat-version-available-as-extra-source-package/
	if use compat; then
		unpack qt-assistant-qassistantclient-library-compat-src-4.6.3.tar.gz \
			qt-assistant-compat-headers-4.7.tar.gz
		mv "${WORKDIR}"/qt-assistant-qassistantclient-library-compat-version-4.6.3 \
			"${S}"/tools/assistant/compat || die
		mv "${WORKDIR}"/QtAssistant "${S}"/include/ || die
	fi
}

src_prepare() {
	use compat && PATCHES+=("${FILESDIR}/${PN}-4.8.5-fix-compat.patch")

	qt4-build-multilib_src_prepare

	# prevent rebuild of QtCore and QtXml (bug 348034)
	sed -i -e '/^sub-qdoc3\.depends/d' doc/doc.pri || die
}

src_configure() {
	myconf+="
		-system-libpng -system-libjpeg -system-zlib
		-no-sql-mysql -no-sql-psql -no-sql-ibase -no-sql-sqlite2 -no-sql-odbc
		-sm -xshape -xsync -xcursor -xfixes -xrandr -xrender -mitshm -xinput -xkb
		-no-multimedia -no-opengl -no-phonon -no-qt3support -no-svg -no-webkit -no-xmlpatterns
		-no-nas-sound -no-cups -no-nis -fontconfig"

	qt4-build-multilib_src_configure
}

src_compile() {
	qt4-build-multilib_src_compile

	# qhelpgenerator needs libQtHelp.so.4
	export LD_LIBRARY_PATH=${S}/lib
	export DYLD_LIBRARY_PATH=${S}/lib:${S}/lib/QtHelp.framework

	if use doc; then
		emake docs
	elif [[ ${QT4_BUILD_TYPE} == release ]]; then
		# live ebuild cannot build qch_docs, it will build them through emake docs
		emake qch_docs
	fi
}

src_install() {
	qt4-build-multilib_src_install

	emake INSTALL_ROOT="${D}" install_qchdocs

	# do not compress .qch files
	docompress -x "${QT4_DOCDIR}"/qch

	if use doc; then
		emake INSTALL_ROOT="${D}" install_htmldocs
	fi

	if use compat; then
		insinto "${QT4_DATADIR#${EPREFIX}}"/mkspecs/features
		doins tools/assistant/compat/features/assistant.prf
	fi
}
