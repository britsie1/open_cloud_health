import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_cloud_health/screens/profiles.dart';

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  var _isAuthenticating = false;
  bool? _canCheckBiometrics;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print(e);
    }
    if (!mounted) {
      return;
    }
    _canCheckBiometrics = canCheckBiometrics;
  }

  void _authenticate() async {
    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_supportState == _SupportState.supported && _canCheckBiometrics!) {
        await auth.authenticate(
          localizedReason: 'Let OS determine authentication method',
          options: const AuthenticationOptions(
            stickyAuth: true,
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication failed.'),
          ),
        );
      }
      setState(() {
        _isAuthenticating = false;
      });
    }

    if (!mounted) {
      return;
    }

    //TODO: check if there are multiple profiles, and if not, navigate to the dashboard of the first profile

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => const ProfilesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              margin: const EdgeInsets.only(
                top: 30,
                bottom: 40,
                left: 20,
                right: 20,
              ),
              width: 230,
              child: Image.asset('assets/images/logo.png'),
            ),
            Text(
              'OpenCloudHealth',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            if (_supportState == _SupportState.unsupported &&
                _canCheckBiometrics!)
              Container(
                margin: const EdgeInsets.all(20),
                child: Card(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning),
                          SizedBox(
                            width: 20,
                          ),
                          Flexible(
                            child: Text(
                              'Your device does not have a lock screen enabled. Please set up a lock screen to protect your data.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.lock_open),
              label: Text(_supportState == _SupportState.unsupported &&
                      _canCheckBiometrics!
                  ? 'Open anyway'
                  : 'Login'),
            ),
          ]),
        ),
      ),
    );
  }
}
