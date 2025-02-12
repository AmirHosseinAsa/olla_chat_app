import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxModel {
  @Id() // Required annotation for ObjectBox entities
  int id = 0; // Must be non-nullable int with default value 0
}
