import 'package:app/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';

class MintingScreen extends StatefulWidget {
  const MintingScreen({super.key});

  @override
  State<MintingScreen> createState() => _MintingScreenState();
}

class _MintingScreenState extends State<MintingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: Text(
          'Mint your voice as an NFT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/bottom_gradient.png",
              height: 300, // 원하는 높이
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter the title of your NFT',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              print('입력값: $value');
                            },
                          ),
                          SizedBox(height: 3),
                          Text(
                            'This field is required.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter a description (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onChanged: (value) {
                              print('입력값: $value');
                            },
                          ),
                          SizedBox(height: 3),
                          Text(
                            'You can provide additional context.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Visibility',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(
                                        0,
                                        0,
                                        0,
                                        0.05,
                                      ),
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Public',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 36,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(
                                        0,
                                        0,
                                        0,
                                        0.05,
                                      ),
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Private',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Choose who can view your NFT.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Add tags (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onChanged: (value) {
                              print('입력값: $value');
                            },
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Separate with commas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Wallet Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your wallet address and fees',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 3),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 76,
                                  width: 164,
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0x1A000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wallet Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                        ),
                                      ),
                                      Text(
                                        '0x1234...abcd',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 76,
                                  width: 164,
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0x1A000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Minting Fee',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                        ),
                                      ),
                                      Text(
                                        '0.05 ETH',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 42,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 42,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      fixedSize: Size(164, 42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Mint NFT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class NftFormPage extends StatefulWidget {
  @override
  _NftFormPageState createState() => _NftFormPageState();
}

class _NftFormPageState extends State<NftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mint your NFT")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Title",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "Enter the title of your NFT",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // 입력값 확인
                    print("NFT Title: ${_titleController.text}");
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
