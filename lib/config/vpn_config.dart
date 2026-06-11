// Modifier VPN_ACCESS_CODE pour changer le code d'accès à l'onglet VPN
const String vpnAccessCode = '636669';

const String _serverPub = '+iB4pASiK+m8kQXPMxevKObTesE/Ya4ENpEbTtaALlg=';
const String _serverEndpoint = '51.159.165.27:51820';

const String wgConfigAndroid = '''[Interface]
PrivateKey = 2DqS6t2IVLSE4155QG2Gbmnv7uw49F7IPJm2qNl4eko=
Address = 10.0.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = $_serverPub
Endpoint = $_serverEndpoint
AllowedIPs = 51.159.165.27/32
PersistentKeepalive = 25
''';

const String wgConfigWindows = '''[Interface]
PrivateKey = +BMFzDrNkYVwbfmXdqzsMmX0F8ZEtHze6Jxwr2MMKkA=
Address = 10.0.0.3/24
DNS = 8.8.8.8

[Peer]
PublicKey = $_serverPub
Endpoint = $_serverEndpoint
AllowedIPs = 51.159.165.27/32
PersistentKeepalive = 25
''';
