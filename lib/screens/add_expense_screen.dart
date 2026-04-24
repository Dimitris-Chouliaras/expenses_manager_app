// Η φόρμα για την καταγραφή εξόδου με αυτόματη λήψη τοποθεσίας και ώρας (ΠΧ2).
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Πακέτο για την πρόσβαση στις υπηρεσίες τοποθεσίας.
import '../database/database_helper.dart'; // Εισαγωγή του Helper για την επικοινωνία με τη SQLite.
import '../models/category.dart'; // Εισαγωγή του μοντέλου Category.
import '../models/expense.dart'; // Εισαγωγή του μοντέλου Expense.
import 'dart:io'; // Χρήση για τον έλεγχο του λειτουργικού συστήματος (Platform).

// Επιτρέπει την εισαγωγή ποσού, επιλογή κατηγορίας και αυτόματη λήψη τοποθεσίας/ώρας.
// Υποστηρίζει επίσης τη λειτουργία επεξεργασίας (Edit) αν περαστεί ένα υπάρχον έξοδο.
class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit; // Αν είναι null, δημιουργούμε νέο. Αν έχει τιμή, κάνουμε edit.
  const AddExpenseScreen({super.key, this.expenseToEdit}); //

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Controllers για την ανάκτηση δεδομένων από τα πεδία εισαγωγής.
  final _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final _descController = TextEditingController();
  final _locNameController = TextEditingController();

  List<Category> _categories = []; // Λίστα που θα φιλοξενήσει τις κατηγορίες από τη ΒΔ.
  int? _selectedCategoryId;        // Αποθηκεύει την επιλογή του χρήστη.Τ

    @override
    void initState() {
      super.initState();
      _loadCategories(); // Φόρτωση των διαθέσιμων κατηγοριών με την έναρξη της οθόνης.

      // Αν η οθόνη άνοιξε για επεξεργασία, γεμίζουμε τα πεδία με τα υπάρχοντα δεδομένα.
      if (widget.expenseToEdit != null) {
        _amountController.text = widget.expenseToEdit!.amount.toString();
        _detailsController.text = widget.expenseToEdit!.details ?? '';
        _locNameController.text = widget.expenseToEdit!.locationName ?? '';
        _selectedCategoryId = widget.expenseToEdit!.categoryId;
      }
    }

  // Ανάκτηση των κατηγοριών από τη SQLite για να γεμίσει το Dropdown (ΠΧ2).
  void _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _categories = cats;
    });
  }

  // Εμφάνιση αναδυόμενου παραθύρου (Dialog) για δημιουργία κατηγορίας "on the fly".
  void _showQuickCategoryDialog() {
    // Χρειαζόμαστε δύο ελεγκτές τώρα
    final TextEditingController _quickTitleController = TextEditingController();
    final TextEditingController _quickDescController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Νέα Κατηγορία'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Για να μην πιάνει όλη την οθόνη το παράθυρο
            children: [
              TextField(
                controller: _quickTitleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Τίτλος',
                  hintText: 'π.χ. Super Market',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quickDescController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Περιγραφή (Προαιρετικό)',
                  hintText: 'π.χ. Έξοδα για το σπίτι',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Άκυρο'),
            ),
            ElevatedButton(
              onPressed: () async {
                String title = _quickTitleController.text.trim();
                String desc = _quickDescController.text.trim();

                if (title.isNotEmpty) {
                  // Δημιουργία αντικειμένου με τίτλο και περιγραφή
                  final newCat = Category(title: title, description: desc);

                  final result = await DatabaseHelper.instance.insertCategory(newCat);

                  if (!mounted) return;
                  if (result == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Η κατηγορία υπάρχει ήδη!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    Navigator.pop(context); // Κλείσιμο διαλόγου.
                    _loadCategories(); // Ανανέωση λίστας κατηγοριών.
                    setState(() {
                      _selectedCategoryId = result;
                    });
                  }
                } else {
                  // Αν ο τίτλος είναι άδειος, δείχνουμε μια ειδοποίηση
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ο τίτλος είναι υποχρεωτικός!')),
                  );
                }
              },
              child: const Text('Προσθήκη'),
            ),
          ],
        );
      },
    );
  }

  // Μέθοδος για τον έλεγχο αδειών και την ανάκτηση του στίγματος GPS.
  // Περιλαμβάνει έλεγχο αν το GPS είναι ενεργό και αν ο χρήστης έδωσε άδεια.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Έλεγχος αν οι υπηρεσίες τοποθεσίας είναι ενεργές στη συσκευή.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Το GPS είναι απενεργοποιημένο.');
    }

    // Διαχείριση αδειών χρήσης GPS.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Η άδεια τοποθεσίας απορρίφθηκε.');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  // Κύρια συνάρτηση αποθήκευσης του εξόδου (ΠΧ2).
  void _saveExpense() async {
    final amountText = _amountController.text;

    // Έλεγχος υποχρεωτικών πεδίων βάσει απαιτήσεων (Ποσό & Κατηγορία).
    if (amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ποσό και Κατηγορία είναι υποχρεωτικά!')),
      );
      return;
    }

    // Προετοιμασία μεταβλητών για το γεωγραφικό στίγμα.
    double lat = 0.0;
    double lng = 0.0;

    try {
      // Έλεγχος πλατφόρμας: Λήψη GPS μόνο σε πραγματικές συσκευές (Android/iOS).
      // Στα Windows χρησιμοποιούμε "καρφωτές" τιμές για αποφυγή σφαλμάτων.
      if (Platform.isAndroid || Platform.isIOS) {
        Position position = await _determinePosition();
        lat = position.latitude;
        lng = position.longitude;
      } else {
        // Mock data (συντεταγμένες Λάρισας) για περιβάλλον Windows/Desktop.
        lat = 39.6391;
        lng = 22.4191;
      }

      final expenseData = Expense(
        id: widget.expenseToEdit?.id, // Κρατάει το παλιό ID αν είναι edit
        amount: double.parse(amountText),
        timestamp: widget.expenseToEdit?.timestamp ?? DateTime.now(),
        details: _detailsController.text,
        categoryId: _selectedCategoryId!,
        latitude: lat,
        longitude: lng,
        locationName: _locNameController.text,
      );

      // Επιλογή αν θα γίνει εισαγωγή (νέο) ή ενημέρωση (edit).
      if (widget.expenseToEdit == null) {
        await DatabaseHelper.instance.insertExpense(expenseData);
      } else {
        await DatabaseHelper.instance.updateExpense(expenseData);
      }

    // Εμφάνιση μηνύματος επιτυχίας
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(widget.expenseToEdit == null
    ? 'Το έξοδο προστέθηκε επιτυχώς!' : 'Το έξοδο ενημερώθηκε επιτυχώς!'),
    backgroundColor: Colors.blue.shade800,
    duration: const Duration(seconds: 2),
    ),
    );

      if (!mounted) return;
      Navigator.pop(context); // Επιστροφή στην προηγούμενη οθόνη.
    } catch (e) {
      // Διαχείριση σφαλμάτων GPS χωρίς τη διακοπή της ροής της εφαρμογής.
      debugPrint("GPS Error: $e");
      // Ακόμα και αν αποτύχει το GPS, η εφαρμογή μπορεί να συνεχίσει (προαιρετικό GPS).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Καταγραφή Εξόδου')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField( // Πεδίο εισαγωγής χρηματικής αξίας.
              controller: _amountController,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.number, // Εμφάνιση αριθμητικού πληκτρολογίου.
              decoration: const InputDecoration(
                labelText: 'Χρηματική αξία (€)',
                hintText: "0.00", // Αχνό κείμενο ως παράδειγμα
                prefixIcon: Icon(Icons.euro),
              ),
              onChanged: (value) {
                if (value.contains(',')) { // Εισαγωγή ποσού με αυτόματη μετατροπή κόμματος σε τελεία για συμβατότητα με double.
                  String fixedValue = value.replaceAll(',', '.');
                  _amountController.value = TextEditingValue(
                    text: fixedValue,
                    selection: TextSelection.collapsed(offset: fixedValue.length), // Κρατάει τον κέρσορα στο τέλος
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Επιλογή κατηγορίας με κουμπί "+" για άμεση δημιουργία νέας κατηγορίας (Σύνδεση με ΠΧ1 μέσω Foreign Key).
            Row( // Row που περιέχει το Dropdown και το κουμπί "+"
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Κατηγορία Εξόδου',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                ),
                const SizedBox(width: 8), // Μικρή απόσταση ανάμεσα στα δύο widgets
                // Το κουμπί για τη γρήγορη προσθήκη
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 35),
                  onPressed: _showQuickCategoryDialog,
                  tooltip: 'Προσθήκη νέας κατηγορίας',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Προαιρετικό πεδίο περιγραφής.
            TextField(
              controller: _detailsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Λεπτομέρειες (Προαιρετικό)'),
            ),
            const SizedBox(height: 16),

            // Προαιρετικό πεδίο για την ονομασία της τοποθεσίας (ΠΧ2).
            TextField(
              controller: _locNameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Όνομα Τοποθεσίας (π.χ. Κατάστημα)',
                helperText: 'Οι συντεταγμένες GPS λαμβάνονται αυτόματα',
              ),
            ),
            const SizedBox(height: 32),

            // Κουμπί Αποθήκευσης.
            ElevatedButton.icon(
              onPressed: _saveExpense,
              icon: const Icon(Icons.save),
              label: const Text('Αποθήκευση Εξόδου'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16),
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
  Είναι η υλοποίηση της Δεύτερης Χρηστικής Περίπτωσης (ΠΧ2). Ο ρόλος του είναι:
  α) Καταγραφή Συναλλαγής: Επιτρέπει την εισαγωγή όλων των απαραίτητων στοιχείων ενός εξόδου (ποσό, κατηγορία, σημειώσεις).
  β) Αυτοματοποίηση GPS & Ώρας: Λαμβάνει αυτόματα το γεωγραφικό στίγμα (latitude/longitude) μέσω του πακέτου geolocator και την τρέχουσα ώρα, ικανοποιώντας τις απαιτήσεις για "αυτόματη λήψη" δεδομένων.
  γ) Ευελιξία (On-the-fly Category): Επιτρέπει στον χρήστη να δημιουργήσει μια νέα κατηγορία χωρίς να χρειάζεται να βγει από τη φόρμα του εξόδου, βελτιώνοντας σημαντικά την ταχύτητα χρήσης.
  δ) Διπλή Λειτουργικότητα (Add/Edit): Το ίδιο αρχείο χρησιμοποιείται τόσο για την πρώτη καταγραφή όσο και για την επεξεργασία ενός υπάρχοντος εξόδου.
  ε) Smart Formatting: Περιλαμβάνει κώδικα που μετατρέπει το κόμμα σε τελεία σε πραγματικό χρόνο, αποτρέποντας σφάλματα κατά τη μετατροπή του κειμένου σε αριθμό (double).
*/
