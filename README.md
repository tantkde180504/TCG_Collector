# ⚡ Pokémon TCG Collector - Flutter Mobile Application

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)]()
[![Database](https://img.shields.io/badge/Database-Firebase_Firestore-orange.svg)]()

Một ứng dụng di động hoàn chỉnh được phát triển bằng Flutter, cho phép các Trainer tìm kiếm, quản lý bộ sưu tập, theo dõi biến động giá và mua sắm các thẻ bài Pokémon TCG (Trading Card Game) chính hãng. Dự án đáp ứng đầy đủ các tiêu chuẩn phân tích nghiệp vụ, kiến trúc phần mềm và kiểm thử.

---

## 👥 1. Team Introduction & Contribution

### Members & Roles
| Full Name | Student ID | Role | Key Responsibilities |
| :--- | :--- | :--- | :--- |
| **Member 1** | SE1XXXXX | **Project Manager / Developer** | Quản lý tiến độ, cấu trúc MVVM, State Management, Cơ sở dữ liệu |
| **Member 2** | SE1XXXXX | **UI/UX Developer** | Phát triển giao diện (Sản phẩm, Chi tiết, Bản đồ, Chat) |
| **Member 3** | SE1XXXXX | **Business Analyst / QA** | Phân tích nghiệp vụ, Viết Unit Test & Widget Test, Documentation |

### Contribution Evaluation Matrix
| Topic | Team Effort | Member 1 | Member 2 | Member 3 |
| :--- | :---: | :---: | :---: | :---: |
| **Case Study Analysis** | 100% | 34% | 33% | 33% |
| **Business Analysis** | 100% | 20% | 20% | 60% |
| **System Design** | 100% | 50% | 30% | 20% |
| **Implementation** | 100% | 50% | 50% | 0% |
| **Documentation** | 100% | 30% | 20% | 50% |

---

## 📖 2. Case Study (Pokémon TCG Marketplace)

Thị trường thẻ bài Pokémon TCG (Trading Card Game) đang phát triển vô cùng mạnh mẽ, kéo theo nhu cầu trao đổi, mua bán và cập nhật giá trị thẻ theo thời gian thực của các nhà sưu tầm (Trainers). 

**Pokémon TCG Collector** ra đời nhằm giải quyết bài toán quản lý và giao dịch thẻ bài thông qua một nền tảng di động tiện lợi. Ứng dụng tích hợp công nghệ lưu trữ thời gian thực và bản đồ tương tác, giúp kết nối cộng đồng người chơi với các cửa hàng vật lý một cách liền mạch.

---

## 📊 3. Business Analysis & System Design

### 🎯 Requirements
#### Functional Requirements (Yêu cầu chức năng)
* **Quản lý người dùng:** Đăng ký, đăng nhập bằng Email/Mạng xã hội, quản lý hồ sơ Trainer.
* **Danh mục sản phẩm:** Hiển thị lưới thẻ bài, bộ lọc nâng cao theo Hệ (Fire, Water, Grass...) và độ hiếm.
* **Giỏ hàng & Thanh toán:** Thêm/sửa/xóa thẻ, áp dụng mã giảm giá, quy trình thanh toán 3 bước.
* **Thông báo:** Cập nhật trạng thái đơn hàng và các sự kiện phát hành thẻ mới.
* **Hỗ trợ trực tuyến:** Chat thời gian thực với đội ngũ hỗ trợ (Trainer Support).
* **Bản đồ định vị:** Tìm kiếm các cửa hàng thẻ bài vật lý xung quanh vị trí người dùng.

#### Non-functional Requirements (Yêu cầu phi chức năng)
* **Hiệu năng:** Mượt mà khi cuộn danh sách (Lazy loading hình ảnh độ phân giải cao), tốc độ phản hồi < 2s.
* **Giao diện (Design System):** Thiết kế đậm chất Pokémon (Màu chủ đạo: *Pokémon Red*, *Electric Yellow*), tuân thủ Material Design.
* **Bảo mật:** Mã hóa thông tin người dùng, phân quyền truy cập thông qua Firebase Auth.

### 🏗️ Application Architecture
Dự án áp dụng kiến trúc **MVVM (Model - View - ViewModel)** kết hợp với **State Management (BLoC / Provider)** nhằm tách biệt hoàn toàn giữa logic nghiệp vụ và giao diện hiển thị.
