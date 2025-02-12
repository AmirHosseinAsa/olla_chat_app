import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'objectbox.g.dart';
import 'models/chat.dart';

/// Provides access to the ObjectBox Store throughout the app.
class ObjectBox {
  /// The Store of this app.
  late final Store store;
  late final Box<Chat> chatBox;
  late final Box<ChatSession> sessionBox;

  ObjectBox._create(this.store) {
    chatBox = Box<Chat>(store);
    sessionBox = Box<ChatSession>(store);
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Store will be created in the documents directory
    final store = await openStore(directory: p.join(docsDir.path, "obx-db"));
    return ObjectBox._create(store);
  }
}
