{ stdenv
, fetchurl
, wrapGAppsHook
, autoPatchelfHook
, libjpeg
, libvpx
, icu63
, gtk3
, alsaLib
, nss
, libXt
, dbus-glib
, libpulseaudio
, gnome3
, gnome2
}:

stdenv.mkDerivation rec {
  name = "firefox-bin-unwrapped-${version}";
  version = "63.0.3-1";

  # TODO also add armv7
  src = fetchurl {
    url = "http://mirror.archlinuxarm.org/aarch64/extra/firefox-${version}-aarch64.pkg.tar.xz";
    sha256 = "1632l85hfp286i1iaklxjqj2kyjsiqpfnx24vfd52rhdk88pnsxs";
  };

  buildInputs = [
    wrapGAppsHook
    gtk3
    alsaLib
    nss
    libXt
    libpulseaudio
    libvpx
    icu63
    dbus-glib
    gnome3.defaultIconTheme
    autoPatchelfHook

    gnome2.startup_notification
  ];

  installPhase = ''
    mkdir -p $out/{,bin}
    cp -r * $out
    ln -s ${stdenv.lib.getLib libjpeg}/lib/libjpeg.so $out/lib/libjpeg.so.8

    rm $out/bin/firefox
    makeWrapper $out/lib/firefox/firefox $out/bin/firefox
  '';

  passthru.execdir = "/bin";
  passthru.ffmpegSupport = true;
  passthru.gssSupport = true;
  meta = with stdenv.lib; {
    description = "Mozilla Firefox, free web browser (binary package)";
    homepage = http://www.mozilla.org/firefox/;
    license = {
      free = false;
      url = http://www.mozilla.org/en-US/foundation/trademarks/policy/;
    };
    platforms = [ "aarch64-linux" ];
    maintainers = with maintainers; [ mic92 ];
  };
}
