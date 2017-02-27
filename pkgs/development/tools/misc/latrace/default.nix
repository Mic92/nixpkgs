{ stdenv, fetchurl
, automake, autoconf, flex_2_5_35, bison
, findXMLCatalogs, asciidoc, xmlto, docbook_xsl, docbook_xml_dtd_45
}:

stdenv.mkDerivation rec {
  name = "latrace-0.5.11";

  src = fetchurl {
    url = "https://people.redhat.com/jolsa/latrace/dl/${name}.tar.bz2";
    sha256 = "1mdx5mjj4k73aigq10gxxnm64hclwbs6c54izc09y7wczb5glniv";
  };

  nativeBuildInputs = [
    automake autoconf flex_2_5_35 bison
    asciidoc findXMLCatalogs xmlto docbook_xsl docbook_xml_dtd_45
  ];

  # autoreconfHooks fails here
  preConfigure = ''
    aclocal
    autoconf
  '';

  hardeningDisable = [ "format" ];

  meta = with stdenv.lib; {
    homepage = https://people.redhat.com/jolsa/latrace;
    description = "Trace library calls and get their statistics in a manner similar to the strace utility";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ mic92 ];
  };
}
