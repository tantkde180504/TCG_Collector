# 🧪 QA Testing Framework - Pokémon TCG Collector

## 📋 Overview

This document provides comprehensive testing guidelines and instructions for the Pokémon TCG Collector application. As **QA & Automated Testing Engineer** (Member 4), your responsibility is to ensure the app is **bug-free, performant, and secure** before release.

---

## 🎯 Testing Strategy

### Test Layers
```
┌─────────────────────────────────────────┐
│  Integration Tests (E2E)                │ ← Complete user flows
│  Widget Tests                           │ ← UI component behavior
│  Unit Tests                             │ ← Business logic
└─────────────────────────────────────────┘
```

---

## 📁 Test Structure

```
test/
├── viewmodels/
│   ├── auth_viewmodel_test.dart        # Authentication logic tests
│   ├── cart_viewmodel_test.dart        # Shopping cart logic tests
│   └── catalog_viewmodel_test.dart     # Catalog search/filter tests
├── screens/
│   ├── login_screen_test.dart          # Login UI tests
│   ├── cart_screen_test.dart           # Cart screen UI tests
│   └── home_screen_test.dart           # (To be added)
├── integration/
│   └── app_flow_test.dart              # End-to-end user flows
├── models/
│   └── (Model tests)                   # (To be added)
├── services/
│   └── (Service tests)                 # (To be added)
└── performance_security_audit.dart     # Performance & security guidelines
```

---

## 🏃 Running Tests

### 1. **Run All Tests**
```bash
flutter test
```

### 2. **Run Specific Test File**
```bash
# Unit tests for CartViewModel
flutter test test/viewmodels/cart_viewmodel_test.dart

# Widget tests for LoginScreen
flutter test test/screens/login_screen_test.dart

# Integration tests
flutter test test/integration/app_flow_test.dart
```

### 3. **Run Tests with Coverage**
```bash
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

### 4. **Run Tests in Profile Mode** (Performance)
```bash
flutter test --profile
```

### 5. **Run Tests with Verbose Output**
```bash
flutter test -v
```

### 6. **Run Tests by Tag**
```bash
flutter test --tags unit
flutter test --tags widget
flutter test --tags integration
```

---

## ✅ Test Coverage Targets

| Component | Target | Priority |
| --- | --- | --- |
| **AuthViewModel** | 100% | 🔴 Critical |
| **CartViewModel** | 95% | 🔴 Critical |
| **CatalogViewModel** | 90% | 🟠 High |
| **Database Service** | 85% | 🟠 High |
| **UI Screens** | 80% | 🟡 Medium |
| **Overall** | **80%+** | 🟡 Target |

### Running Coverage Reports
```bash
# Generate coverage
flutter test --coverage

# View line-by-line coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📊 Unit Tests

### AuthViewModel Tests (`test/viewmodels/auth_viewmodel_test.dart`)

**Covered Scenarios:**
- ✅ Login with valid credentials
- ✅ Login with invalid email
- ✅ Login with short password
- ✅ Social login (Google/Facebook)
- ✅ Logout functionality
- ✅ Credentials persistence
- ✅ State management

**Run:**
```bash
flutter test test/viewmodels/auth_viewmodel_test.dart -v
```

---

### CartViewModel Tests (`test/viewmodels/cart_viewmodel_test.dart`)

**Covered Scenarios:**
- ✅ Add items to cart
- ✅ Remove items from cart
- ✅ Update quantities
- ✅ Calculate subtotal
- ✅ Calculate discounts
- ✅ Calculate shipping costs
- ✅ Checkout state management

**Run:**
```bash
flutter test test/viewmodels/cart_viewmodel_test.dart -v
```

---

### CatalogViewModel Tests (`test/viewmodels/catalog_viewmodel_test.dart`)

**Covered Scenarios:**
- ✅ Search functionality
- ✅ Type filtering
- ✅ Sorting (Price, Name, HP)
- ✅ Combined filtering + sorting
- ✅ Case-insensitive search
- ✅ Default state

**Run:**
```bash
flutter test test/viewmodels/catalog_viewmodel_test.dart -v
```

---

## 🎨 Widget Tests

### LoginScreen Tests (`test/screens/login_screen_test.dart`)

**Covered Scenarios:**
- ✅ Form rendering
- ✅ Email validation
- ✅ Password input masking
- ✅ Login button functionality
- ✅ Error message display
- ✅ Social login buttons

**Run:**
```bash
flutter test test/screens/login_screen_test.dart -v
```

---

### CartScreen Tests (`test/screens/cart_screen_test.dart`)

**Covered Scenarios:**
- ✅ Empty cart display
- ✅ Cart items rendering
- ✅ Price calculations
- ✅ Coupon input
- ✅ Checkout button

**Run:**
```bash
flutter test test/screens/cart_screen_test.dart -v
```

---

## 🔗 Integration Tests (E2E)

### Complete App Flow Test (`test/integration/app_flow_test.dart`)

**User Flows Tested:**
1. ✅ **Login Flow** - Successful authentication
2. ✅ **Catalog Navigation** - Browse and search products
3. ✅ **Shopping Flow** - Add items to cart
4. ✅ **Checkout Process** - Complete purchase
5. ✅ **Multi-device Support** - Test on different screen sizes
6. ✅ **Session Persistence** - User stays logged in

**Run:**
```bash
flutter test test/integration/app_flow_test.dart -v
```

---

## 🔒 Performance & Security Audit

### Performance Checklist
See: `test/performance_security_audit.dart`

**Key Metrics to Monitor:**
- ⏱️ App startup time: **< 2 seconds**
- 🎬 Frame rate: **60+ FPS**
- 💾 Memory usage: **< 200 MB**
- ⚡ Network response: **< 1 second**

### Run Performance Tests
```bash
# Run in profile mode (measures actual performance)
flutter run --profile

# In DevTools, check:
# 1. Performance tab → Frames
# 2. Memory tab → Heap size
# 3. Network tab → API response times
```

### Security Checklist
See: `test/performance_security_audit.dart`

**Key Items:**
- 🔐 No hardcoded API keys
- 🔒 Secure credential storage
- ✔️ HTTPS validation
- 🛡️ Input sanitization
- 💳 PCI DSS compliance for payments

### Check for Exposed Secrets
```bash
# Scan for API keys
grep -r "AIzaSy" lib/              # Google API
grep -r "sk_live" lib/            # PayOS keys
grep -r "firebase" lib/           # Firebase config
grep -r "token" lib/ --include="*.dart" | grep -v "// "
```

---

## 🚀 CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/flutter-tests.yml`:

```yaml
name: Flutter Tests & Quality
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run analysis
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
```

---

## 📈 Measuring Test Coverage

### Generate Coverage Report
```bash
# Run tests with coverage
flutter test --coverage

# Install lcov (if needed)
# macOS
brew install lcov
# Ubuntu
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Expected Coverage Breakdown
```
lib/
  ├── viewmodels/
  │   ├── auth_viewmodel.dart          100% ✅
  │   ├── cart_viewmodel.dart          95%  ✅
  │   ├── catalog_viewmodel.dart       90%  ✅
  │   └── ...
  ├── views/
  │   ├── login_screen.dart            85%  ✅
  │   ├── cart_screen.dart             80%  ✅
  │   └── ...
  ├── models/
  │   └── *.dart                       100% ✅
  └── services/
      └── *.dart                        85%  ✅
```

---

## 🐛 Bug Report Template

When you find a bug, create an issue with this format:

```markdown
## Bug Report

**Title:** [Critical/High/Medium/Low] - Brief description

**Description:**
Clear description of the issue

**Steps to Reproduce:**
1. Login with user@example.com
2. Navigate to Cart
3. Add item and checkout
4. Error occurs

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Screenshots:**
Attach if applicable

**Environment:**
- Flutter version: flutter --version
- Device: iPhone 13 / Pixel 6
- OS: iOS 15 / Android 12
```

---

## 🎓 Best Practices

### ✅ DO
- Write tests for critical business logic
- Test both happy path and error cases
- Use descriptive test names
- Keep tests focused and isolated
- Mock external dependencies
- Test edge cases and boundary conditions

### ❌ DON'T
- Write tests that depend on each other
- Ignore test failures
- Mock excessively (test real behavior)
- Test implementation details only
- Skip security tests
- Hardcode test data

---

## 📚 Additional Resources

### Flutter Testing Docs
- [Unit Testing Guide](https://flutter.dev/docs/testing/unit-testing)
- [Widget Testing Guide](https://flutter.dev/docs/testing/widget-testing)
- [Integration Testing Guide](https://flutter.dev/docs/testing/integration-testing)

### Mockito Documentation
- [Mockito Package](https://pub.dev/packages/mockito)
- [Mocking Examples](https://pub.dev/packages/mockito#usage)

### DevTools
- [Performance Guide](https://flutter.dev/docs/development/tools/devtools/performance)
- [Memory Profiling](https://flutter.dev/docs/development/tools/devtools/memory)

---

## 🎯 Before Every Release

### Pre-Release Checklist
- [ ] All unit tests pass (100%)
- [ ] All widget tests pass (100%)
- [ ] All integration tests pass (100%)
- [ ] Code coverage ≥ 80%
- [ ] `flutter analyze` shows 0 errors
- [ ] No performance warnings in logs
- [ ] Memory usage tested and stable
- [ ] Security audit passed
- [ ] No hardcoded secrets or credentials
- [ ] Version number incremented
- [ ] Release notes prepared
- [ ] TestFlight/Beta build successful

---

## 📞 Contact & Support

For questions about testing:
- 📧 Email: qa@pokemontcg.dev
- 🐛 Report bugs: GitHub Issues
- 💬 Slack: #qa-testing channel

---

**Happy Testing! 🎉**
