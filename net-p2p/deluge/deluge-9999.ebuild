# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PYTHON_COMPAT=( python3_6 )
DISTUTILS_SINGLE_IMPL=1
PLOCALES="ar ast be bg bn bs ca cs cy da de el en_AU en_CA en_GB eo es et eu fa fi fr fy gl he hi hr hu id is it iu ja ka kk kn ko ku la lt lv mk ms nb nds nl pl pms pt pt_BR ro ru si sk sl sr sv ta th tl tlh tr uk vi zh_CN zh_HK zh_TW"
inherit distutils-r1 eutils l10n

DESCRIPTION="BitTorrent client with a client/server model"
HOMEPAGE="https://deluge-torrent.org/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.deluge-torrent.org/${PN}
		git://deluge-torrent.org/${PN}.git"
	EGIT_BRANCH="master"
	SRC_URI=""
else
	SRC_URI="http://download.deluge-torrent.org/source/${P}.tar.bz2"
	KEYWORDS="~amd64 ~arm ~ppc ~sparc ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="console geoip gtk libnotify sound webinterface"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	sound? ( gtk )
	libnotify? ( gtk )
"
CDEPEND=">=net-libs/libtorrent-rasterbar-1.2.0[python,${PYTHON_USEDEP}]"
DEPEND="${CDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-util/intltool"
RDEPEND="${CDEPEND}
	dev-python/chardet[${PYTHON_USEDEP}]
	dev-python/mako[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pyopenssl[${PYTHON_USEDEP}]
	dev-python/pyxdg[${PYTHON_USEDEP}]
	dev-python/rencode[${PYTHON_USEDEP}]
	dev-python/setproctitle[${PYTHON_USEDEP}]
	dev-python/service_identity[${PYTHON_USEDEP}]
	|| ( >=dev-python/twisted-16.0.0[${PYTHON_USEDEP}]
		>=dev-python/twisted-web-13.0[${PYTHON_USEDEP}]
	)
	dev-python/wheel[${PYTHON_USEDEP}]
	geoip? ( dev-python/geoip-python[${PYTHON_USEDEP}] )
	gtk? (
		sound? ( dev-python/pygame[${PYTHON_USEDEP}] )
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		gnome-base/librsvg
		libnotify? ( dev-python/notify-python )
	)
	webinterface? ( dev-python/mako[${PYTHON_USEDEP}] )"

python_prepare_all() {
	local args=(
		-e "/Compiling po file/a \\\tuptoDate = False"
	)
	#sed -i "${args[@]}" -- 'setup.py' || die
	args=(
		-e 's|"new_release_check": True|"new_release_check": False|'
		-e 's|"check_new_releases": True|"check_new_releases": False|'
		-e 's|"show_new_releases": True|"show_new_releases": False|'
	)
	sed -i "${args[@]}" -- 'deluge/core/preferencesmanager.py' || die

	local loc_dir="${S}/deluge/i18n"
	l10n_find_plocales_changes "${loc_dir}" "" ".po"
	rm_loc() {
		rm -vf "${loc_dir}/${1}.po" || die
	}
	l10n_for_each_disabled_locale_do rm_loc

	# Version
	sed -i "s/=_version/='1.3.15'/g" setup.py || die

	distutils-r1_python_prepare_all
}

esetup.py() {
	# bug 531370: deluge has its own plugin system. No need to relocate its egg info files.
	# Override this call from the distutils-r1 eclass.
	# This does not respect the distutils-r1 API. DONOT copy this example.
	set -- "${PYTHON}" setup.py "$@"
	echo "$@"
	"$@" || die
}

python_install_all() {
	distutils-r1_python_install_all
	if ! use console ; then
		rm -rf "${D}/usr/lib/python3.7/site-packages/deluge/ui/console/" || die
		rm -f "${D}/usr/bin/deluge-console" || die
		rm -f "${D}/usr/share/man/man1/deluge-console.1" ||die
	fi
	if ! use gtk ; then
		rm -rf "${D}/usr/lib/python3.7/site-packages/deluge/ui/gtk3/" || die
		rm -rf "${D}/usr/share/icons/" || die
		rm -f "${D}/usr/bin/deluge-gtk" || die
		rm -f "${D}/usr/share/man/man1/deluge-gtk.1" || die
		rm -f "${D}/usr/share/applications/deluge.desktop" || die
	fi
	if use webinterface; then
		newinitd "${FILESDIR}/deluge-web.init" deluge-web
		newconfd "${FILESDIR}/deluge-web.conf" deluge-web
	else
		rm -rf "${D}/usr/lib/python3.7/site-packages/deluge/ui/web/" || die
		rm -f "${D}/usr/bin/deluge-web" || die
		rm -f "${D}/usr/share/man/man1/deluge-web.1" || die
	fi
	newinitd "${FILESDIR}"/deluged.init-2 deluged
	newconfd "${FILESDIR}"/deluged.conf-2 deluged
}

pkg_postinst() {
	elog
	elog "If, after upgrading, deluge doesn't work, please remove the"
	elog "'~/.config/deluge' directory and try again, but make a backup"
	elog "first!"
	elog
	elog "To start the daemon either run 'deluged' as user"
	elog "or modify /etc/conf.d/deluged and run"
	elog "/etc/init.d/deluged start as root"
	elog "You can still use deluge the old way"
	elog
	elog "For more information look at https://dev.deluge-torrent.org/wiki/Faq"
	elog
}
