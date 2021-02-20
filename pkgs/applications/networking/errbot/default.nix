{ lib
, ansi
, buildPythonApplication
, colorlog
, daemonize
, deepmerge
, dulwich
, fetchFromGitHub
, flask
, glibcLocales
, hypchat
, irc
, jinja2
, markdown
, mock
, pyasn1
, pyasn1-modules
, pygments
, pygments-markdown-lexer
, pyopenssl
, pytestCheckHook
, requests
, slack-sdk
, sleekxmpp
, telegram
, webtest
}:

buildPythonApplication rec {
  pname = "errbot";
  version = "6.1.7";

  src = fetchFromGitHub {
    owner = "errbotio";
    repo = "errbot";
    rev = version;
    sha256 = "sha256-5/jyCeqhwYbW/YZfRFAYr7+p3+Aae3iK8T+kNhomBAo=";
  };

  LC_ALL = "en_US.utf8";

  buildInputs = [ glibcLocales ];

  propagatedBuildInputs = [
    webtest requests jinja2 flask dulwich deepmerge
    pyopenssl colorlog markdown ansi pygments
    daemonize pygments-markdown-lexer telegram irc slack-sdk

    sleekxmpp pyasn1 pyasn1-modules hypchat
  ];

  checkInputs = [ mock pytestCheckHook ];

  disabledTests = [
    # touches network
    "backup"
    "broken_plugin"
    "plugin_cycle"
  ];

  # we provide slack_sdk instead of the old slackclient
  pytestFlagsArray = [ "--ignore=tests/backend_tests/slack_test.py" ];

  meta = with lib; {
    description = "Chatbot designed to be simple to extend with plugins written in Python";
    homepage = "http://errbot.io/";
    maintainers = with maintainers; [ fpletz globin ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    # flaky on darwin, "RuntimeError: can't start new thread"
  };
}
