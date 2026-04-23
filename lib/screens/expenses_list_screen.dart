// Οθόνη Επιθεώρησης Εξόδων (Υλοποίηση ΠΧ3).
import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Εισαγωγή του Helper για την επικοινωνία με τη SQLite.
import '../models/expense.dart'; // Εισαγωγή του μοντέλου Expense.
import 'package:intl/intl.dart'; // Χρήση για τη μορφοποίηση της ημερομηνίας σε αναγνώσιμη μορφή.
import 'add_expense_screen.dart'; // Εισαγωγή της οθόνης προσθήκης για τη λειτουργία της επεξεργασίας (Edit).

// Εμφανίζει όλα τα καταγεγραμμένα έξοδα σε μορφή λίστας και επιτρέπει τη διαγραφή ή επεξεργασία τους.
class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  List<Expense> _expenses = []; // Τοπική λίστα που αποθηκεύει τα έξοδα που ανακτώνται από τη βάση για προβολή στο UI.

  String _selectedFilter = 'ΣΗΜΕΡΑ'; // Μεταβλητή που κρατάει το τρέχον επιλεγμένο φίλτρο (Προεπιλογή: ΣΗΜΕΡΑ).

  @override
  void initState() {
    super.initState();
    _refreshExpenses(); // Αρχική φόρτωση των δεδομένων κατά την εκκίνηση της οθόνης.
  }

  // Μέθοδος ανάκτησης όλων των εξόδων από τη SQLite με βάση το επιλεγμένο φίλτρο (Υλοποίηση ΠΧ3).
  void _refreshExpenses() async {
    final data = await DatabaseHelper.instance.getFilteredExpenses(_selectedFilter); // Καλούμε τη μέθοδο getFilteredExpenses του Helper, η οποία εκτελεί το αντίστοιχο SQL query.

    setState(() { // Ενημερώνουμε την κατάσταση (State) για να ξανασχεδιαστεί η λίστα με τα νέα δεδομένα.
      _expenses = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Επιθεώρηση Εξόδων')),
      body: Column(
        children: [
          // Οριζόντιο μενού επιλογής φίλτρων (Chips) για γρήγορη πλοήγηση σε χρονικές περιόδους.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Επιτρέπει το πλάγιο σκρολάρισμα των φίλτρων
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: ['ΣΗΜΕΡΑ', 'ΧΘΕΣ', 'ΕΒΔΟΜΑΔΑ', 'ΜΗΝΑΣ', 'ΧΡΟΝΟΣ','ΟΛΑ'].map((filter) { // Δημιουργία κουμπιών (Chips) για κάθε χρονικό φίλτρο που ορίζει η εκφώνηση.
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    selectedColor: Colors.blue.shade100,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                        _refreshExpenses(); // Επαναφόρτωση δεδομένων μόλις αλλάξει το φίλτρο.
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1), // Διαχωριστική γραμμή μεταξύ φίλτρων και λίστας

          // Η λίστα των εξόδων
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν έξοδα για αυτή την περίοδο.'))
                : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.euro_symbol_rounded, color: Colors.redAccent),
                    title: Text('${expense.amount.toStringAsFixed(2)} €'), // Εμφάνιση ποσού με 2 δεκαδικά ψηφία
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(expense.timestamp)}\n'
                          'Κατηγορία: ${expense.categoryName ?? "Χωρίς Κατηγορία"}', // Εμφάνιση Κατηγορίας αντί τοποθεσίας
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Κουμπί Πληροφοριών: Εμφανίζει dialog με τις σημειώσεις και τις συντεταγμένες GPS.
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.blueAccent), // Άλλαξα το εικονίδιο σε info
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text('Λεπτομέρειες Εξόδου'),
                                  ],
                                ),
                                content: SingleChildScrollView( // Για να μην "κόβεται" αν οι λεπτομέρειες είναι πολλές
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Σημειώσεις:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                      const SizedBox(height: 5),
                                      // Εμφάνιση λεπτομερειών ή μηνύματος αν είναι κενές
                                      Text(
                                        (expense.details == null || expense.details!.isEmpty)
                                            ? "Δεν υπάρχουν επιπλέον λεπτομέρειες."
                                            : expense.details!,
                                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                                      ),
                                      const Divider(height: 30),
                                      const Text('Γεωγραφικά Δεδομένα:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text( // Εμφάνιση latitude και longitude που λήφθηκαν κατά την ΠΧ2.
                                              'Lat: ${expense.latitude.toStringAsFixed(6)}\nLong: ${expense.longitude.toStringAsFixed(6)}',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Διεύθυνση: ${expense.locationName ?? "Άγνωστη"}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Κλείσιμο'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Κουμπί Επεξεργασίας: Στέλνει τον χρήστη πίσω στη φόρμα καταγραφής με τα δεδομένα του εξόδου.
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddExpenseScreen(expenseToEdit: expense),
                              ),
                            );
                            _refreshExpenses(); // Ανανέωση της λίστας μετά την επιστροφή από την επεξεργασία.
                          },
                        ),
                        // Κουμπί διαγραφής: Αφαιρεί οριστικά το έξοδο από τη βάση δεδομένων.
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteExpense(expense.id!);
                            _refreshExpenses(); // Αφαίρεση από τη λίστα στο UI.
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Το έξοδο διαγράφηκε.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
  Είναι η υλοποίηση της Τρίτης Χρηστικής Περίπτωσης (ΠΧ3). Ο ρόλος του είναι:
  α) Προβολή Ιστορικού: Παρουσιάζει στον χρήστη όλα τα έξοδα που έχει καταγράψει σε μια οργανωμένη λίστα (Cards).
  β) Δυναμικό Φιλτράρισμα: Επιτρέπει την ταξινόμηση και προβολή των δεδομένων ανάλογα με τον χρόνο (π.χ. μόνο τα σημερινά ή μόνο του τρέχοντος μήνα), στέλνοντας δυναμικά queries στη SQLite.
  γ) Διαχείριση Δεδομένων (Edit/Delete): Παρέχει τα εργαλεία για τη διόρθωση λαθών (Επεξεργασία) ή την αφαίρεση καταγραφών (Διαγραφή).
  δ) Πλήρης Διαφάνεια (Details Dialog): Επιτρέπει στον χρήστη να δει τις κρυφές πληροφορίες κάθε εξόδου, όπως τις ακριβείς συντεταγμένες GPS και τις σημειώσεις που δεν φαίνονται στην κύρια λίστα.
*/