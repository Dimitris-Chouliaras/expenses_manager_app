// Οθόνη Επιθεώρησης Κατηγοριών (Υλοποίηση ΔΙΚΗ ΜΟΥ ΕΞΤΡΑ).
import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Εισαγωγή του Helper για την πρόσβαση στη βάση δεδομένων.
import '../models/category.dart'; // Εισαγωγή του μοντέλου Category.

// Οθόνη Διαχείρισης Κατηγοριών. Επιτρέπει την προβολή, επεξεργασία, διαγραφή και αναδιάταξη των κατηγοριών.
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<Category> _categories = []; // Τοπική λίστα που αποθηκεύει τις κατηγορίες που ανακτώνται από τη βάση.

  @override
  void initState() {
    super.initState();
    _refreshCategories(); // Αρχική φόρτωση των κατηγοριών μόλις ανοίξει η οθόνη.
  }

  // Μέθοδος ανάκτησης των κατηγοριών από τη SQLite και ανανέωση της οθόνης.
  void _refreshCategories() async {
    final data = await DatabaseHelper.instance.getAllCategories();
    setState(() => _categories = data);
  }

  // Εμφάνιση αναδυόμενου παραθύρου (Dialog) για την επεξεργασία υπάρχουσας κατηγορίας.
  void _showEditDialog(Category category) { // Controllers με προ-συμπληρωμένα τα τρέχοντα στοιχεία της κατηγορίας.
    final titleController = TextEditingController(text: category.title); // Προ-συμπλήρωση του τίτλου.
    final descController = TextEditingController(text: category.description); // Προ-συμπλήρωση της περιγραφής.

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Επεξεργασία Κατηγορίας'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Το παράθυρο προσαρμόζεται στο μέγεθος των περιεχομένων.
          children: [
            TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Τίτλος')),
            TextField(
                controller: descController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Περιγραφή')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ακύρωση')),
          ElevatedButton(
            onPressed: () async { // Ενημέρωση του αντικειμένου Dart με τις νέες τιμές από τα πεδία.
              category.title = titleController.text;
              category.description = descController.text;
              await DatabaseHelper.instance.updateCategory(category); // Κλήση της μεθόδου ενημέρωσης στη βάση δεδομένων SQLite
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Η κατηγορία ενημερώθηκε επιτυχώς!'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );

              Navigator.pop(context); // Κλείσιμο του διαλόγου.
              _refreshCategories(); // Ανανέωση της λίστας στην οθόνη.
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  // Μέθοδος που εμφανίζει διάλογο επιβεβαίωσης πριν τη διαγραφή.
  void _confirmDelete(BuildContext context, Category cat) async {
    // Ελέγχουμε αν έχει έξοδα
    bool hasExpenses = await DatabaseHelper.instance.categoryHasExpenses(cat.id!);

    if (!mounted) return;

    if (hasExpenses) {
      // ΔΙΑΛΟΓΟΣ ΓΙΑ ΚΑΤΗΓΟΡΙΑ ΜΕ ΕΞΟΔΑ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Προσοχή: Υπάρχουν Έξοδα"),
          content: Text("Η κατηγορία '${cat.title}' περιέχει καταγεγραμμένα έξοδα. "
              "Αν τη διαγράψετε, θα χαθούν οριστικά και όλα τα σχετικά έξοδα. "
              "Θέλετε να προχωρήσετε;"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.deleteCategoryAndExpenses(cat.id!); // Η νέα μέθοδος
                _refreshCategories();
              },
              child: const Text("ΔΙΑΓΡΑΦΗ ΟΛΩΝ", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // ΑΠΛΟΣ ΔΙΑΛΟΓΟΣ ΓΙΑ ΑΔΕΙΑ ΚΑΤΗΓΟΡΙΑ
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Επιβεβαίωση"),
          content: Text("Θέλετε να διαγράψετε την κατηγορία '${cat.title}';"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.deleteCategory(cat.id!);
                _refreshCategories();
              },
              child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  // Μέθοδος διαγραφής κατηγορίας με έλεγχο "RESTRICT" για το αν ήδη υπάρχουν δεδομένα (ακεραιότητα δεδομένων).
  void _deleteCategory(int id) async {
    bool hasExpenses = await DatabaseHelper.instance.categoryHasExpenses(id); // Κλήση της μεθόδου ελέγχου που φτιάξαμε στον Helper. Πριν τη διαγραφή, ελέγχουμε αν η κατηγορία περιέχει έξοδα.

    if (hasExpenses) { // Αν υπάρχουν έξοδα, ενημερώνουμε τον χρήστη ότι η διαγραφή απαγορεύεται (RESTRICT).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Δεν μπορείτε να διαγράψετε κατηγορία που έχει έξοδα!')),
      );
    } else { // Αν η κατηγορία είναι άδεια, προχωράμε στην οριστική διαγραφή από τη SQLite.
      await DatabaseHelper.instance.deleteCategory(id);
      _refreshCategories(); // Ανανέωση UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Διαχείριση Κατηγοριών')),
      body: _categories.isEmpty
          ? const Center(child: Text('Δεν υπάρχουν κατηγορίες.'))
          : ReorderableListView( // Χρήση ReorderableListView για τη λειτουργία Drag & Drop.
        onReorder: (oldIndex, newIndex) async { // Αυτή η συνάρτηση τρέχει όταν ο χρήστης αφήνει την κατηγορία σε νέα θέση
          setState(() {
            if (newIndex > oldIndex) { // Διόρθωση του index αν το στοιχείο μετακινηθεί προς τα κάτω.
              newIndex -= 1;
            }
            final Category item = _categories.removeAt(oldIndex); // Μετακίνηση του στοιχείου μέσα στην τοπική λίστα Dart.
            _categories.insert(newIndex, item);
          });

          // Ενημέρωση της στήλης 'position' στη βάση δεδομένων για να διατηρηθεί η νέα σειρά.
          await DatabaseHelper.instance.updateCategoryOrder(_categories);
        },
        children: _categories.map((cat) {
          return ListTile(
            key: ValueKey(cat.id), // Το Key είναι υποχρεωτικό στο ReorderableListView για την ταυτοποίηση των στοιχείων (να ξέρει το Flutter ποιο στοιχείο κουνήθηκε).
            title: Text(cat.title),
            subtitle: Text(cat.description ?? ''),
            trailing: Row( // Κουμπιά ενεργειών (Επεξεργασία και Διαγραφή).
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, cat), // Κλήση του διαλόγου επιβεβαίωσης.
                ),
                const SizedBox(width: 14), // Επιπλέον κενό δεξιά από το delete για να πάρει απόσταση από το εικονίδιο reorder (τρεις γραμμές).
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/*
  Είναι η υλοποίηση της ΔΙΚΗΣ ΜΟΥ ΕΞΤΡΑ Χρηστικής Περίπτωσης (ΠΧ?). Ο ρόλος του είναι:
  α) Διαχείριση Λίστας: Παρουσιάζει όλες τις κατηγορίες που έχει δημιουργήσει ο χρήστης σε μια δυναμική λίστα
  β) Δυναμικό Reordering: Υλοποιεί τη λειτουργία Drag & Drop μέσω του ReorderableListView, επιτρέποντας στον χρήστη να ορίσει τη σειρά προτεραιότητας των κατηγοριών, η οποία αποθηκεύεται μόνιμα στη βάση δεδομένων (στήλη position).
  γ) Επεξεργασία & Διόρθωση: Παρέχει τη δυνατότητα αλλαγής του τίτλου ή της περιγραφής μιας κατηγορίας μέσω ενός εύχρηστου διαλόγου (Edit Dialog).
  δ) Ασφαλής Διαγραφή: Ενσωματώνει έναν κρίσιμο μηχανισμό ασφαλείας. Πριν διαγράψει μια κατηγορία, ελέγχει αν υπάρχουν έξοδα συνδεδεμένα με αυτήν, προστατεύοντας τον χρήστη από την ακούσια απώλεια δεδομένων ή τη δημιουργία σφαλμάτων στη βάση (Data Integrity)
*/