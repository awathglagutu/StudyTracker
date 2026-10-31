import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_session.dart';

class AddSessionScreen extends StatefulWidget {
  final StudySession? sessionToEdit;

  const AddSessionScreen({super.key, this.sessionToEdit});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  String? _subject;

  bool get _isEditing => widget.sessionToEdit != null;

  static const _subjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Computer Science',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sessionToEdit?.title ?? '');
    _durationController = TextEditingController(
      text: widget.sessionToEdit != null ? widget.sessionToEdit!.duration.toString() : '',
    );
    _notesController = TextEditingController(text: widget.sessionToEdit?.notes ?? '');
    _subject = widget.sessionToEdit?.subject;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveSession() {
    if (!_formKey.currentState!.validate()) return;
    final session = StudySession(
      id: widget.sessionToEdit?.id,
      title: _titleController.text.trim(),
      subject: _subject!,
      duration: int.parse(_durationController.text.trim()),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isFavorite: widget.sessionToEdit?.isFavorite ?? false,
      createdAt: widget.sessionToEdit?.createdAt,
    );
    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit study session' : 'New study session'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                _isEditing ? 'Update session details' : 'Capture what you studied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditing
                    ? 'Modify the details of your recorded session.'
                    : 'Add a few details to your session log.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 28),
              _fieldLabel(context, 'Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Chapter 4 revision',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              _fieldLabel(context, 'Subject'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: const InputDecoration(
                  hintText: 'Choose a subject',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: _subjects
                    .map((subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _subject = value),
                validator: (value) => value == null ? 'Choose a subject' : null,
              ),
              const SizedBox(height: 20),
              _fieldLabel(context, 'Duration'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'e.g. 60',
                  suffixText: 'minutes',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration <= 0) {
                    return 'Enter a duration greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _fieldLabel(context, 'Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Anything you want to remember?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saveSession,
                  icon: Icon(_isEditing ? Icons.save_rounded : Icons.check_rounded),
                  label: Text(_isEditing ? 'Save Changes' : 'Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      );
}
