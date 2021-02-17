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
, slackclient
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
    ansi
    colorlog
    daemonize
    deepmerge
    dulwich
    flask
    hypchat
    irc
    jinja2
    markdown
    pyasn1
    pyasn1-modules
    pygments
    pygments-markdown-lexer
    pyopenssl
    requests
    slackclient
    sleekxmpp
    telegram
    webtest
  ];

  checkInputs = [
    mock
    pytestCheckHook
  ];

  # Slack backend test has an import issue
  pytestFlagsArray = [ "--ignore=tests/backend_tests/slack_test.py" ];

  disabledTests = [
    "backup"
    "broken_plugin"
    "plugin_cycle"
  ];

  pythonImportsCheck = [ "errbot" ];

  meta = with lib; {
    description = "Chatbot designed to be simple to extend with plugins written in Python";
    homepage = "http://errbot.io/";
    maintainers = with maintainers; [ fpletz globin ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    # flaky on darwin, "RuntimeError: can't start new thread"
  };
}
