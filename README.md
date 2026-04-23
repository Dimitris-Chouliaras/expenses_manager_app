# 📱 Expense Manager - Flutter & SQLite

Μια ολοκληρωμένη εφαρμογή διαχείρισης προσωπικών εξόδων αναπτυγμένη με το framework **Flutter**. Το project εστιάζει στην ορθή διαχείριση τοπικών βάσεων δεδομένων, τη χρήση γεωγραφικών δεδομένων και την παροχή μιας σύγχρονης εμπειρίας χρήστη (UX).

## 🚀 Κύριες Λειτουργίες (Use Cases)
* **Διαχείριση Κατηγοριών (ΠΧ1)**: Πλήρες σύστημα προσθήκης, επεξεργασίας και διαγραφής κατηγοριών με υποστήριξη **Drag & Drop** για την αναδιάταξη της σειράς εμφάνισης.
* **Καταγραφή Εξόδων (ΠΧ2)**: Δυναμική φόρμα εισαγωγής εξόδων με αυτόματη καταγραφή ημερομηνίας/ώρας και λήψη γεωγραφικών συντεταγμένων (**GPS**) μέσω του `geolocator`.
* **Επιθεώρηση & Φιλτράρισμα (ΠΧ3)**: Προβολή ιστορικού με εξελιγμένα χρονικά φίλτρα (Σήμερα, Χθες, Εβδομάδα, Μήνας, Έτος) και χρήση **SQL JOINs** για τη σύνδεση εξόδων με τις κατηγορίες τους.
* **Ανάλυση Εξόδων (ΠΧ4)**: Οπτικοποίηση των συνολικών εξόδων ανά κατηγορία με δυναμικές μπάρες προόδου για γρήγορη οικονομική εποπτεία.

## 📸 Screenshots
<p align="center">
   <img width="1080" height="2340" alt="Screenshot_20260423_231524" src="https://github.com/user-attachments/assets/da09f806-9e45-4681-b75f-4f09aa41d298" />
   <img width="1080" height="2340" alt="Screenshot_20260423_231545" src="https://github.com/user-attachments/assets/0d9a863a-23cb-44ce-9367-ffa16cf0bed8" />
   <img width="1080" height="2340" alt="Screenshot_20260423_231551" src="https://github.com/user-attachments/assets/c2c75f17-cd6d-47e4-946f-0c8243122290" />
</p>
<p align="center">
   <img width="1080" height="2340" alt="Screenshot_20260423_231556" src="https://github.com/user-attachments/assets/6f791f77-26e2-4816-99b2-5bd1ffb7c39e" />
   <img width="1080" height="2340" alt="Screenshot_20260423_231606" src="https://github.com/user-attachments/assets/48f34083-ebd6-422c-add3-cfd3f1cb8b8a" />
   <img width="1080" height="2340" alt="Screenshot_20260423_231616" src="https://github.com/user-attachments/assets/a5efdca7-a5ef-4a4f-9125-f2e932828fb5" />
</p>

## 🛠 Τεχνικά Χαρακτηριστικά
* **Τοπική Βάση Δεδομένων**: Χρήση της βιβλιοθήκης `sqflite` για μόνιμη αποθήκευση.
* **Ασφάλεια Δεδομένων**: Υλοποίηση **Database Transactions** (Atomicity) για την ταυτόχρονη διαγραφή κατηγοριών και των σχετικών τους εξόδων, διασφαλίζοντας την ακεραιότητα της βάσης.
* **UI/UX**: 
    * Πλήρης υποστήριξη **Dark Mode** & **Light Mode** (System Theme).
    * Responsive σχεδιασμός για κινητά και desktop (ffi support).
    * Αυτόματη κεφαλαιοποίηση (Text Capitalization) σε όλα τα πεδία εισαγωγής.

## 📦 Εγκατάσταση
1. Βεβαιωθείτε ότι έχετε εγκαταστήσει το [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Κλωνοποιήστε το repository: `git clone https://github.com/ΤΟ_USERNAME_ΣΟΥ/expenses_manager_app.git`
3. Εκτελέστε την εντολή: `flutter pub get`
4. Τρέξτε την εφαρμογή: `flutter run`
