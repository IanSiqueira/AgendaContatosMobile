import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final String contactTable = "contactTable";
final String idCollun = "idCollun";
final String nameCollun = "nameCollun";
final String phoneCollun = "phoneCollun";
final String emailCollun = "emailCollun";
final String imgCollun = "imgCollun";
final String cepCollun = "cepCollun";
final String cidadeCollun = "cidadeCollun";
final String bairroCollun = "bairroCollun";
final String enderecoCollun = "enderecoCollun";
final String numeroCollun = "numeroCollun";

class ContactHelper {
  static final ContactHelper _instance = ContactHelper.internal();

  factory ContactHelper() => _instance;

  ContactHelper.internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "contacts.db");

    return await openDatabase(
      path,
      version: 2, // versão atualizada
      onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE $contactTable("
                "$idCollun INTEGER PRIMARY KEY,"
                "$nameCollun TEXT,"
                "$phoneCollun TEXT,"
                "$imgCollun TEXT,"
                "$emailCollun TEXT,"
                "$cepCollun TEXT,"
                "$cidadeCollun TEXT,"
                "$bairroCollun TEXT,"
                "$enderecoCollun TEXT,"
                "$numeroCollun TEXT)"
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE $contactTable ADD COLUMN $cepCollun TEXT");
          await db.execute("ALTER TABLE $contactTable ADD COLUMN $cidadeCollun TEXT");
          await db.execute("ALTER TABLE $contactTable ADD COLUMN $bairroCollun TEXT");
          await db.execute("ALTER TABLE $contactTable ADD COLUMN $enderecoCollun TEXT");
          await db.execute("ALTER TABLE $contactTable ADD COLUMN $numeroCollun TEXT");
        }
      },
    );
  }
  Future<Contact> saveContact(Contact contact) async {
    Database dbContact = await db;
    contact.id = await dbContact.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact?> getContact(int id) async {
    Database dbContact = await db;
    List<Map<String, Object?>> maps = await dbContact.query(
      contactTable,
      columns: [
        idCollun,
        nameCollun,
        emailCollun,
        phoneCollun,
        imgCollun,
        cepCollun,
        cidadeCollun,
        bairroCollun,
        enderecoCollun,
        numeroCollun
      ],
      where: "$idCollun = ?",
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> deleteContact(int id) async {
    Database dbContact = await db;
    return await dbContact.delete(
      contactTable,
      where: "$idCollun = ?",
      whereArgs: [id],
    );
  }

  Future<int> updateContact(Contact contact) async {
    Database dbContact = await db;
    return await dbContact.update(
      contactTable,
      contact.toMap(),
      where: "$idCollun = ?",
      whereArgs: [contact.id],
    );
  }

  Future<List<Contact>> getAllContacts() async {
    Database dbContact = await db;
    List<Map<String, Object?>> listMap = await dbContact.rawQuery("SELECT * FROM $contactTable");
    List<Contact> listContact = [];
    for (Map<String, Object?> m in listMap) {
      listContact.add(Contact.fromMap(m));
    }
    return listContact;
  }

  Future<int?> getNumber() async {
    Database dbContact = await db;
    List<Map<String, Object?>> result = await dbContact.rawQuery("SELECT COUNT(*) as count FROM $contactTable");
    return Sqflite.firstIntValue(result);
  }

  Future close() async {
    Database dbContact = await db;
    await dbContact.close();
  }
}

class Contact {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? img;
  String? cep;
  String? cidade;
  String? bairro;
  String? endereco;
  String? numero;

  Contact();

  Contact.fromMap(Map<String, Object?> map) {
    id = map[idCollun] as int?;
    name = map[nameCollun] as String?;
    phone = map[phoneCollun] as String?;
    email = map[emailCollun] as String?;
    img = map[imgCollun] as String?;
    cep = map[cepCollun] as String?;
    cidade = map[cidadeCollun] as String?;
    bairro = map[bairroCollun] as String?;
    endereco = map[enderecoCollun] as String?;
    numero = map[numeroCollun] as String?;
  }

  Map<String, Object?> toMap() {
    final Map<String, Object?> map = {
      nameCollun: name,
      emailCollun: email,
      phoneCollun: phone,
      imgCollun: img,
      cepCollun: cep,
      cidadeCollun: cidade,
      bairroCollun: bairro,
      enderecoCollun: endereco,
      numeroCollun: numero,
    };

    if (id != null) {
      map[idCollun] = id!;
    }
    return map;
  }

  @override
  String toString() {
    return "Contato (id: $id, nome: $name, email: $email, telefone: $phone, img: $img, "
        "CEP: $cep, Cidade: $cidade, Bairro: $bairro, Endereço: $endereco, Número: $numero)";
  }
}
