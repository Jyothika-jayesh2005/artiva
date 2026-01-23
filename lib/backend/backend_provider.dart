import 'backend.dart';
import 'fake_backend.dart';

// ✅ Keep ONE instance for entire app runtime
final Backend backend = FakeBackend();

// Later (after Firebase), you will change ONLY this line to:
// final Backend backend = FirebaseBackend();
