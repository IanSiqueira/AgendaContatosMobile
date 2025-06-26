// lib/ui/home_page.dart
import 'dart:io';
import 'package:agendamobile/helpers/contact_helper.dart';
import 'package:agendamobile/ui/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String formatPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11) {
    return '(${d.substring(0,2)}) ${d.substring(2,7)}-${d.substring(7)}';
  }
  return phone;
}

enum OrderOptions { orderaz, orderza }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final helper = ContactHelper();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() async {
    final list = await helper.getAllContacts();
    setState(() => contacts = list);
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contatos'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
        actions: [
          PopupMenuButton<OrderOptions>(
            onSelected: _order,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: OrderOptions.orderaz,
                  child: Text('Ordenar A→Z')),
              PopupMenuItem(
                  value: OrderOptions.orderza,
                  child: Text('Ordenar Z→A')),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openContact(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: contacts.length,
        itemBuilder: (_, i) => _card(i),
      ),
    );
  }

  Widget _card(int i) {
    final ct = contacts[i];
    return GestureDetector(
      onTap: () => _openContact(ct),
      onLongPress: () => _options(i),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: ct.img != null
                        ? FileImage(File(ct.img!))
                        : const AssetImage('images/pessoaPadraoWhiteMode.png')
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ct.name ?? '',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(ct.email ?? '',
                      style: const TextStyle(fontSize: 18)),
                  Text(formatPhone(ct.phone ?? ''),
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _options(int i) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _call(contacts[i].phone);
            },
            child:
            const Text('Ligar', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openContact(contacts[i]);
            },
            child:
            const Text('Editar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              helper.deleteContact(contacts[i].id!).then((_) => _reload());
            },
            child:
            const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openContact([Contact? ct]) async {
    final res = await Navigator.push<Contact?>(
      context,
      MaterialPageRoute(builder: (_) => ContactPage(contact: ct)),
    );
    if (res != null) _reload();
  }

  void _order(OrderOptions opt) {
    contacts.sort((a, b) {
      final na = a.name?.toLowerCase() ?? '';
      final nb = b.name?.toLowerCase() ?? '';
      return opt == OrderOptions.orderaz
          ? na.compareTo(nb)
          : nb.compareTo(na);
    });
    setState(() {});
  }
}
