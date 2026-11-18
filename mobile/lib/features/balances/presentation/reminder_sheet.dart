import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_overlays.dart';
import '../../../core/widgets/money_text.dart';
import '../../profile/data/profile_repository.dart';
import '../application/reminder_formatter.dart';
import '../application/reminder_launcher.dart';
import '../application/reminder_tone_store.dart';
import '../domain/reminder_tone.dart';

/// Modal bottom sheet for composing and sending WhatsApp reminders with tones (SA9).
class ReminderSheet extends ConsumerStatefulWidget {
  const ReminderSheet({
    super.key,
    required this.debtorName,
    required this.amountMinor,
    required this.groupName,
    this.instapayHandle,
    this.initialTone = ReminderTone.soft,
  });

  final String debtorName;
  final int amountMinor;
  final String groupName;
  final String? instapayHandle;
  final ReminderTone initialTone;

  static Future<void> show(
    BuildContext context, {
    required String debtorName,
    required int amountMinor,
    required String groupName,
    String? instapayHandle,
    ReminderTone initialTone = ReminderTone.soft,
  }) {
    final l10n = AppLocalizations.of(context);
    return showAppBottomSheet<void>(
      context,
      title: l10n.reminderSheetTitle,
      subtitle: l10n.reminderSheetSubtitle,
      child: ReminderSheet(
        debtorName: debtorName,
        amountMinor: amountMinor,
        groupName: groupName,
        instapayHandle: instapayHandle,
        initialTone: initialTone,
      ),
    );
  }

  @override
  ConsumerState<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<ReminderSheet> {
  late ReminderTone _tone;
  late bool _includeInstapay;
  String? _instapayHandle;
  late final TextEditingController _controller;
  bool _toneLoadedFromStore = false;
  bool _edited = false; // the user typed in the field: async loads must not overwrite it
  bool _sending = false;

  bool get _hasInstapay =>
      _instapayHandle != null && _instapayHandle!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tone = widget.initialTone;
    _instapayHandle = widget.instapayHandle;
    _includeInstapay = _hasInstapay;
    _controller = TextEditingController();

    _loadStoredTone();
    if (_instapayHandle == null) {
      _loadInstapayHandle();
    }
  }

  Future<void> _loadInstapayHandle() async {
    try {
      final handles = await ref.read(profileRepositoryProvider).paymentHandles();
      if (mounted && handles.instapay != null && handles.instapay!.trim().isNotEmpty) {
        setState(() {
          _instapayHandle = handles.instapay!.trim();
          _includeInstapay = true;
          if (!_edited) _updateText();
        });
      }
    } catch (_) {
      // No handle available
    }
  }

  Future<void> _loadStoredTone() async {
    try {
      final stored = await ref.read(reminderToneStoreProvider).getLastTone();
      if (mounted && !_toneLoadedFromStore) {
        setState(() {
          _tone = stored;
          _toneLoadedFromStore = true;
          if (!_edited) _updateText();
        });
      }
    } catch (_) {
      // Keep default tone if store is not available
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.text.isEmpty) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateText() {
    _edited = false;
    final l10n = AppLocalizations.of(context);
    _controller.text = ReminderFormatter.formatMessage(
      l10n: l10n,
      tone: _tone,
      debtorName: widget.debtorName,
      amountMinor: widget.amountMinor,
      groupName: widget.groupName,
      instapayHandle: _instapayHandle,
      includeInstapay: _includeInstapay,
    );
  }

  void _onToneSelected(ReminderTone tone) {
    setState(() {
      _tone = tone;
      _toneLoadedFromStore = true; // an explicit pick wins over a late store load
      _updateText();
    });
    ref.read(reminderToneStoreProvider).setLastTone(tone).ignore();
  }

  void _onToggleInstapay(bool value) {
    setState(() {
      _includeInstapay = value;
      _updateText();
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await ref.read(reminderLauncherProvider).launchOrShare(text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _sending = false);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).reminderLaunchFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Debtor & Amount summary
        Container(
          padding: const EdgeInsets.all(QesmaSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(QesmaRadii.card),
            border: Border.all(color: context.colors.hairline),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: context.colors.primary),
                  const SizedBox(width: QesmaSpacing.sm),
                  Text(
                    widget.debtorName,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              MoneyText(widget.amountMinor, size: MoneySize.small),
            ],
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),

        // Tone Selector
        Text(
          l10n.reminderToneLabel,
          style: theme.textTheme.titleSmall?.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: QesmaSpacing.xs),
        Wrap(
          spacing: QesmaSpacing.sm,
          children: [
            for (final tone in ReminderTone.values)
              ChoiceChip(
                label: Text(switch (tone) {
                  ReminderTone.soft => l10n.reminderToneSoftChip,
                  ReminderTone.firm => l10n.reminderToneFirmChip,
                  ReminderTone.funny => l10n.reminderToneFunnyChip,
                }),
                selected: _tone == tone,
                onSelected: (selected) {
                  if (selected) _onToneSelected(tone);
                },
              ),
          ],
        ),
        const SizedBox(height: QesmaSpacing.md),

        // Optional InstaPay Toggle
        if (_hasInstapay) ...[
          SwitchListTile.adaptive(
            value: _includeInstapay,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminderIncludeInstapay, style: theme.textTheme.bodyMedium),
            subtitle: Text(
              _instapayHandle!,
              style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
            ),
            onChanged: _onToggleInstapay,
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],

        // Editable Message Field
        Text(
          l10n.reminderMessageFieldLabel,
          style: theme.textTheme.titleSmall?.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: QesmaSpacing.xs),
        TextField(
          controller: _controller,
          onChanged: (_) => _edited = true,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QesmaRadii.card),
              borderSide: BorderSide(color: context.colors.buttonBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QesmaRadii.card),
              borderSide: BorderSide(color: context.colors.buttonBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QesmaRadii.card),
              borderSide: BorderSide(color: context.colors.primary, width: 2),
            ),
            filled: true,
            fillColor: context.colors.card,
          ),
        ),
        const SizedBox(height: QesmaSpacing.lg),

        // Action Button: Open WhatsApp
        AppButton(
          label: l10n.reminderOpenWhatsapp,
          icon: Icons.chat_bubble_outline,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}
