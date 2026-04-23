// Κλάση Μοντέλου για τα Έξοδα (Σχετίζεται με την ΠΧ2).
// Ορίζει τη δομή των δεδομένων για κάθε καταγραφή εξόδου, συμπεριλαμβανομένων των γεωγραφικών συντεταγμένων.
class Expense {
  int? id; // Ο μοναδικός κωδικός του εξόδου (Primary Key).
  double amount; // Η χρηματική αξία σε ευρώ (Υποχρεωτικό πεδίο - ΠΧ2).
  DateTime timestamp; // Ημερομηνία και ώρα της συναλλαγής (Αυτή που λαμβάνεται αυτόματα - ΠΧ2).
  int categoryId; // Το ID της κατηγορίας (Foreign Key που συνδέει το έξοδο με τον πίνακα categories).
  String? categoryName; // <--- ΠΡΟΣΘΗΚΗ: Για να κρατάμε το όνομα που έρχεται από το JOIN
  double latitude; // Γεωγραφικό πλάτος (Λαμβάνεται από το GPS - ΠΧ2).
  double longitude; // Γεωγραφικό μήκος (Λαμβάνεται από το GPS - ΠΧ2).
  String? locationName; // Προαιρετική ονομασία τοποθεσίας που δίνει ο χρήστης (π.χ. "Βενζινάδικο").
  String? details; // Προαιρετική περιγραφή του εξόδου.

  // Constructor της κλάσης Expense. Το 'required' διασφαλίζει ότι δεν θα λείπουν βασικές πληροφορίες για το έξοδο.
  Expense({
    this.id,
    required this.amount,
    required this.timestamp,
    required this.categoryId,
    this.categoryName, // <--- ΠΡΟΣΘΗΚΗ
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.details,
  });

  // Factory Constructor fromMap: Μετατρέπει τα δεδομένα από τη βάση πίσω σε αντικείμενο Dart.
  // Η SQLite επιστρέφει τα δεδομένα σε μορφή Map (σαν λεξικό). Αυτή η μέθοδος // Ανακτά τα δεδομένα από το Map της βάσης και δημιουργεί ένα αντικείμενο Expense.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']), // Μετατρέπουμε το String της βάσης πάλι σε αντικείμενο DateTime της Dart.
      categoryId: map['category_id'],
      categoryName: map['categoryName'], // <--- ΠΡΟΣΘΗΚΗ: Διαβάζει το όνομα από το SQL Query
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
      details: map['details'],
    );
  }

  // Μέθοδος toMap: Μετατρέπει το αντικείμενο Category σε Map (ζεύγη key-value).
  // Η βιβλιοθήκη sqflite απαιτεί αυτή τη μορφή για να εκτελέσει Insert ή Update στη βιβλιοθήκη sqflite, καθώς η SQLite δέχεται τα δεδομένα σε αυτή τη μορφή.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      // Η SQLite δεν έχει τύπο δεδομένων DateTime.
      // Μετατρέπουμε την ημερομηνία σε ISO8601 String για σωστή αποθήκευση και ταξινόμηση.
      'timestamp': timestamp.toIso8601String(),
      'category_id': categoryId,
      // Σύνδεση Foreign Key.
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'details': details,
    };
  }
}

/*
  Είναι το "καλούπι" (Model) των κατηγοριών. Ο ρόλος του είναι:
  α) Δομή Δεδομένων: Καθορίζει όλες τις απαραίτητες πληροφορίες που συνοδεύουν ένα έξοδο, όπως το ποσό, την κατηγορία στην οποία ανήκει και τις συντεταγμένες GPS.
  β) Διαχείριση Χρόνου & Τοποθεσίας: Διασφαλίζει ότι η ημερομηνία και η τοποθεσία μετατρέπονται σωστά από και προς τη βάση δεδομένων, επιτρέποντας στην εφαρμογή να ταξινομεί τα έξοδα χρονολογικά (ΠΧ3).
  γ) Σύνδεση Πινάκων: Μέσω του categoryId, επιτρέπει στο σύστημα να γνωρίζει σε ποια κατηγορία ανήκει το κάθε έξοδο, κάτι που είναι απαραίτητο για την Ανάλυση Εξόδων (ΠΧ4).
*/