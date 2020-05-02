import 'package:dalk/app.dart';

void main() {
  Flavor.current = Flavor(Env.staging);
  launch();
}
