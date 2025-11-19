part of 'package:patient_tracker/app_modules.dart';

/// ===================== Models & helpers =====================
/// Safe input dialog: uses the dialog's own context to avoid calling into a disposed widget tree
Future<String?> promptText(BuildContext context, String title) async {
  final controller = TextEditingController();

  final result = await fadeDialog<String>(
    context,
    Builder(
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Type here...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  controller.dispose(); // Release controller resources
  return result;
}
