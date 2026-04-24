// Η φόρμα για τη δημιουργία κατηγοριών (ΠΧ1).
import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Εισαγωγή του Helper για την επικοινωνία με τη SQLite.
import '../models/category.dart'; // Εισαγωγή του μοντέλου Category.

// Χρησιμοποιούμε StatefulWidget γιατί η οθόνη διαχειρίζεται την κατάσταση (state) των πεδίων κειμένου και τη δυναμική αλλαγή του UI κατά την πληκτρολόγηση.
class AddCategoryScreen extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  // TextEditingControllers: Χρησιμοποιούνται για τον έλεγχο και την ανάκτηση του κειμένου που πληκτρολογεί ο χρήστης στα TextFields.
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Μέθοδος για την αποθήκευση της κατηγορίας στη βάση δεδομένων.
  void _saveCategory() async {
    final title = _titleController.text; // Λήψη τίτλου από τον controller.
    final desc = _descController.text;   // Λήψη περιγραφής από τον controller.

    // Έλεγχος εγκυρότητας: Ο τίτλος (Συνοπτική Φράση) είναι υποχρεωτικός βάσει εκφώνησης.
    if (title.isEmpty) {
      // Εμφάνιση SnackBar για ενημέρωση του χρήστη σε περίπτωση παράλειψης.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Παρακαλώ δώστε έναν τίτλο!')),
      );
      return; // Διακοπή της εκτέλεσης αν λείπει ο τίτλος.
    }

    // Δημιουργία νέου αντικειμένου Category με τα δεδομένα της φόρμας.
    final newCategory = Category(title: title, description: desc);

    // Κλήση της μεθόδου insertCategory του DatabaseHelper και λήψη του αποτελέσματος - Αποθηκεύουμε το αποτέλεσμα της εισαγωγής
    final result = await DatabaseHelper.instance.insertCategory(newCategory);

    if (!mounted) return; // Έλεγχος αν το Widget παραμένει στο δέντρο των Widgets μετά το await (ασφάλεια πλοήγησης).

  // ΕΛΕΓΧΟΣ: Αν το αποτέλεσμα είναι -1, η κατηγορία υπάρχει ήδη στην βάση
    if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Σφάλμα: Η κατηγορία υπάρχει ήδη!'),
          backgroundColor: Colors.red, // Κόκκινο χρώμα για σφάλμα
        ),
      );
      return; // Διακόπτουμε εδώ, δεν κλείνουμε την οθόνη ώστε ο χρήστης να διορθώσει το όνομα
    }

    // Αν η αποθήκευση πέτυχε (result != -1), ενημερώνουμε τον χρήστη.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Η κατηγορία δημιουργήθηκε επιτυχώς!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    if (!mounted) return; // Ελέγχουμε αν η οθόνη είναι ακόμα ενεργή πριν την κλείσουμε.
    Navigator.pop(context); // Κλείνει την τρέχουσα οθόνη και επιστρέφει τον χρήστη στην αρχική (Home Screen) μετά την επιτυχή αποθήκευση.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Νέα Κατηγορία')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField( // TextField για τη "Συνοπτική Φράση" (Τίτλος κατηγορίας).
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Συνοπτική Φράση (π.χ. Φαγητό)',border: OutlineInputBorder(),), // Προσθήκη πλαισίου για καλύτερη εμφάνιση.
            ),
            const SizedBox(height: 12),
            TextField( // TextField για την "Πλήρη Περιγραφή" (Προαιρετική).
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2, // Επιτρέπουμε περισσότερες γραμμές για την περιγραφή.
              decoration: const InputDecoration(labelText: 'Πλήρης Περιγραφή (Προαιρετικά)',border: OutlineInputBorder(),), // Προσθήκη πλαισίου για καλύτερη εμφάνιση.
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon( // Κουμπί υποβολής της φόρμας.
              onPressed: _saveCategory,
              icon: const Icon(Icons.save),
              label: const Text('Αποθήκευση Κατηγορίας'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800, // Χρώμα κουμπιού.
                foregroundColor: Colors.white), // Χρώμα κειμένου.
            ),
          ],
        ),
      ),
    );
  }
}

/*
  Είναι η υλοποίηση της Πρώτης Χρηστικής Περίπτωσης (ΠΧ1). Ο ρόλος του είναι:
  α) Διεπαφή Χρήστη (Form): Παρέχει τα πεδία εισαγωγής για τη δημιουργία μιας νέας κατηγορίας εξόδων.
  β) Επικύρωση Δεδομένων (Validation): Διασφαλίζει ότι ο χρήστης δεν αφήνει κενό το υποχρεωτικό πεδίο του τίτλου.
  γ) Έλεγχος Διπλοτύπων: Επικοινωνεί με τη βάση δεδομένων και ενημερώνει τον χρήστη αν προσπαθήσει να εισάγει μια κατηγορία που υπάρχει ήδη, αποτρέποντας τα σφάλματα και την περιττή επανάληψη δεδομένων.
  δ) Αλληλεπίδραση (User Feedback): Χρησιμοποιεί SnackBars για να δώσει άμεση οπτική επιβεβαίωση (επιτυχία ή σφάλμα) στον χρήστη.
*/