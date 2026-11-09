import 'package:qesma_api/qesma_api.dart';

/// Expenses of one `expenseDate`, in the order the server sent them.
class ExpenseDay {
  const ExpenseDay(this.date, this.items);

  final Date date;
  final List<ExpenseView> items;
}

/// Groups the loaded list by `expenseDate`. The server sorts by date (newest first), so
/// equal dates are neighbours; this runs over the WHOLE loaded list, so a day that
/// continues on the next page keeps one header. Order is never changed.
List<ExpenseDay> groupByDate(List<ExpenseView> expenses) {
  final days = <ExpenseDay>[];
  for (final expense in expenses) {
    if (days.isNotEmpty && days.last.date == expense.expenseDate) {
      days.last.items.add(expense);
    } else {
      days.add(ExpenseDay(expense.expenseDate, [expense]));
    }
  }
  return days;
}
