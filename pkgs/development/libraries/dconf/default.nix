{ stdenv, fetchurl, meson, ninja, python3, vala, libxslt, pkgconfig, glib, bash-completion, dbus, gnome3
, libxml2, gtk-doc, docbook_xsl, docbook_xml_dtd_42 }:

let
  pname = "dconf";
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  version = "0.36.0";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${name}.tar.xz";
    sha256 = "0bfs069pjv6lhp7xrzmrhz3876ay2ryqxzc6mlva1hhz34ibprlz";
  };

  postPatch = ''
    chmod +x meson_post_install.py tests/test-dconf.py
    patchShebangs meson_post_install.py
    patchShebangs tests/test-dconf.py
  '';
  outputs = [ "out" "lib" "dev" ] ++ stdenv.lib.optional (stdenv.hostPlatform == stdenv.buildPlatform) "devdoc";

  strictDeps = true;

  nativeBuildInputs = [
    meson
    ninja
    vala
    pkgconfig
    python3
    libxslt
    libxml2
    gtk-doc
    docbook_xsl
    docbook_xml_dtd_42
    glib # for gdbus-codegen
  ];

  buildInputs = [
    glib
    bash-completion
    dbus
    vala # for vapigen.pc
  ];

  mesonFlags = [
    "--sysconfdir=/etc"
    # dconf-scan is not build with BUILD_CC
    "-Dgtk_doc=${if stdenv.hostPlatform == stdenv.buildPlatform then "true" else "false"}"
  ];

  doCheck = !stdenv.isAarch32 && !stdenv.isAarch64 && !stdenv.isDarwin;

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
    };
  };

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Projects/dconf;
    license = licenses.lgpl21Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = gnome3.maintainers;
  };
}
