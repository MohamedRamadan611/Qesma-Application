import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/theme/tokens.dart';
import '../application/expense_command_builder.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/expense_preview_controller.dart';
import 'itemized_breakdown_card.dart';
import 'itemized_charges_card.dart';
import 'itemized_items_card.dart';

/// The restaurant-bill editor (P8-01, revised in SA16), shown inside the add/edit form when the "Restaurant bill" tab is
/// selected: the items (by item or by person), the discount, service, tax and adjustment, then the per-person breakdown
/// and the payers banner. Each card lives in its own file; this shell only wires the preview and the two UI choices
/// (the assignment mode and the person shown in "by person").
///
/// Every amount drawn here that the user did not type (subtotal, discount, service, tax, per-person parts, total,
/// "payers match") is the server's, from the preview, and only while that preview is the answer for the bill as it is
/// now. Nothing is calculated here and nothing is added up.
class ItemizedEditor extends ConsumerStatefulWidget {
  const ItemizedEditor({
    super.key,
    required this.formKey,
    required this.form,
    required this.members,
    required this.nameOf,
    this.itemsSectionKey,
    this.chargesSectionKey,
    this.beforeBreakdown,
  });

  /// Shown between the charges and "each person's share" (the form screen puts "Who paid?" here).
  final Widget? beforeBreakdown;

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;
  final String Function(String) nameOf;

  /// Scroll targets for "go to the first error" (one key per section; the form screen owns them).
  final GlobalKey? itemsSectionKey;
  final GlobalKey? chargesSectionKey;

  @override
  ConsumerState<ItemizedEditor> createState() => _ItemizedEditorState();
}

class _ItemizedEditorState extends ConsumerState<ItemizedEditor> {
  AssignmentMode _mode = AssignmentMode.byItem;
  String? _personId;

  /// The preview for this exact bill came back as a validation error although every field is readable and a discount
  /// is on: the discount is what the engine refuses (it must stay below the items total, A171).
  static bool _discountTooLarge(PreviewState preview, String? splitKey, ExpenseFormState form, List<String> memberIds) {
    final failure = preview.failure;
    return splitKey != null &&
        preview.key == splitKey &&
        preview.status == PreviewStatus.failed &&
        failure is ApiHttpFailure &&
        failure.problem?.code == ApiErrorCode.validationError &&
        form.itemized.discountOn &&
        form.itemized.valid(memberIds);
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final controller = ref.read(expenseFormControllerProvider(widget.formKey).notifier);
    final memberIds = controller.memberIds;
    final splitCommand = buildItemizedPreview(form, memberIds: memberIds);
    final splitKey = splitCommand == null ? null : commandKey(splitCommand);
    final preview = ref.watch(expensePreviewControllerProvider((gid: widget.formKey.gid, slot: PreviewSlot.split)));
    final current = preview.isCurrentFor(splitKey) ? preview.preview : null;

    final matchCommand = buildItemizedPreview(form, memberIds: memberIds, withPayers: true);
    final matchKey = matchCommand == null ? null : commandKey(matchCommand);
    final match = ref.watch(expensePreviewControllerProvider((gid: widget.formKey.gid, slot: PreviewSlot.match)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: widget.itemsSectionKey,
          child: ItemsCard(
            formKey: widget.formKey,
            form: form,
            members: widget.members,
            current: current,
            mode: _mode,
            onMode: (mode) => setState(() => _mode = mode),
            personId: _personId,
            onPerson: (id) => setState(() => _personId = id),
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),
        KeyedSubtree(
          key: widget.chargesSectionKey,
          child: ChargesCard(formKey: widget.formKey, form: form, current: current, discountTooLarge: _discountTooLarge(preview, splitKey, form, memberIds)),
        ),
        const SizedBox(height: QesmaSpacing.md),
        if (widget.beforeBreakdown != null) ...[
          widget.beforeBreakdown!,
          const SizedBox(height: QesmaSpacing.md),
        ],
        BreakdownCard(
          formKey: widget.formKey,
          form: form,
          preview: preview,
          splitKey: splitKey,
          current: current,
          match: match,
          matchKey: matchKey,
          nameOf: widget.nameOf,
          yourMemberId: widget.members.where((m) => m.isYou).firstOrNull?.id,
        ),
      ],
    );
  }
}
