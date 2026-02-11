import 'dart:convert';

// 메뉴 하나하나를 정의하는 설계도
class Menu {
  final String name;
  final String category; // 한식, 중식, 일식 등

  Menu({required this.name, required this.category});

  // 데이터 저장할 때 필요한 변환 기능
  Map<String, dynamic> toJson() => {'name': name, 'category': category};
  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(name: json['name'], category: json['category']);
  }
}

// 기본으로 들어갈 메뉴들 (앱 처음 켤 때 사용)
final List<Menu> defaultMenus = [
  Menu(name: '김치찌개', category: '한식'),
  Menu(name: '된장찌개', category: '한식'),
  Menu(name: '삼겹살', category: '한식'),
  Menu(name: '비빔밥', category: '한식'),
  Menu(name: '국밥', category: '한식'),

  Menu(name: '짜장면', category: '중식'),
  Menu(name: '짬뽕', category: '중식'),
  Menu(name: '마라탕', category: '중식'),
  Menu(name: '탕수육', category: '중식'),

  Menu(name: '돈가스', category: '일식'),
  Menu(name: '초밥', category: '일식'),
  Menu(name: '라멘', category: '일식'),
  Menu(name: '우동', category: '일식'),

  Menu(name: '파스타', category: '양식'),
  Menu(name: '피자', category: '양식'),
  Menu(name: '햄버거', category: '양식'),
  Menu(name: '스테이크', category: '양식'),

  Menu(name: '라면', category: '분식'),
  Menu(name: '떡볶이', category: '분식'),
  Menu(name: '김밥', category: '분식'),

  Menu(name: '쌀국수', category: '아시안'),
  Menu(name: '샌드위치', category: '간편식'),
  Menu(name: '샐러드', category: '다이어트'),
  Menu(name: '치킨', category: '치킨'),
];
