# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils qt4-build-multilib

DESCRIPTION="The GUI module for the Qt toolkit"

if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi

IUSE="+accessibility cups egl +glib gtkstyle mng nas nis qt3support tiff trace xinerama +xv"

REQUIRED_USE="
	gtkstyle? ( glib )
"

# cairo[-qt4] is needed because of bug 454066
RDEPEND="
	app-admin/eselect-qtgraphicssystem
	~dev-qt/qtcore-${PV}[aqua=,debug=,glib=,qt3support=,${MULTILIB_USEDEP}]
	~dev-qt/qtscript-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	media-libs/fontconfig[${MULTILIB_USEDEP}]
	media-libs/freetype:2[${MULTILIB_USEDEP}]
	media-libs/libpng:0=[${MULTILIB_USEDEP}]
	sys-libs/zlib[${MULTILIB_USEDEP}]
	virtual/jpeg:0[${MULTILIB_USEDEP}]
	!aqua? (
		x11-libs/libICE[${MULTILIB_USEDEP}]
		x11-libs/libSM[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXfixes[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXrender[${MULTILIB_USEDEP}]
		xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
		xv? ( x11-libs/libXv[${MULTILIB_USEDEP}] )
	)
	cups? ( net-print/cups[${MULTILIB_USEDEP}] )
	egl? ( media-libs/mesa[egl,${MULTILIB_USEDEP}] )
	glib? ( dev-libs/glib:2[${MULTILIB_USEDEP}] )
	gtkstyle? (
		x11-libs/cairo[-qt4,${MULTILIB_USEDEP}]
		x11-libs/gtk+:2[aqua=,${MULTILIB_USEDEP}]
	)
	mng? ( >=media-libs/libmng-1.0.9:=[${MULTILIB_USEDEP}] )
	nas? ( >=media-libs/nas-1.5[${MULTILIB_USEDEP}] )
	tiff? ( media-libs/tiff:0[${MULTILIB_USEDEP}] )
	!<dev-qt/qthelp-4.8.5:4
"
DEPEND="${RDEPEND}
	!aqua? (
		x11-proto/inputproto[${MULTILIB_USEDEP}]
		x11-proto/xextproto[${MULTILIB_USEDEP}]
		xinerama? ( x11-proto/xineramaproto[${MULTILIB_USEDEP}] )
		xv? ( x11-proto/videoproto[${MULTILIB_USEDEP}] )
	)
"
PDEPEND="
	qt3support? ( ~dev-qt/qt3support-${PV}[aqua=,debug=,${MULTILIB_USEDEP}] )
"

PATCHES=(
	"${FILESDIR}/${PN}-4.7.3-cups.patch" # bug 323257
	"${FILESDIR}/${PN}-4.8.5-dont-crash-on-broken-GIF-images.patch" # bug 508984
	"${FILESDIR}/${PN}-4.8.6-disable-gtk-theme-check.patch" # bug 491226
)

QT4_TARGET_DIRECTORIES="
	src/gui
	src/scripttools
	src/plugins/imageformats/gif
	src/plugins/imageformats/ico
	src/plugins/imageformats/jpeg
	src/plugins/imageformats/tga
	src/plugins/inputmethods"

pkg_setup() {
	use accessibility && QT4_TARGET_DIRECTORIES+=" src/plugins/accessible/widgets"
	use mng && QT4_TARGET_DIRECTORIES+=" src/plugins/imageformats/mng"
	use tiff && QT4_TARGET_DIRECTORIES+=" src/plugins/imageformats/tiff"
	use trace && QT4_TARGET_DIRECTORIES+=" src/plugins/graphicssystems/trace tools/qttracereplay"

	[[ ${CHOST} != *-darwin* ]] && QT4_TARGET_DIRECTORIES+=" tools/qtconfig"

	QCONFIG_ADD="
		mitshm tablet x11sm xcursor xfixes xinput xkb xrandr xrender xshape xsync
		fontconfig system-freetype gif png system-png jpeg system-jpeg
		$(usev accessibility)
		$(usev cups)
		$(use mng && echo system-mng)
		$(usev nas)
		$(usev nis)
		$(use tiff && echo system-tiff)
		$(usev xinerama)
		$(use xv && echo xvideo)"
	QCONFIG_REMOVE="no-freetype no-gif no-jpeg no-png no-gui"
	QCONFIG_DEFINE="$(use accessibility && echo QT_ACCESSIBILITY)
			$(use cups && echo QT_CUPS)
			$(use egl && echo QT_EGL)
			QT_FONTCONFIG QT_FREETYPE
			$(use gtkstyle && echo QT_STYLE_GTK)
			QT_IMAGEFORMAT_JPEG QT_IMAGEFORMAT_PNG
			$(use mng && echo QT_IMAGEFORMAT_MNG)
			$(use nas && echo QT_NAS)
			$(use nis && echo QT_NIS)
			$(use tiff && echo QT_IMAGEFORMAT_TIFF)
			QT_SESSIONMANAGER QT_SHAPE QT_TABLET QT_XCURSOR QT_XFIXES
			$(use xinerama && echo QT_XINERAMA)
			QT_XINPUT QT_XKB QT_XRANDR QT_XRENDER QT_XSYNC
			$(use xv && echo QT_XVIDEO)"
}

src_prepare() {
	qt4-build-multilib_src_prepare

	# Add -xvideo to the list of accepted configure options
	sed -i -e 's:|-xinerama|:&-xvideo|:' configure || die
}

src_configure() {
	myconf+="
		$(qt_use accessibility)
		$(qt_use cups)
		$(qt_use glib)
		$(qt_use mng libmng system)
		$(qt_use nas nas-sound system)
		$(qt_use nis)
		$(qt_use tiff libtiff system)
		$(qt_use egl)
		$(qt_use qt3support)
		$(qt_use gtkstyle)
		$(qt_use xinerama)
		$(qt_use xv xvideo)
		-system-libpng -system-libjpeg -system-zlib
		-no-sql-mysql -no-sql-psql -no-sql-ibase -no-sql-sqlite -no-sql-sqlite2 -no-sql-odbc
		-sm -xshape -xsync -xcursor -xfixes -xrandr -xrender -mitshm -xinput -xkb
		-fontconfig -no-svg -no-webkit -no-phonon -no-opengl"

	# bug 367045
	[[ ${CHOST} == *86*-apple-darwin* ]] && myconf+=" -no-ssse3"

	qt4-build-multilib_src_configure
}

src_install() {
	qt4-build-multilib_src_install

	# touch the available graphics systems
	dodir /usr/share/qt4/graphicssystems
	echo "default" > "${ED}"/usr/share/qt4/graphicssystems/raster || die
	echo "" > "${ED}"/usr/share/qt4/graphicssystems/native || die

	if has tools/qtconfig ${QT4_TARGET_DIRECTORIES}; then
		newicon tools/qtconfig/images/appicon.png qtconfig.png
		make_desktop_entry qtconfig 'Qt Configuration Tool' qtconfig 'Qt;Settings;DesktopSettings'
	fi
}

pkg_postinst() {
	qt4-build-multilib_pkg_postinst

	# raster is the default graphicssystem, set it on first install
	eselect qtgraphicssystem set raster --use-old
}
