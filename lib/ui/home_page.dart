import 'dart:io';
import 'package:agendamobile/helpers/contact_helper.dart';
import 'package:agendamobile/ui/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum OrderOptions { orderaz, orderza }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ContactHelper helper = ContactHelper();
  List<Contact> contacts = <Contact>[];

  @override
  void initState() {
    super.initState();
    _getAllContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contatos"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<OrderOptions>(
            onSelected: _orderList,
            itemBuilder: (context) => <PopupMenuEntry<OrderOptions>>[
              const PopupMenuItem<OrderOptions>(
                child: Text("Ordenar de A - Z"),
                value: OrderOptions.orderaz,
              ),
              const PopupMenuItem<OrderOptions>(
                child: Text("Ordenar de Z - A"),
                value: OrderOptions.orderza,
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showContactPage();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return _contactCard(context, index);
        },
      ),
    );
  }

  Widget _contactCard(BuildContext context, int index) {
    final contact = contacts[index];
    return GestureDetector(
      onTap: () {
        _showContactPage(contact: contact);
      },
      onLongPress: () {
        _showOptions(context, index);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: contact.img != null
                        ? FileImage(File(contact.img!))
                        : const AssetImage("images/pessoaPadrao.png")
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    contact.name ?? "",
                    style: const TextStyle(
                        fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    contact.email ?? "",
                    style: const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.normal),
                  ),
                  Text(
                    contact.phone ?? "",
                    style: const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.normal),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _callContact(contacts[index].phone);
                  },
                  child: const Text(
                    "Ligar",
                    style: TextStyle(color: Colors.red, fontSize: 20.0),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showContactPage(contact: contacts[index]);
                  },
                  child: const Text(
                    "Editar",
                    style: TextStyle(color: Colors.blue, fontSize: 20.0),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteContact(index);
                  },
                  child: const Text(
                    "Excluir",
                    style: TextStyle(color: Colors.black, fontSize: 20.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _callContact(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print("Não foi possível realizar a chamada para $phone");
    }
  }

  void _deleteContact(int index) {
    final Contact contact = contacts[index];
    helper.deleteContact(contact.id!).then((_) {
      setState(() {
        contacts.removeAt(index);
      });
    });
  }

  void _showContactPage({Contact? contact}) async {
    final recContact = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactPage(contact: contact),
      ),
    );
    if (recContact != null) {
      _getAllContacts();
    }
  }

  void _getAllContacts() {
    helper.getAllContacts().then((list) {
      setState(() {
        contacts = list;
      });
    });
  }

  void _orderList(OrderOptions result) {
    switch (result) {
      case OrderOptions.orderaz:
        contacts.sort((a, b) {
          return (a.name?.toLowerCase() ?? '')
              .compareTo(b.name?.toLowerCase() ?? '');
        });
        break;
      case OrderOptions.orderza:
        contacts.sort((a, b) {
          return (b.name?.toLowerCase() ?? '')
              .compareTo(a.name?.toLowerCase() ?? '');
        });
        break;
    }
    setState(() {});
  }
}
