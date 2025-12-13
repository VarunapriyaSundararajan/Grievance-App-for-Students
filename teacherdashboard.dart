import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. Teacher Dashboard (Stateful for Tab Navigation) ---

class TeacherDashboard extends StatefulWidget {
  final String name;
  final String email;
  final String department;
  final String phoneNumber;

  TeacherDashboard({
    required this.name,
    required this.email,
    required this.department,
    required this.phoneNumber,
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  // CHANGED: Tab indices updated to new order: 0 for Grievances, 1 for Feedback, 2 for Profile
  int _selectedIndex = 0;

  // Helper to format the timestamp without using the 'intl' package.
  String _formatDate(DateTime? timestamp) {
    if (timestamp == null) return 'Date N/A';

    // Example format: 2024-05-15 10:30:00.000000 -> 2024-05-15 10:30
    final localDateTime = timestamp.toLocal().toString();
    final parts = localDateTime.split(' ');
    if (parts.length < 2) return localDateTime;

    final datePart = parts[0]; // e.g., 2024-05-15
    final timePart = parts[1].split('.').first.substring(0, 5); // e.g., 10:30

    return '$datePart $timePart';
  }

  // --- Profile Section Widget ---

  Widget _buildProfileCard() {
    return SingleChildScrollView(
      // Added for mobile/small screen safety
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      // Padding adjusted for scroll view
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300!, Colors.blue.shade100!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 4,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 36, color: Colors.blue[900]),
                const SizedBox(width: 10),
                Text(
                  'Teacher Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildDetailRow(label: 'Name', value: widget.name, icon: Icons.badge),
            _divider(),
            _buildDetailRow(label: 'Email', value: widget.email, icon: Icons.email),
            _divider(),
            _buildDetailRow(
                label: 'Department', value: widget.department, icon: Icons.domain),
            _divider(),
            _buildDetailRow(label: 'Phone', value: widget.phoneNumber, icon: Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      {required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                children: <TextSpan>[
                  TextSpan(
                      text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.blueGrey[200],
      thickness: 1,
      height: 0,
      indent: 30,
    );
  }

  // UPDATED: The three screens are now ordered: Grievances (0), Feedback (1), Profile (2)
  late final List<Widget> _widgetOptions = <Widget>[
    _GrievanceListAndEditor(department: widget.department, formatDate: _formatDate), // Index 0
    _FeedbackList(department: widget.department, formatDate: _formatDate), // Index 1
    _buildProfileCard(), // Index 2
  ];

  // Helper for AppBar title
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Grievance Queue';
      case 1:
        return 'Student Feedback';
      case 2:
        return 'Teacher Profile';
      default:
        return 'Dashboard';
    }
  }

  // --- Main Widget Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Consistent padding for mobile view
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // UPDATED: BottomNavigationBarItem order changed
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Grievances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- 2. Grievance List and Editor (Stateful) --------------------------
// ----------------------------------------------------------------------

class _GrievanceListAndEditor extends StatefulWidget {
  final String department;
  final String Function(DateTime?) formatDate;

  const _GrievanceListAndEditor({required this.department, required this.formatDate});

  @override
  _GrievanceListAndEditorState createState() => _GrievanceListAndEditorState();
}

class _GrievanceListAndEditorState extends State<_GrievanceListAndEditor> {
  // Only allow actionable statuses in the dropdown
  final List<String> statuses = const ['In Progress', 'Solved'];

  // Helper function to assign an aesthetic icon and color based on the category/status.
  Map<String, dynamic> _getGrievanceVisuals(String category, String status) {
    Color baseColor;
    IconData icon;

    // 1. Determine base icon and color based on category
    switch (category.toLowerCase()) {
      case 'facility':
        icon = Icons.apartment;
        baseColor = Colors.red.shade600;
        break;
      case 'student conduct':
        icon = Icons.school;
        baseColor = Colors.orange.shade600;
        break;
      case 'administration':
        icon = Icons.business;
        baseColor = Colors.purple.shade600;
        break;
      default:
        icon = Icons.announcement;
        baseColor = Colors.teal.shade600;
        break;
    }

    // 2. Override status color for visual clarity on the status tag
    Color statusColor;
    switch (status) {
      case 'Solved':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.blue.shade400;
        break;
      case 'New':
      default:
        statusColor = Colors.red.shade400;
        break;
    }

    return {'icon': icon, 'baseColor': baseColor, 'statusColor': statusColor};
  }

  // Function to update the status in Firestore
  Future<void> _updateGrievanceStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('grievances')
          .doc(docId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grievance status updated to "$newStatus"!'),
          backgroundColor: newStatus == 'Solved' ? Colors.green : Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Backend Logic ---

  Stream<QuerySnapshot> _getGrievancesStream() {
    return FirebaseFirestore.instance
        .collection('grievances')
        .where('department', isEqualTo: widget.department) // Filter remains
        .snapshots()
        .handleError((error) {
      print("Error fetching grievances: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grievance Queue (${widget.department})',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getGrievancesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading grievances: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      const SizedBox(height: 10),
                      Text(
                        'No grievances submitted for ${widget.department} department.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // --- CLIENT-SIDE SORTING IMPLEMENTATION ---
              final grievances = snapshot.data!.docs;
              grievances.sort((a, b) {
                // Safely extract and compare timestamps for descending order (newest first)
                final Timestamp? tsA =
                    (a.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                final DateTime dtA = tsA?.toDate() ?? DateTime(1970);

                final Timestamp? tsB =
                    (b.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                final DateTime dtB = tsB?.toDate() ?? DateTime(1970);

                // Compare B to A to get descending order
                return dtB.compareTo(dtA);
              });
              // --- END CLIENT-SIDE SORTING ---

              return ListView.builder(
                itemCount: grievances.length,
                itemBuilder: (context, index) {
                  return _buildGrievanceItem(context, grievances[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Grievance Item Renderer with Status Dropdown ---

  Widget _buildGrievanceItem(BuildContext context, DocumentSnapshot grievance) {
    final data = grievance.data() as Map<String, dynamic>?;
    final docId = grievance.id;

    final grievanceText = data?['grievance'] ?? 'Grievance description unavailable';
    final category = data?['category'] ?? 'General';
    final status = data?['status'] ?? 'New'; // Default status is 'New'
    final registerNo = data?['registerNo'] ?? 'N/A';
    final timestamp = (data?['timestamp'] as Timestamp?)?.toDate();

    final visuals = _getGrievanceVisuals(category, status);
    final formattedDate = widget.formatDate(timestamp);

    // Determine the dropdown value: if the status is not 'In Progress' or 'Solved' (i.e., 'New'),
    // set the value to null so the hint is displayed and the user is forced to select an action.
    final String? dropdownValue = statuses.contains(status) ? status : null;
    final String hintText = status == 'New' ? 'Take Action' : 'Change Status';

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: visuals['baseColor'], // Category color stripe
              width: 6,
            ),
          ),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Icon(
            visuals['icon'],
            color: visuals['baseColor'],
            size: 32,
          ),
          title: Text(
            grievanceText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reg No: $registerNo | Category: $category',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: visuals['statusColor']),
              borderRadius: BorderRadius.circular(8),
            ),
            // --- Status Editing Dropdown ---
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownValue, // Null if status is 'New'
                icon: Icon(Icons.arrow_drop_down, color: visuals['statusColor']),
                hint: Text(
                  hintText,
                  style: TextStyle(
                    color: visuals['statusColor'],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                items: statuses.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: TextStyle(
                            color: _getGrievanceVisuals('', value)['statusColor'],
                            fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateGrievanceStatus(context, docId, newValue);
                  }
                },
              ),
            ),
          ),
          onTap: () {
            // Optional: Implement a full detail view modal here
            print('Tapped grievance: $docId');
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- 3. Feedback List Widget (NEW and Finalized) ----------------------
// ----------------------------------------------------------------------

class _FeedbackList extends StatelessWidget {
  final String department;
  final String Function(DateTime?) formatDate;

  const _FeedbackList({required this.department, required this.formatDate});

  // --- Backend Logic: Get Feedback Stream ---
  Stream<QuerySnapshot> _getFeedbackStream() {
    // Filters the feedback by the department (teacher's department)
    return FirebaseFirestore.instance
        .collection('feedback')
        .where('department', isEqualTo: department)
        .snapshots()
        .handleError((error) {
      print("Error fetching feedback: $error");
    });
  }

  // Helper to get the correct star icon/color based on the rating
  Icon _getRatingIcon(double rating) {
    if (rating >= 4.5) {
      return const Icon(Icons.star, color: Colors.green, size: 24); // Excellent
    } else if (rating >= 3.5) {
      return const Icon(Icons.star, color: Colors.lightGreen, size: 24); // Good
    } else if (rating >= 2.0) {
      return const Icon(Icons.star_half, color: Colors.orange, size: 24); // Needs Improvement
    } else {
      return const Icon(Icons.star_border, color: Colors.red, size: 24); // Poor
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback on Solved Grievances',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFeedbackStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading feedback: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, size: 60, color: Colors.blueGrey),
                      const SizedBox(height: 10),
                      Text(
                        'No student feedback submitted yet for your department.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Sort feedback by date, descending (newest first)
              final feedbackList = snapshot.data!.docs;
              feedbackList.sort((a, b) {
                final Timestamp? tsA =
                    (a.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                final DateTime dtA = tsA?.toDate() ?? DateTime(1970);

                final Timestamp? tsB =
                    (b.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
                final DateTime dtB = tsB?.toDate() ?? DateTime(1970);

                return dtB.compareTo(dtA);
              });

              return ListView.builder(
                itemCount: feedbackList.length,
                itemBuilder: (context, index) {
                  return _buildFeedbackCard(context, feedbackList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Feedback Card Renderer ---
  Widget _buildFeedbackCard(BuildContext context, DocumentSnapshot feedbackDoc) {
    final data = feedbackDoc.data() as Map<String, dynamic>?;

    final rating = (data?['rating'] as num?)?.toDouble() ?? 0.0;
    // Reads the 'comments' field saved by the fixed student dashboard code
    final comments = data?['comments'] ?? 'No comments provided.';
    // Reads the 'originalGrievance' field saved by the fixed student dashboard code
    final originalGrievanceText =
        data?['originalGrievance'] ?? 'Original grievance context missing from DB.';
    final regNo = data?['registerNo'] ?? 'N/A';
    final timestamp = (data?['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = formatDate(timestamp);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and Reg No
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getRatingIcon(rating),
                    const SizedBox(width: 8),
                    Text(
                      '${rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                Text(
                  'Reg No: $regNo',
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey[600]),
                ),
              ],
            ),
            const Divider(height: 20),
            // Original Grievance Context (Now populated!)
            Text(
              'Grievance: "$originalGrievanceText"',
              maxLines: 3, // Increased maxLines for better context reading
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            // Comments Section
            Text(
              'Comments:',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              comments,
              style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4),
            ),
            const SizedBox(height: 10),
            // Date
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Submitted on $formattedDate',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}