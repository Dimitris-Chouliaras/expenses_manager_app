import 'package:sqflite/sqflite.dart'; // Βασική βιβλιοθήκη για τη χρήση της SQLite βάσης δεδομένων.
import 'package:path/path.dart'; // Βιβλιοθήκη για τη διαχείριση διαδρομών αρχείων (file paths) στο σύστημα.
import '../models/category.dart'; // Εισαγωγή του μοντέλου Category για τη διαχείριση των αντικειμένων κατηγορίας.
import '../models/expense.dart'; // Εισαγωγή του μοντέλου Expense για τη διαχείριση των αντικειμένων εξόδων.

// Κλάση διαχείρισης της βάσης δεδομένων SQLite - Υλοποιεί όλες τις λειτουργίες CRUD (Create, Read, Update, Delete).
class DatabaseHelper {
  // Singleton Pattern: Διασφαλίζει ότι η εφαρμογή χρησιμοποιεί μόνο ένα ανοιχτό instance της βάσης, εξοικονομώντας πόρους και αποφεύγοντας conflicts.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter για τη βάση: Αν δεν υπάρχει (null), την αρχικοποιεί - Αν όχι (null), καλεί την _initDB για να τη δημιουργήσει/ανοίξει.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses_final_v1.db');
    return _database!;
  }

  // Αρχικοποίηση και σύνδεση με το αρχείο της βάσης (.db) στο σύστημα αρχείων της συσκευής.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // Επιστρέφει το default path των ΒΔ στη συσκευή.
    final path = join(dbPath, filePath); // Ενώνει το μονοπάτι με το όνομα του αρχείου.

    return await openDatabase(
      path,
      version: 2, // Η έκδοση της βάσης (αυξήθηκε σε 2 για το migration) - Πρόσθεσα την στήλη position στο TABLE categories
      onCreate: _createDB, // Εκτελείται μόνο την πρώτη φορά που δημιουργείται το αρχείο .db.
      onConfigure: _onConfigure, // Ρυθμίσεις που τρέχουν κάθε φορά που ανοίγει η βάση.
      onUpgrade: _onUpgrade, // Διαχειρίζεται την αναβάθμιση από παλαιότερες εκδόσεις (π.χ. προσθήκη στήλης - v2).
    );
  }

  // Ρύθμιση για την ενεργοποίηση των Foreign Key Constraints - Διασφαλίζει ότι οι σχέσεις μεταξύ πινάκων (π.χ. έξοδο προς κατηγορία) τηρούνται αυστηρά.
  // *** Από προεπιλογή η SQLite τα έχει απενεργοποιημένα για λόγους συμβατότητας *** --> Να το ξανά τσεκάρω
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Δημιουργία των πινάκων της εφαρμογής.
  Future _createDB(Database db, int version) async {
    // Πίνακας Κατηγοριών (Σχετίζεται με την ΠΧ1).
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- Αυτόματη αύξηση ID.
        title TEXT NOT NULL,                  -- Υποχρεωτικός σύντομος τίτλος.
        description TEXT                      -- Προαιρετική περιγραφή.
        position INTEGER DEFAULT 0            -- Η ΝΕΑ ΣΤΗΛΗ
      )
    ''');

    // Πίνακας Εξόδων (Σχετίζεται με την ΠΧ2).
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,                 -- Αποθήκευση χρηματικής αξίας (double).
        timestamp TEXT NOT NULL,              -- Ημερομηνία/Ώρα σε ISO8601 String.
        details TEXT,
        latitude REAL NOT NULL,               -- Γεωγραφικό πλάτος (GPS).
        longitude REAL NOT NULL,              -- Γεωγραφικό μήκος (GPS).
        location_name TEXT,                   -- Προαιρετική ονομασία τοποθεσίας.
        category_id INTEGER NOT NULL,         -- Foreign Key σύνδεση με κατηγορία.
        
        -- Περιορισμός Foreign Key: Διασφαλίζει την ακεραιότητα των δεδομένων.
        -- ON DELETE RESTRICT: Απαγορεύει τη διαγραφή κατηγορίας αν υπάρχουν έξοδα σε αυτήν.
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');
  }

  // Διαχείριση αναβάθμισης: Αν ο χρήστης έχει την έκδοση 1, προσθέτει τη στήλη 'position' στον πίνακα categories χωρίς να διαγραφούν τα υπάρχοντα δεδομένα.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async { // --> Να το ξανά τσεκάρω ερρορ στο v7
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN position INTEGER DEFAULT 0');
        print("Η βάση αναβαθμίστηκε στην έκδοση 2!");
      } catch (e) {
        // Αν η στήλη υπάρχει ήδη (όπως στο δικό σου PC τώρα),
        // το catch θα αποτρέψει το κράσαρισμα.
        print("Η στήλη position υπάρχει ήδη.");
      }
    }
  }

  // --- Μέθοδοι για Κατηγορίες (Υλοποίηση ΠΧ1) ---

  // Εισαγωγή νέας κατηγορίας στη βάση: Ελέγχει πρώτα αν το όνομα υπάρχει ήδη (μοναδικότητα).
  Future<int> insertCategory(Category category) async {
    final db = await database; // Ανοίγουμε τη σύνδεση

    // 1. Ψάχνουμε αν υπάρχει ήδη κατηγορία με αυτό το όνομα
    final List<Map<String, dynamic>> existing = await db.query(
      'categories',
      where: 'title = ?',
      whereArgs: [category.title],
    );

    // 2. Αν η λίστα δεν είναι άδεια, σημαίνει ότι υπάρχει ήδη!
    if (existing.isNotEmpty) {
      return -1; // Επιστρέφουμε -1 ως "σήμα" ότι απέτυχε η εισαγωγή λόγω διπλότυπου
    }

    // 3. Αν δεν υπάρχει, την αποθηκεύουμε κανονικά
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Ανάκτηση όλων των κατηγοριών για εμφάνιση σε Dropdowns ή λίστες ταξινομημένων βάσει της στήλης position.
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    // Προσθέτουμε το ORDER BY position
    final result = await db.query('categories', orderBy: 'position ASC');
    // Μετατροπή των Map αποτελεσμάτων σε αντικείμενα Category (Dart Objects).
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // Μαζική ενημέρωση της σειράς των κατηγοριών (Batch Update) μετά από Drag & Drop.
  Future<void> updateCategoryOrder(List<Category> categories) async {
    final db = await instance.database;
    var batch = db.batch(); // Χρήση batch για ταχύτητα και αποφυγή πολλαπλών εγγραφών.
    for (int i = 0; i < categories.length; i++) {
      batch.update(
        'categories',
        {'position': i},
        where: 'id = ?',
        whereArgs: [categories[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Μέθοδοι για Έξοδα (Υλοποίηση ΠΧ2 & ΠΧ3) ---

  // Αποθήκευση νέου εξόδου (ΠΧ2).
  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  // Ανάκτηση εξόδων με φίλτρα χρόνου (Σήμερα, Μήνας κλπ) χρησιμοποιώντας SQL συναρτήσεις ημερομηνίας.
  Future<List<Expense>> getFilteredExpenses(String filter) async {
    final db = await instance.database;
    String where = ''; // Αρχικά κενό για την περίπτωση 'ΟΛΑ'

    // Δημιουργούμε το WHERE clause προσθέτοντας τη λέξη WHERE στην αρχή
    if (filter == 'ΣΗΜΕΡΑ') {
      where = "WHERE date(e.timestamp, 'localtime') = date('now', 'localtime')";
    } else if (filter == 'ΧΘΕΣ') {
      where = "WHERE date(e.timestamp, 'localtime') = date('now', 'localtime', '-1 day')";
    } else if (filter == 'ΕΒΔΟΜΑΔΑ') {
      where = "WHERE date(e.timestamp, 'localtime') >= date('now', 'localtime', '-7 days')";
    } else if (filter == 'ΜΗΝΑΣ') {
      where = "WHERE date(e.timestamp, 'localtime') >= date('now', 'localtime', 'start of month')";
    } else if (filter == 'ΧΡΟΝΟΣ') {
      where = "WHERE date(e.timestamp, 'localtime') >= date('now', 'localtime', 'start of year')";
    } // Αν είναι 'ΟΛΑ', το whereClause μένει null

    // Χρήση rawQuery για να συνδέσουμε τους δύο πίνακες (expenses και categories)
    // Παίρνουμε όλα τα πεδία του εξόδου (e.*) και το title από τις κατηγορίες (c.title)
    // Εκτέλεση του rawQuery με JOIN
    final result = await db.rawQuery('''
    SELECT e.*, c.title as categoryName 
    FROM expenses e
    JOIN categories c ON e.category_id = c.id
    $where
    ORDER BY e.timestamp DESC
  ''');

    // Μετατροπή των αποτελεσμάτων σε λίστα αντικειμένων Expense
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  // Ανάκτηση όλων των εξόδων με ταξινόμηση από το πιο πρόσφατο στο παλαιότερο (ΠΧ3).
  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'timestamp DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  // Διαγραφή συγκεκριμένου εξόδου βάσει ID (ΠΧ3).
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Ενημέρωση υπάρχοντος εξόδου.
  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // --- Νέες μέθοδοι για τη Διαχείριση Κατηγοριών (Επεξεργασία & Διαγραφή) ---

  // Μέθοδος ενημέρωσης κατηγορίας (Update). Επιτρέπει τη διόρθωση λαθών (π.χ. "ΚΚαυσιμα" -> "Καύσιμα").
  Future<int> updateCategory(Category category) async {
    final db = await instance.database; // Λήψη της βάσης.
    return await db.update(
      'categories',          // Ο πίνακας προς ενημέρωση.
      category.toMap(),      // Τα νέα δεδομένα σε μορφή Map.
      where: 'id = ?',       // Φίλτρο για να βρει τη συγκεκριμένη εγγραφή.
      whereArgs: [category.id], // Το ID της κατηγορίας που επεξεργαζόμαστε.
    );
  }

  // Μέθοδος διαγραφής κατηγορίας (Delete).
  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Έλεγχος ακεραιότητας δεδομένων: Ελέγχει αν μια κατηγορία έχει συνδεδεμένα έξοδα. Απαραίτητο για να αποφύγουμε σφάλματα λόγω του RESTRICT constraint της SQLite.
  Future<bool> categoryHasExpenses(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1, // Χρειαζόμαστε έστω και μία εγγραφή για να ξέρουμε ότι δεν είναι άδεια.
    );
    return result.isNotEmpty; // Επιστρέφει true αν βρέθηκαν έξοδα.
  }

  // Διαγραφή κατηγορίας και ΟΛΩΝ των εξόδων της (Transaction)
  Future<void> deleteCategoryAndExpenses(int categoryId) async {
    final db = await instance.database;

    // Χρησιμοποιούμε transaction για να είμαστε σίγουροι ότι
    // ή θα διαγραφούν όλα ή τίποτα (ασφάλεια δεδομένων).
    await db.transaction((txn) async {
      // 1. Διαγραφή των εξόδων που ανήκουν στην κατηγορία
      await txn.delete(
        'expenses',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 2. Διαγραφή της ίδιας της κατηγορίας
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }
}

/*
  Είναι η καρδιά των δεδομένων της εφαρμογής σου. Ο ρόλος του είναι:
  α) Διαχείριση της SQLite: Δημιουργεί το αρχείο της βάσης, ορίζει τους πίνακες (categories, expenses) και φροντίζει για την ασφαλή σύνδεση (Singleton)
  β) Migration: Επιτρέπει την αναβάθμιση της εφαρμογής (π.χ. προσθήκη νέων στηλών) χωρίς να χάνονται τα δεδομένα του χρήστη.
  γ) CRUD Λειτουργίες: Περιέχει όλη τη λογική για την αποθήκευση, ανάκτηση, επεξεργασία και διαγραφή δεδομένων.
  δ) Φιλτράρισμα & Ταξινόμηση: Εκτελεί τις SQL ερωτήσεις που επιτρέπουν στον χρήστη να βλέπει τα έξοδα ανά χρονική περίοδο ή τις κατηγορίες με τη σειρά που ο ίδιος επέλεξε.
*/