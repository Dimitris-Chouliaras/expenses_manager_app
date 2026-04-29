import 'package:ergasia_eksaminou/screens/category_list_screen.dart'; // Εισαγωγή της οθόνης εμφάνισης των κατηγοριών.
import 'package:flutter/material.dart';
import 'dart:io'; // Βιβλιοθήκη για την αναγνώριση του λειτουργικού συστήματος (Platform detection).
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Υποστήριξη SQLite για περιβάλλον Desktop.
import 'screens/add_category_screen.dart'; // Εισαγωγή της οθόνης προσθήκης κατηγορίας.
import 'screens/add_expense_screen.dart'; // Εισαγωγή της οθόνης προσθήκης για τη λειτουργία της επεξεργασίας (Edit).
import 'screens/expenses_list_screen.dart'; // Εισαγωγή της οθόνης εμφάνισης των εξόδων.
import 'screens/analysis_screen.dart'; // Εισαγωγή της οθόνης ανάλυσης των εξόδων.
import 'database/database_helper.dart';

// Η συνάρτηση main είναι το σημείο εκκίνησης της εφαρμογής(Entry Point).
void main() {
  // Έλεγχος αν η εφαρμογή εκτελείται σε Windows ή Linux.
  // Απαραίτητο βήμα για τη συμβατότητα της SQLite σε desktop περιβάλλον κατά την ανάπτυξη καθώς η sqflite από προεπιλογή υποστηρίζει μόνο Mobile (Android/iOS).
  if (Platform.isWindows || Platform.isLinux) {
    // Αρχικοποίηση της βάσης δεδομένων για μη-mobile πλατφόρμες.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyExpenseApp());
}

// Η κεντρική κλάση της εφαρμογής (Root Widget).
class MyExpenseApp extends StatelessWidget {
  const MyExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Αφαίρεση του debug banner για πιο καθαρό UI.
      title: 'Διαχείριση Εξόδων',

      theme: ThemeData( // Ρύθμιση του Light Theme (Ανοιχτόχρωμο θέμα).
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData( // Ρύθμιση του Dark Theme (Σκουρόχρωμο θέμα).
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          // Διόρθωση για το κείμενο μέσα στις κάρτες (π.χ. Συνολικά Έξοδα)
          onPrimaryContainer: Colors.white,
          // Διόρθωση για το κείμενο στα κουμπιά και στα chips
          onSecondaryContainer: Colors.black,
          primaryContainer: Colors.blueGrey[900],
        ),
      ),
      themeMode: ThemeMode.system, // Η εφαρμογή ακολουθεί αυτόματα τις ρυθμίσεις του λειτουργικού συστήματος.
      home: const MainHomeScreen(), // Ορισμός της αρχικής οθόνης που θα εμφανιστεί μόλις ανοίξει η εφαρμογή.
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

// Η αρχική οθόνη που περιλαμβάνει το κεντρικό μενού πλοήγησης (Drawer).
class _MainHomeScreenState extends State<MainHomeScreen> {
  double _todayTotal = 0.0;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayStats(); // Φόρτωση στατιστικών με το που ανοίγει η εφαρμογή
  }

  // Συνάρτηση για τον υπολογισμό των σημερινών εξόδων
  Future<void> _loadTodayStats() async {
    final db = DatabaseHelper.instance;
    final allExpenses = await db.getAllExpenses();

    // Παίρνουμε τη σημερινή ημερομηνία σε μορφή String (YYYY-MM-DD)
    String today = DateTime.now().toString().split(' ')[0];

    double total = 0;
    int count = 0;

    for (var exp in allExpenses) {
      if (exp.timestamp.toString().split(' ')[0] == today) {
        total += exp.amount;
        count++;
      }
    }
    setState(() {
      _todayTotal = total;
      _todayCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Manager'),
        centerTitle: true,
        elevation: 4,
         /* actions: [
          // Κουμπί ανανέωσης στην μπάρα
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayStats,
          )
        ], */
      ),
      // Drawer: Το πλαϊνό μενού που παρέχει πρόσβαση σε όλες τις λειτουργίες (ΠΧ1-ΠΧ4) + ΤΟ ΕΞΤΡΑ ΔΙΚΟ ΜΟΥ ΠΧ?.
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Αναβαθμισμένη Κεφαλίδα Μενού με Gradient (Διαβάθμιση χρώματος).
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500], // Το gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.account_balance_wallet, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Expense Manager',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Επιλογή 1: Δημιουργία Κατηγορίας (ΠΧ1).
            ListTile(
              leading: Icon(Icons.category, color: Colors.blue.shade700),
              title: const Text('Δημιουργία Κατηγορίας', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context); // Κλείνει το Drawer.
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategoryScreen()));
              },
            ),
            // Επιλογή 2: Διαχείριση Κατηγοριών (Reordering & Delete) (ΠΧ?).
            ListTile(
              leading: Icon(Icons.settings_suggest, color: Colors.blue.shade700),
              title: const Text('Διαχείριση Κατηγοριών', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryListScreen()));
                _loadTodayStats(); // Ανανεώνει τα στατιστικά στην αρχική οθόνη μόλις επιστρέψουμε
              },
            ),
            // Επιλογή 3: Καταγραφή Εξόδου (ΠΧ2).
            ListTile(
              leading: Icon(Icons.add_shopping_cart, color: Colors.blue.shade700),
              title: const Text('Καταγραφή Εξόδου', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
                _loadTodayStats(); // Ανανεώνει τα στατιστικά στην αρχική οθόνη μόλις επιστρέψουμε
              },
            ),
            // Επιλογή 4: Επιθεώρηση Εξόδων (Φιλτράρισμα & Ιστορικό) (ΠΧ3).
            ListTile(
              leading: Icon(Icons.list_alt, color: Colors.blue.shade700),
              title: const Text('Επιθεώρηση Εξόδων', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpensesListScreen()));
                _loadTodayStats(); // Ανανεώνει τα στατιστικά στην αρχική οθόνη μόλις επιστρέψουμε
              },
            ),
            // Επιλογή 5: Ανάλυση Εξόδων (Σύνολα ανά κατηγορία) (ΠΧ4).
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.blue.shade700),
              title: const Text('Ανάλυση Εξόδων', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalysisScreen()));
              },
            ),
          ],
        ),
      ),
      // Κεντρικό περιεχόμενο της αρχικής οθόνης.
      body: LayoutBuilder( // Χρησιμοποιούμε LayoutBuilder για να ξέρουμε το ύψος της οθόνης
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // μοιράζονται ωραία στο μέγεθος της οθόνης
                  children: [

                    // Welcome στοιχεία + καθοδήγηση
                    Column(
                      children: const [
                        SizedBox(height: 20),
                        Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
                        SizedBox(height: 20),
                        Text(
                          'Καλώς ήρθατε!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text('Χρησιμοποιήστε το μενού για να ξεκινήσετε.'),
                      ],
                    ),

                    // Στρόγγυλο quick button
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 4,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 45,
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                              );
                              _loadTodayStats();
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Γρήγορη Προσθήκη Εξόδου",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    // Ημερήσια κάρτα ανάλυσης
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 30),
                          title: const Text('Σημερινά Έξοδα'),
                          subtitle: Text(
                            '€${_todayTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // ΠΡΟΣΘΗΚΗ FOOTER:
      bottomNavigationBar: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: Center(
          child: Text(
            '© 2026 Expense Manager v2.0 • Σύστημα Διαχείρισης Εξόδων',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/*
  Το main.dart είναι ο εγκέφαλος και ο οργανωτής της εφαρμογής. Ο ρόλος του είναι:
  α) Εκκίνηση (Bootstrapping): Φροντίζει για την αρχικοποίηση της SQLite ώστε να δουλεύει σωστά σε όλες τις συσκευές.
  β) Παραμετροποίηση Εμφάνισης: Ορίζει τα χρώματα, τις γραμματοσειρές και τη συμπεριφορά του Dark Mode για όλη την εφαρμογή.
  γ) Πλοήγηση (Routing): Μέσω του Drawer (Πλαϊνό μενού), λειτουργεί ως ο "τροχονόμος" που επιτρέπει στον χρήστη να μεταβεί σε όλες τις Χρηστικές Περιπτώσεις (ΠΧ1 έως ΠΧ4).
  δ) Σημείο Εισόδου: Καθορίζει ποια οθόνη θα δει ο χρήστης πρώτα και πώς θα είναι δομημένο το βασικό πλαίσιο (Scaffold) της εφαρμογής.
*/