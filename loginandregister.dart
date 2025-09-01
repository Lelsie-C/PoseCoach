import 'dart:io';

// User class representing a fitness app user
class User {
  String username;
  String email;
  String password;

  // Constructor to initialize the user
  User({
    required this.username,
    required this.email,
    required this.password,
  });

  // Validate email format
  bool validateEmail() {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  // Validate password length
  bool validatePassword() {
    return password.length >= 6;
  }
}

// AuthService class simulates user authentication (registration and login)
class AuthService {
  List<User> _users = []; // List to hold registered users (in-memory database)

  // Function to register a user
  bool registerUser(User user) {
    // Check if email is already registered
    if (_users.any((existingUser) => existingUser.email == user.email)) {
      print("Email is already in use.");
      return false;  // Registration failed due to email conflict
    }

    // Validate email and password
    if (!user.validateEmail()) {
      print("Invalid email format.");
      return false;  // Registration failed due to invalid email
    }

    if (!user.validatePassword()) {
      print("Password must be at least 6 characters long.");
      return false;  // Registration failed due to invalid password
    }

    // If validation passes, add user to the list
    _users.add(user);
    print("Registration successful.");
    return true;  // Registration successful
  }

  // Function to log in a user
  bool loginUser(String email, String password) {
    final user = _users.firstWhere(
      (existingUser) => existingUser.email == email,
      orElse: () => User(username: '', email: '', password: ''),
    );

    // Check if user exists
    if (user.username.isEmpty) {
      print("User not found.");
      return false;  // Login failed: user not found
    }

    // Check if password matches
    if (user.password != password) {
      print("Incorrect password.");
      return false;  // Login failed: wrong password
    }

    print("Login successful.");
    return true;  // Login successful
  }

  // Function to display all users (for testing purposes)
  void displayUsers() {
    print("Registered Users:");
    for (var user in _users) {
      print('Username: ${user.username}, Email: ${user.email}');
    }
  }
}

// Function to prompt user input for registration or login
void promptUserInput() {
  final authService = AuthService();
  
  while (true) {
    print("\nWelcome to the Fitness App");
    print("1. Register");
    print("2. Login");
    print("3. Display all users (for testing)");
    print("4. Exit");

    String? choice = stdin.readLineSync();

    if (choice == '1') {
      // Register User
      print("Enter username:");
      String? username = stdin.readLineSync();

      print("Enter email:");
      String? email = stdin.readLineSync();

      print("Enter password:");
      String? password = stdin.readLineSync();

      if (username != null && email != null && password != null) {
        User newUser = User(username: username, email: email, password: password);
        authService.registerUser(newUser);
      }
    } else if (choice == '2') {
      // Login User
      print("Enter email:");
      String? email = stdin.readLineSync();

      print("Enter password:");
      String? password = stdin.readLineSync();

      if (email != null && password != null) {
        authService.loginUser(email, password);
      }
    } else if (choice == '3') {
      // Display all users
      authService.displayUsers();
    } else if (choice == '4') {
      print("Exiting...");
      break;  // Exit the program
    } else {
      print("Invalid choice. Please try again.");
    }
  }
}

void main() {
  promptUserInput(); // Start the application
}
