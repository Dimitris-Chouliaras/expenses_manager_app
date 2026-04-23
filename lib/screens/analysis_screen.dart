// Οθόνη Ανάλυσης Εξόδων (Υλοποίηση ΠΧ4).
import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Εισαγωγή του Helper για την πρόσβαση στη βάση δεδομένων.
import 'package:intl/intl.dart'; // Βιβλιοθήκη για τη μορφοποίηση ημερομηνιών και αριθμών.

// Παρέχει τη δυνατότητα φιλτραρίσματος εξόδων ανά χρονική περίοδο και ομαδοποίησής τους ανά κατηγορία με φθίνουσα σειρά αθροίσματος.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Ορισμός χρονικού εύρους αναζήτησης. Προεπιλογή: οι τελευταίες 30 ημέρες από σήμερα.
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _analysisData = []; // Λίστα που θα φιλοξενήσει τα αποτελέσματα του SQL ερωτήματος (ομαδοποιημένα έξοδα).

  double _grandTotal = 0; // Μεταβλητή που αποθηκεύει το άθροισμα όλων των εξόδων για την επιλεγμένη περίοδο.

  // Κύρια μέθοδος ανάλυσης που εκτελεί το query στη SQLite (Υλοποίηση ΠΧ4).
  void _runAnalysis() async {
    final db = await DatabaseHelper.instance.database;

    // Εκτέλεση σύνθετου SQL ερωτήματος (Raw Query): /*** ΑΚΡΙΒΩΣ ΜΕ ΤΗΝ ΣΕΙΡΑ ΤΟΥ SQL ΕΡΩΤΗΜΑΤΟΣ ΓΙΑ ΠΛΗΡΗ ΚΑΤΑΝΟΗΣΗ ***/
    // 1. JOIN: Συνένωση πινάκων expenses και categories μέσω του category_id.
    // 2. SUM: Άθροισμα των ποσών ανά κατηγορία.
    // 3. WHERE: Φιλτράρισμα βάσει του timestamp (Περίοδος που επέλεξε ο χρήστης).
    // 4. GROUP BY: Ομαδοποίηση των αποτελεσμάτων ανά κατηγορία.
    // 5. ORDER BY total DESC: Ταξινόμηση από το μεγαλύτερο συνολικό έξοδο στο μικρότερο (Φθίνουσα σειρά).
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT c.title, SUM(e.amount) as total 
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE e.timestamp BETWEEN ? AND ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [_startDate.toIso8601String(), _endDate.toIso8601String()]);

    // Υπολογισμός του γενικού συνόλου για να χρησιμοποιηθεί στον υπολογισμό των ποσοστών (%).
    double tempTotal = 0;
    for (var row in result) {
      tempTotal += row['total'];
    }

    // Ενημέρωση της κατάστασης του UI με τα δεδομένα που επιστράφηκαν από τη βάση.
    setState(() {
      _analysisData = result;
      _grandTotal = tempTotal;
    });
  }

  // Μέθοδος εμφάνισης του ημερολογίου (Date Picker) για επιλογή περιόδου.
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() { // Ανάλογα με το ποιο πεδίο πατήθηκε, ενημερώνουμε την αρχή ή το τέλος της περιόδου.
        if (isStart) _startDate = picked; else _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ανάλυση Εξόδων')),
      body: Column(
        children: [
          ListTile( // Επιλογή ημερομηνιών (Από - Έως).
            title: Text("Από: ${DateFormat('dd/MM/yyyy').format(_startDate)}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, true),
          ),
          ListTile( // Επιλογή ημερομηνιών (Από - Έως).
            title: Text("Έως: ${DateFormat('dd/MM/yyyy').format(_endDate)}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, false),
          ),
          ElevatedButton( // Κουμπί ανάλυσης
            onPressed: _runAnalysis,
            child: const Text('Εκτέλεση Ανάλυσης'),
          ),
          const Divider(),

          // Εμφάνιση του Συνολικού Ποσού της περιόδου σε μια Card (μόνο αν υπάρχουν δεδομένα).
          if (_grandTotal > 0)
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Συνολικά Έξοδα:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('${_grandTotal.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),

          // Λίστα Αποτελεσμάτων: Προβολή κατηγοριών με μπάρες προόδου (Progress Indicators).
          Expanded(
            child: _analysisData.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν δεδομένα για την περίοδο.')) // αν empty do this
                : ListView.builder( // αν έχει δεδομένα do this
              itemCount: _analysisData.length,
              itemBuilder: (context, index) {
                final item = _analysisData[index];
                final double categoryTotal = item['total'];

                // Υπολογισμός του ποσοστού της κατηγορίας επί του συνόλου (τιμή 0.0 έως 1.0).
                final double percentage = _grandTotal > 0 ? categoryTotal / _grandTotal : 0;
                double displayPercentage = percentage * 100; // Μετατροπή σε 0-100 για ευκολία

                // Δυναμικός χρωματισμός μπάρας ανάλογα με τη "βαρύτητα" του εξόδου:
                Color progressColor;
                if (displayPercentage < 50) {
                  progressColor = Colors.blue; // 0% - 49.99% - Χαμηλά έξοδα. Μπράβο πασάκα μου
                } else if (displayPercentage < 75) {
                  progressColor = Colors.orange; // 50% - 74.99% - Μεσαία έξοδα.
                } else {
                  progressColor = Colors.red; // 75% - 100% - Υψηλά έξοδα (καμπανάκι κινδύνου). Το γάμησε στα έξοδα
                }

                // Το UI κομμάτι της μπάρας μέσα στο Column
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( // Επικεφαλίδα κατηγορίας και ποσό.
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${index + 1}. ${item['title']}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${categoryTotal.toStringAsFixed(2)} € (${displayPercentage.toStringAsFixed(1)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator( // Οπτική αναπαράσταση του ποσοστού με μπάρα.
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        color: progressColor, // Χρήση του δυναμικού χρώματος
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
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
  Είναι η υλοποίηση της Τέταρτης Χρηστικής Περίπτωσης (ΠΧ4). Ο ρόλος του είναι:
  α) Επεξεργασία Δεδομένων: Δεν δείχνει απλά μια λίστα, αλλά "ρωτάει" τη βάση δεδομένων για να κάνει μαθηματικούς υπολογισμούς (αθροίσματα) σε πραγματικό χρόνο.
  β) Στατιστική Εικόνα: Παρέχει στον χρήστη μια σαφή εικόνα για το πού ξοδεύονται τα περισσότερα χρήματα, ομαδοποιώντας τα έξοδα ανά κατηγορία.
  γ) Οπτική Ανάλυση: Χρησιμοποιεί μπάρες προόδου (LinearProgressIndicator) και χρώματα (μπλε, πορτοκαλί, κόκκινο) για να βοηθήσει τον χρήστη να αναγνωρίσει αμέσως τις κατηγορίες με τη μεγαλύτερη οικονομική επιβάρυνση.
  δ) Παραμετροποίηση: Επιτρέπει την πλήρη ελευθερία στην επιλογή του χρονικού διαστήματος ανάλυσης μέσω ενός εύχρηστου ημερολογίου.
*/