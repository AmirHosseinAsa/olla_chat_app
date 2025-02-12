import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';
import '../models/chat.dart';

class ObjectBox {
  late final Store store;
  late final Box<Chat> chatBox;
  late final Box<ChatSession> sessionBox;

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store =
        await openStore(directory: path.join(docsDir.path, "ollachat"));
    return ObjectBox._create(store);
  }

  ObjectBox._create(this.store) {
    chatBox = Box<Chat>(store);
    sessionBox = Box<ChatSession>(store);
  }
}

late ObjectBox objectbox;
