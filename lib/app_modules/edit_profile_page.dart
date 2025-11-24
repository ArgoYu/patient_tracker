part of 'package:patient_tracker/app_modules.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.initial});
  final PatientProfile initial;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameC, idC, notesC, avatarUrlC;
  @override
  void initState() {
    super.initState();
    nameC = TextEditingController(text: widget.initial.name);
    idC = TextEditingController(text: widget.initial.patientId);
    notesC = TextEditingController(text: widget.initial.notes ?? '');
    avatarUrlC = TextEditingController(text: widget.initial.avatarUrl ?? '');
  }

  @override
  void dispose() {
    nameC.dispose();
    idC.dispose();
    notesC.dispose();
    avatarUrlC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrlC.text.trim();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton(
                onPressed: () {
                  final updated = PatientProfile(
                      name: nameC.text.trim().isEmpty
                          ? widget.initial.name
                          : nameC.text.trim(),
                      patientId: idC.text.trim().isEmpty
                          ? widget.initial.patientId
                          : idC.text.trim(),
                      avatarUrl: url.isEmpty ? null : url,
                      notes: notesC.text.trim(),
                      email: widget.initial.email,
                      phoneNumber: widget.initial.phoneNumber);
                  Navigator.pop(context, updated);
                },
                child: const Text('Save'))
          ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
            child: CircleAvatar(
                radius: 40,
                backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                child:
                    url.isEmpty ? const Icon(Icons.person, size: 40) : null)),
        const SizedBox(height: 12),
        Glass(
            child: TextField(
                controller: avatarUrlC,
                decoration: const InputDecoration(
                    labelText: 'Avatar URL (image link)',
                    border: InputBorder.none))),
        const SizedBox(height: 12),
        Glass(
            child: TextField(
                controller: nameC,
                decoration: const InputDecoration(
                    labelText: 'Name', border: InputBorder.none))),
        const SizedBox(height: 12),
        Glass(
            child: TextField(
                controller: idC,
                decoration: const InputDecoration(
                    labelText: 'Patient ID', border: InputBorder.none))),
        const SizedBox(height: 12),
        Glass(
            child: TextField(
                controller: notesC,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: InputBorder.none),
                maxLines: 3)),
      ]),
    );
  }
}
