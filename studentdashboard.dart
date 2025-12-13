import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- Main Student Screen with Bottom Navigation ---
class MainStudentScreen extends StatefulWidget {
  final String name;
  final String email;
  final String registerNo; // Passed to HomeTab
  final String studentClass;
  final String section;
  final String department;
  final String hostelDaysScholar;
  final String batch;

  MainStudentScreen({
    required this.name,
    required this.email,
    required this.registerNo,
    required this.studentClass,
    required this.section,
    required this.department,
    required this.hostelDaysScholar,
    required this.batch,
  });

  @override
  _MainStudentScreenState createState() => _MainStudentScreenState();
}

class _MainStudentScreenState extends State<MainStudentScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // The tabs list is created inside build, using the current widget's properties
    final List<Widget> _tabs = [
      // Renamed HomeTab and passing registerNo
      HomeTabWithGrievances(registerNo: widget.registerNo),
      GrievanceTab(
        registerNo: widget.registerNo,
        department: widget.department,
      ),
      ProfileTab(
        name: widget.name,
        email: widget.email,
        registerNo: widget.registerNo,
        studentClass: widget.studentClass,
        section: widget.section,
        department: widget.department,
        hostelDaysScholar: widget.hostelDaysScholar,
        batch: widget.batch,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Grievance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// --- Tab 1: Home/Instructions/Grievance Status (UPDATED) ---
class HomeTabWithGrievances extends StatefulWidget {
  final String registerNo;

  const HomeTabWithGrievances({super.key, required this.registerNo});

  @override
  State<HomeTabWithGrievances> createState() => _HomeTabWithGrievancesState();
}

class _HomeTabWithGrievancesState extends State<HomeTabWithGrievances> {
  // Utility for Instruction Items
  Widget _buildInstructionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // --- Feedback Dialog Handler (UPDATED to accept originalGrievance) ---
  void _showFeedbackDialog(
      BuildContext context,
      String grievanceId,
      String department,
      String grievanceCategory,
      String registerNo,
      String originalGrievance) { // <--- **UPDATED**
    showDialog(
      context: context,
      builder: (context) {
        return FeedbackTab(
          grievanceId: grievanceId,
          department: department,
          grievanceCategory: grievanceCategory,
          registerNo: registerNo,
          originalGrievanceText: originalGrievance, // <--- **PASSED**
        );
      },
    );
  }

  // Utility for Grievance Status Card (Aesthetic Design)
  Widget _buildGrievanceCard(
    String id,
    String category,
    String grievance,
    String status,
    Timestamp timestamp,
    String department,
    String registerNo,
  ) {
    // Determine color and icon based on status
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_full;

    if (status == 'New' || status == 'In Progress') {
      statusColor = Colors.orange[800]!;
      statusIcon = Icons.access_time;
    } else if (status == 'Solved') {
      statusColor = Colors.green[800]!;
      statusIcon = Icons.check_circle;
    } else if (status == 'Rejected') {
      statusColor = Colors.red[800]!;
      statusIcon = Icons.cancel;
    }

    // Format the timestamp
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: $category',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 15, color: Colors.black12),
            Text(
              grievance,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              'Submitted on: $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            // --- Feedback Button (Conditional) ---
            if (status == 'Solved') ...[
              const Divider(height: 20, color: Colors.black12),
              Center(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('grievances')
                      .doc(id)
                      .get(),
                  builder: (context, snapshot) {
                    bool isFeedbackSubmitted = snapshot.hasData &&
                        (snapshot.data!.data()
                                as Map<String, dynamic>?)
                            ?.containsKey('feedbackSubmitted') ==
                            true;

                    return ElevatedButton.icon(
                      onPressed: isFeedbackSubmitted
                          ? null
                          : () => _showFeedbackDialog(
                                context,
                                id,
                                department,
                                category,
                                registerNo,
                                grievance, // <--- **PASSING THE GRIEVANCE TEXT**
                              ),
                      icon: Icon(isFeedbackSubmitted
                          ? Icons.done_all
                          : Icons.rate_review),
                      label: Text(isFeedbackSubmitted
                          ? 'Feedback Submitted'
                          : 'Submit Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFeedbackSubmitted
                            ? Colors.grey[400]
                            : Colors.purple[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome and Instructions Section
          Text(
            'Welcome to the Student Grievance Portal! 🏠',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800]),
          ),
          const SizedBox(height: 30),

          // --- What To Do ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.lightGreen[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ What to Do (Instructions)',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700]),
                ),
                const SizedBox(height: 10),
                _buildInstructionItem(
                    'Select the appropriate **category** for your issue (e.g., Academic, Facilities).',
                    Icons.label_important),
                _buildInstructionItem(
                    'Provide a clear and detailed description of your grievance.',
                    Icons.text_fields),
                _buildInstructionItem(
                    'If possible, attach an image/proof to support your claim.',
                    Icons.attach_file),
                _buildInstructionItem(
                    'Check your **Profile** details are correct before submission.',
                    Icons.person_pin),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // --- What Not To Do ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '❌ What Not to Do (Ground Rules)',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700]),
                ),
                const SizedBox(height: 10),
                _buildInstructionItem(
                    'Do not submit false or malicious complaints.',
                    Icons.block),
                _buildInstructionItem(
                    'Avoid using abusive or inappropriate language.',
                    Icons.gavel),
                _buildInstructionItem(
                    'Do not submit the same grievance multiple times.',
                    Icons.cached),
                _buildInstructionItem(
                    'Do not use the form for general feedback; only for serious concerns.',
                    Icons.feedback_outlined),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // --- 2. Student Grievance Status Section ---
          Text(
            'Your Submitted Grievances Status 📋',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900]),
          ),
          const SizedBox(height: 15),

          // StreamBuilder to fetch and display grievances
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('grievances')
                .where('registerNo', isEqualTo: widget.registerNo) // Filter by student's Register No
                .orderBy('timestamp', descending: true) // Show newest first
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading grievances: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text(
                            'No grievances submitted yet. Head to the Grievance tab to file one!',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              // Display the list of grievances
              return ListView.builder(
                shrinkWrap:
                    true, // Important for ListView inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable ListView scrolling
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var grievanceDoc = snapshot.data!.docs[index];
                  Map<String, dynamic> data =
                      grievanceDoc.data() as Map<String, dynamic>;

                  return _buildGrievanceCard(
                    grievanceDoc.id, // Pass document ID for feedback
                    data['category'] ?? 'N/A',
                    data['grievance'] ?? 'No Description',
                    data['status'] ?? 'New', // Default status if field is missing
                    data['timestamp'] ?? Timestamp.now(),
                    data['department'] ?? 'N/A', // Pass department for staff tracking
                    widget.registerNo,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80), // Extra space for bottom bar clearance
        ],
      ),
    );
  }
}

// --- NEW Widget: Feedback Submission Dialog (UPDATED) ---
class FeedbackTab extends StatefulWidget {
  final String grievanceId;
  final String department;
  final String grievanceCategory;
  final String registerNo;
  final String originalGrievanceText; // <--- **NEW PROPERTY**

  const FeedbackTab({
    super.key,
    required this.grievanceId,
    required this.department,
    required this.grievanceCategory,
    required this.registerNo,
    required this.originalGrievanceText, // <--- **REQUIRED**
  });

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab> {
  double _rating = 5.0; // 1 to 5 rating
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackData = {
        'grievanceId': widget.grievanceId,
        'department': widget.department,
        'category': widget.grievanceCategory,
        'registerNo': widget.registerNo,
        'rating': _rating,
        'comments': _feedbackController.text.trim(), // Renamed to 'comments' for consistency with Teacher Dashboard code
        'timestamp': FieldValue.serverTimestamp(),
        'originalGrievance': widget.originalGrievanceText, // <--- **FIX: SAVING ORIGINAL TEXT**
      };

      // 1. Submit feedback to a new 'feedback' collection
      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      // 2. Update the original grievance to mark feedback as submitted
      await FirebaseFirestore.instance
          .collection('grievances')
          .doc(widget.grievanceId)
          .update({
        'feedbackSubmitted': true,
        'finalRating': _rating, // optional: save the rating back to the grievance doc
      });

      _showAlert('Feedback submitted successfully. Thank you!');
      // Dismiss the dialog after success
      // Navigator.of(context).pop(); // Removed pop here as _showAlert handles it
    } on FirebaseException catch (e) {
      _showAlert('Feedback Submission Failed: ${e.message}');
    } catch (e) {
      _showAlert('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAlert(String message) {
    // Show alert outside the dialog's context
    // Check if the current dialog is still mounted before attempting to pop.
    if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop(); // Close current dialog first
    }
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Feedback Status'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        'Rate Your Resolution (Category: ${widget.grievanceCategory})',
        style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How satisfied are you with the resolution?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            Center(
              child: Column(
                children: [
                  Text(
                    'Rating: ${_rating.toStringAsFixed(1)} / 5.0',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800]),
                  ),
                  Slider(
                    value: _rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8, // Allows for 0.5 increments
                    label: _rating.toStringAsFixed(1),
                    onChanged: (double newValue) {
                      setState(() {
                        _rating = newValue;
                      });
                    },
                    activeColor: Colors.amber,
                    inactiveColor: Colors.amber[100],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Additional Comments (Optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., The response was very quick.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

// --- Tab 2: Grievance Submission (Padding Fix Applied) ---
class GrievanceTab extends StatefulWidget {
  final String registerNo;
  final String department;

  const GrievanceTab({required this.registerNo, required this.department});

  @override
  _GrievanceTabState createState() => _GrievanceTabState();
}

class _GrievanceTabState extends State<GrievanceTab> {
  final _grievanceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  String? _selectedCategory;

  // File handling for both platforms
  XFile? _selectedImage; // Used by image_picker on mobile
  Uint8List? _fileBytes; // Used by file_picker on web or read from XFile
  String? _fileName;

  final List<String> categories = [
    'Academic',
    'Facilities',
    'Hostel',
    'Student Conduct',
    'Other'
  ];

  // --- Image Picking Logic ---
  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web Picking: Use file_picker to get bytes
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _fileBytes = result.files.single.bytes;
            _fileName = result.files.single.name;
            _selectedImage = null;
          });
        }
      } else {
        // Mobile Picking: Use image_picker to get XFile
        final XFile? image =
            await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedImage = image;
            _fileBytes = null;
            _fileName = image.name;
          });
        }
      }
    } catch (e) {
      _showAlert('Image picking failed: $e');
      print('Image picking failed: $e');
    }
  }

  // --- Platform-Safe Image Upload Logic ---
  Future<String?> _uploadImage() async {
    if (_fileName == null) return null;

    try {
      String path =
          'grievances/${widget.registerNo}/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      Reference storageRef = FirebaseStorage.instance.ref().child(path);
      UploadTask uploadTask;

      Uint8List dataToUpload;

      if (!kIsWeb && _selectedImage != null) {
        // Mobile/Desktop: Read bytes from the XFile object
        dataToUpload = await _selectedImage!.readAsBytes();
      } else if (kIsWeb && _fileBytes != null) {
        // Web: Use bytes already loaded from FilePicker
        dataToUpload = _fileBytes!;
      } else {
        return null;
      }

      // Use putData for both platforms (the safe method)
      uploadTask = storageRef.putData(dataToUpload);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _showAlert('Image upload failed: ${e.message}');
      print('Image upload failed: ${e.message}');
      return null;
    } catch (e) {
      _showAlert('An unexpected error occurred during upload: $e');
      print('Unexpected upload error: $e');
      return null;
    }
  }

  // --- Grievance Submission Logic ---
  Future<void> _submitGrievance() async {
    String grievance = _grievanceController.text.trim();
    if (_selectedCategory == null || grievance.isEmpty) {
      _showAlert(
          'Please enter a grievance and select a category before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Upload image and get URL (if selected)
      String? imageUrl = await _uploadImage();

      // 2. Submit data to Firestore
      await FirebaseFirestore.instance.collection('grievances').add({
        'category': _selectedCategory,
        'grievance': grievance,
        'registerNo': widget.registerNo,
        'department': widget.department,
        'imageUrl': imageUrl, // Save the image URL
        'status': 'New',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Success and Reset
      _showAlert('Grievance submitted successfully!');
      _grievanceController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedImage = null;
        _fileBytes = null;
        _fileName = null;
        _isSubmitting = false;
      });
    } on FirebaseException catch (e) {
      _showAlert('Firestore Error: Submission failed. ${e.message}');
      setState(() {
        _isSubmitting = false;
      });
    } catch (e) {
      _showAlert(
          'An unexpected error occurred during submission: ${e.toString()}');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // --- Alert Dialog Utility ---
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Grievance System Alert',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    // FIX: Wrap the content in a SingleChildScrollView
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Container(
        // The container holds the styling and size constraints
        constraints:
            BoxConstraints(minHeight: MediaQuery.of(context).size.height - 100),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Your Grievance 📝',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900]),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildLabel('Choose Category:'),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: categories
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              hint: const Text("Select Category"),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Grievance Text Field
            _buildLabel('Enter Your Grievance:'),
            TextField(
              controller: _grievanceController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your grievance here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // Image/File Picker
            _buildLabel('Insert Image/File (Optional):'),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName != null ? 'Change File' : "Choose File"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[900],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 10),
            if (_fileName != null)
              Text(
                "File Selected: $_fileName",
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            const SizedBox(height: 30),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGrievance,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text("Submit Grievance"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 80), // Ensure button is visible above navbar
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

// --- Tab 3: Profile Information ---
class ProfileTab extends StatelessWidget {
  final String name;
  final String email;
  final String registerNo;
  final String studentClass;
  final String section;
  final String department;
  final String hostelDaysScholar;
  final String batch;

  const ProfileTab({
    super.key,
    required this.name,
    required this.email,
    required this.registerNo,
    required this.studentClass,
    required this.section,
    required this.department,
    required this.hostelDaysScholar,
    required this.batch,
  });

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile Details 👤',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800]),
          ),
          const SizedBox(height: 20),
          _buildProfileItem('Name', name, Icons.person),
          _buildProfileItem('Register No.', registerNo, Icons.badge),
          _buildProfileItem('Email', email, Icons.email),
          _buildProfileItem('Department', department, Icons.school),
          _buildProfileItem('Class & Section', '$studentClass - $section', Icons.class_),
          _buildProfileItem('Batch', batch, Icons.calendar_today),
          _buildProfileItem('Status', hostelDaysScholar, Icons.home_work),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Information sourced from registration data.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          )
        ],
      ),
    );
  }
}