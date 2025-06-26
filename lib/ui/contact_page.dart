import 'dart:io';
import 'dart:convert';
import 'package:agendamobile/helpers/contact_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';



var maskFormatter = new MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
);

class ContactPage extends StatefulWidget {
  final Contact? contact;
  ContactPage({this.contact});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  late Contact _editedContact;
  late String _appBarTitle;
  bool _userEdited = false;
  ContactHelper helper = ContactHelper();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _editedContact = Contact.fromMap(widget.contact!.toMap());
      _appBarTitle = _editedContact.name ?? "Editar Contato";
      _nameController.text = _editedContact.name ?? "";
      _phoneController.text = _editedContact.phone ?? "";
      _emailController.text = _editedContact.email ?? "";
      _cepController.text = _editedContact.cep ?? "";
      _cidadeController.text = _editedContact.cidade ?? "";
      _bairroController.text = _editedContact.bairro ?? "";
      _enderecoController.text = _editedContact.endereco ?? "";
      _numeroController.text = _editedContact.numero ?? "";
    } else {
      _editedContact = Contact();
      _appBarTitle = "Novo Contato";
    }
  }

  Future<void> _fetchViaCep(String cep) async {
    if (cep.isEmpty) return;
    final url = 'https://viacep.com.br/ws/$cep/json/';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['erro'] != true) {
          setState(() {
            _cidadeController.text = data['localidade'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _enderecoController.text = data['logradouro'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar CEP: $e');
    }
  }

  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Galeria"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Câmera"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
                if (_editedContact.img != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text("Remover imagem"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _editedContact.img = null;
                        _userEdited = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _pickImageFromSource(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _editedContact.img = pickedFile.path;
        _userEdited = true;
      });
    }
  }

  Future<void> _saveContact() async {
    if (_nameController.text.isNotEmpty) {
      _editedContact.name = _nameController.text;
      _editedContact.phone = _phoneController.text;
      _editedContact.email = _emailController.text;
      _editedContact.cep = _cepController.text;
      _editedContact.cidade = _cidadeController.text;
      _editedContact.bairro = _bairroController.text;
      _editedContact.endereco = _enderecoController.text;
      _editedContact.numero = _numeroController.text;
      if (_editedContact.id != null) {
        await helper.updateContact(_editedContact);
      } else {
        await helper.saveContact(_editedContact);
      }
      Navigator.pop(context, _editedContact);
    } else {
      FocusScope.of(context).requestFocus(_nameFocus);
    }
  }

  Future<bool> _requestPop() async {
    FocusScope.of(context).unfocus();
    if (!_userEdited) return true;
    final int? decision = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Salvar alterações?"),
          content: const Text("Você tem alterações não salvas. O que deseja fazer?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(0),
            ),
            TextButton(
              child: const Text("Descartar"),
              onPressed: () => Navigator.of(context).pop(1),
            ),
            TextButton(
              child: const Text("Salvar"),
              onPressed: () => Navigator.of(context).pop(2),
            ),
          ],
        );
      },
    );
    if (decision == 2) {
      await _saveContact();
      return false;
    } else if (decision == 1) {
      Navigator.of(context).pop();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _requestPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          backgroundColor: Colors.blueGrey[900],
          centerTitle: true,
          actions: [
            if (_editedContact.id != null &&
                (_editedContact.phone?.isNotEmpty ?? false))
              IconButton(
                icon: const Icon(Icons.phone),
                tooltip: 'Ligar',
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: _editedContact.phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Não foi possível iniciar a chamada.")),
                    );
                  }
                },
              ),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_editedContact.id != null)
              FloatingActionButton(
                heroTag: 'deleteButton',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Excluir contato'),
                      content: const Text('Tem certeza que deseja excluir este contato?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await helper.deleteContact(_editedContact.id!);
                    Navigator.pop(context); // volta para a lista após excluir
                  }
                },
                backgroundColor: Colors.red[800],
                child: const Icon(Icons.delete),
              ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'saveButton',
              onPressed: _saveContact,
              child: const Icon(Icons.save),
              backgroundColor: Colors.blueGrey[900],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  width: 140.0,
                  height: 140.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: _editedContact.img != null
                          ? FileImage(File(_editedContact.img!))
                          : const AssetImage("images/pessoaPadraoWhiteMode.png") as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(labelText: "Nome"),
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                keyboardType: TextInputType.emailAddress,
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Telefone"),
              keyboardType: TextInputType.phone,
              inputFormatters: [maskFormatter],
              onChanged: (text) {
                _userEdited = true;
              },
              ),
              TextField(
                controller: _cepController,
                decoration: const InputDecoration(labelText: "CEP"),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  _fetchViaCep(value);
                },
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
              TextField(
                controller: _cidadeController,
                decoration: const InputDecoration(labelText: "Cidade"),
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
              TextField(
                controller: _bairroController,
                decoration: const InputDecoration(labelText: "Bairro"),
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
              TextField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: "Endereço"),
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
              TextField(
                controller: _numeroController,
                decoration: const InputDecoration(labelText: "Número"),
                keyboardType: TextInputType.number,
                onChanged: (text) {
                  _userEdited = true;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
