import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Welcome back to\nAudion !",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
             // 이미지 placeholder
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    const Spacer(),
                    Expanded(// 오른쪽 1/2 내용
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Image Placeholder'),
                      ),
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 30),

              // Email
              const Text("Email"),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: "이메일 입력",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              const Text("Password"),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "비밀번호 입력",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 24),

              // 지갑으로 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/selectWallet');
                  },
                  child: const Text("지갑으로 로그인"),
                ),
              ),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Divider(thickness: 1, color: Color(0xFFBDBDBD)),
              ),

              const SizedBox(height: 15),

              const Text("이메일 / 비밀번호 찾기"),

              const SizedBox(height: 15),

              const Text("회원가입"),
            ],
          ),
        ),
      ),
    );
  }
}

