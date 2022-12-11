{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "matterbridge";
  version = "1.25.2";

  src = fetchFromGitHub {
    owner = "42wim";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-VqVrAmbKTfDhcvgayEE1wUeFBSTGczBrntIJQ5/uWzM=";
  };

  tags = [ "whatsappmulti" ];

  patches = [
    ./0001-whatsapp-allow-to-open-channel-with-users.patch
    ./0002-whatsapp-skip-checking-profile-images.patch
    ./0003-whatsapp-workaround-for-ratelimit.patch
  ];

  vendorSha256 = null;

  meta = with lib; {
    description = "Simple bridge between Mattermost, IRC, XMPP, Gitter, Slack, Discord, Telegram, Rocket.Chat, Hipchat(via xmpp), Matrix and Steam";
    homepage = "https://github.com/42wim/matterbridge";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ ryantm ];
    platforms = platforms.unix;
  };
}
