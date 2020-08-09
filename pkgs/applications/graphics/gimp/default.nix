{ stdenv
, lib
, fetchFromGitLab
, substituteAll
, autoreconfHook
, pkgconfig
, intltool
, babl
, gegl
, gtk3
, glib
, gdk-pixbuf
, isocodes
, pango
, cairo
, freetype
, fontconfig
, lcms
, libpng
, libjpeg
, poppler
, poppler_data
, libtiff
, libmng
, librsvg
, libwmf
, zlib
, libzip
, ghostscript
, aalib
, shared-mime-info
, python3
, libexif
, gettext
, makeWrapper
, xorg
, glib-networking
, libmypaint
, gexiv2
, harfbuzz
, mypaint-brushes1
, libwebp
, libheif
, libgudev
, openexr
, AppKit
, Cocoa
, gtk-mac-integration-gtk2
, meson
, ninja
, appstream-glib
, libarchive
, libXmu
, vala
, webkitgtk
, alsaLib
, gjs
, luajit
, libxslt
, xvfb_run
, dbus
, gobject-introspection
, gtk-doc
, docbook_xml_dtd_412
, docbook_xsl
, wrapGAppsHook
}:

let
  python = python3.withPackages (pp: [ pp.pygobject3 ]);
in stdenv.mkDerivation rec {
  pname = "gimp";
  version = "2.99";

  outputs = [ "out" "dev" ];

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "gimp";
    rev = "74d09904566a284c4f3cdee4530a050f6fa6a0d5";
    sha256 = "0n8v324xsn248qwf7fzsz843r1ag80fvl7q6x3hpks5cvx5ij9rb";
  };
  #src = fetchurl {
  #  url = "http://download.gimp.org/pub/gimp/v${lib.versions.majorMinor version}/${pname}-${version}.tar.bz2";
  #  sha256 = "4S+fh0saAHxCd7YKqB4LZzML5+YVPldJ6tg5uQL8ezw=";
  #};

  patches = [
    # to remove compiler from the runtime closure, reference was retained via
    # gimp --version --verbose output
    (substituteAll {
      src = ./remove-cc-reference.patch;
      cc_version = stdenv.cc.cc.name;
    })

    # Use absolute paths instead of relying on PATH
    # to make sure plug-ins are loaded by the correct interpreter.
    ./hardcode-plugin-interpreters.patch
  ];

  nativeBuildInputs = [
    pkgconfig
    intltool
    gettext
    makeWrapper
    meson
    vala
    libxslt
    ninja
    wrapGAppsHook
  ];

  buildInputs = [
    docbook_xml_dtd_412 docbook_xsl
    xvfb_run
    appstream-glib
    gobject-introspection
    webkitgtk
    gtk-doc
    dbus
    gjs
    luajit
    alsaLib
    libarchive
    libXmu
    babl
    gegl
    gtk3
    glib
    gdk-pixbuf
    pango
    cairo
    gexiv2
    harfbuzz
    isocodes
    freetype
    fontconfig
    lcms
    libpng
    libjpeg
    poppler
    poppler_data
    libtiff
    openexr
    libmng
    librsvg
    libwmf
    zlib
    libzip
    ghostscript
    aalib
    shared-mime-info
    libwebp
    libheif
    python
    libexif
    xorg.libXpm
    glib-networking
    libmypaint
    mypaint-brushes1
  ] ++ lib.optionals stdenv.isDarwin [
    AppKit
    Cocoa
    gtk-mac-integration-gtk2
  ] ++ lib.optionals stdenv.isLinux [
    libgudev
  ];

  # needed by gimp-2.0.pc
  propagatedBuildInputs = [
    gegl
  ];

  # Check if librsvg was built with --disable-pixbuf-loader.
  PKG_CONFIG_GDK_PIXBUF_2_0_GDK_PIXBUF_MODULEDIR = "${librsvg}/${gdk-pixbuf.moduleDir}";

  preConfigure = ''
    # The check runs before glib-networking is registered
    export GIO_EXTRA_MODULES="${glib-networking}/lib/gio/modules:$GIO_EXTRA_MODULES"
  '';

  postPatch = ''
    patchShebangs ./tools/
  '';

  postFixup = ''
    wrapProgram $out/bin/gimp-${lib.versions.majorMinor version} \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE"
  '';

  passthru = rec {
    # The declarations for `gimp-with-plugins` wrapper,
    # used for determining plug-in installation paths
    majorVersion = "${lib.versions.major version}.0";
    targetPluginDir = "lib/gimp/${majorVersion}/plug-ins";
    targetScriptDir = "share/gimp/${majorVersion}/scripts";

    # probably its a good idea to use the same gtk in plugins ?
    gtk = gtk3;
  };

  configureFlags = [
    "--without-webkit" # old version is required
    "--disable-check-update"
    "--with-bug-report-url=https://github.com/NixOS/nixpkgs/issues/new"
    "--with-icc-directory=/run/current-system/sw/share/color/icc"
    # fix libdir in pc files (${exec_prefix} needs to be passed verbatim)
    "--libdir=\${exec_prefix}/lib"
  ];

  # on Darwin,
  # test-eevl.c:64:36: error: initializer element is not a compile-time constant
  doCheck = false;

  enableParallelBuilding = true;

  meta = with lib; {
    description = "The GNU Image Manipulation Program";
    homepage = "https://www.gimp.org/";
    maintainers = with maintainers; [ jtojnar ];
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
}
