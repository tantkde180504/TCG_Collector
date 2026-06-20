# PROJECT REPORT: POKÉMON TCG COLLECTOR MOBILE APP
**Course**: Mobile Application Development (Flutter)  
**Project Title**: Pokémon TCG Collector Store  
**Platform**: Android, iOS, Web

---

## 1. Team Introduction

Our project team consists of three core members, each handling specific areas of the development life cycle:

| Member Name | Student ID | Primary Role | Contributions Summary |
| :--- | :--- | :--- | :--- |
| **Nguyen Van A** | SE160001 | Project Lead & Lead Developer | Database design (`DatabaseService` SQLite schemas), state management architecture (MVVM ViewModels), and core application router setup. |
| **Tran Thi B** | SE160002 | UI/UX Designer & Developer | Custom widget design system, custom canvas painters (`PriceChartPainter`, `RadarMapPainter`), and 3D Card-Flipping gestures. |
| **Le Van C** | SE160003 | QA Engineer & Analyst | System requirement analysis, manual testing verification matrices, and automated unit/widget tests validation. |

---

## 2. Case Study

### Business Scenario
The Trading Card Games (TCG) market, particularly Pokémon TCG, is experiencing massive global growth. Rare cards are no longer just toys; they are valuable collectibles and financial assets, with some cards priced from hundreds to thousands of dollars. 

To address the needs of this collector community, we designed the **Pokémon TCG Collector Store**. This mobile app provides a dedicated e-commerce experience for trainers, allowing them to:
- Verify real-time market value fluctuations using interactive graphs.
- Filter, search, and purchase authentic cards.
- Chat in real-time with local support (Professor Oak) for card deck recommendations and order updates.
- Track down local physical retail hobby shops via an interactive location radar.

---

## 3. Business Analysis & System Design

### Functional Requirements
1. **User Authentication**: Secure credentials verification, session caching via SharedPreferences, and Google/Nintendo account logins.
2. **Product Catalog**: Multi-attribute card grid showing system elements, HP stats, prices, and rarities.
3. **Smart Filters**: Dynamic filtering tabs by element (Fire, Water, Grass, etc.) and search typing bar.
4. **Holographic Detail Cards**: 3D perspective rotation flipping cards to view backs, and detailed combat stats.
5. **Interactive Price Charts**: 7-day bezier curves illustrating market value trends.
6. **Active Shopping Cart**: Quantity incrementors, swipe-to-delete, and discount coupon validations.
7. **Multi-Step Checkout**: Form-validated address entry, secure payment options, and invoice creation.
8. **Store Locator Map**: Stylized vector-drawn map pinpointing physical coordinates and calculating step-by-step navigation instructions.
9. **Support Desk Chat**: Interactive query suggestion chips and instant automated answers from a simulated support agent.
10. **System Alerts**: Order dispatch tracking and announcement updates.

### Non-Functional Requirements
- **Performance**: High scroll frames (60 FPS) when loading lists of card graphics.
- **Aesthetic**: Customized Dark Material 3 theme incorporating trademark Pokémon styling.
- **Cross-Platform Resilience**: Automated database fallback. Uses SQLite on Android devices and falls back to local storage/in-memory on Windows/Web targets.

### Architecture: Model-View-ViewModel (MVVM)
We implemented the standard MVVM design pattern in Flutter:
- **Model**: Declares clear schemas for `PokemonCard`, `CartItem`, `OrderItem`, `ChatMessage`, and `NotificationModel`.
- **ViewModel**: Uses `Provider` package to hold state and expose actions, decoupling UI layouts from database controllers:
  - `AuthViewModel`: Manages authentication state.
  - `CatalogViewModel`: Manages sorting, filters, and searches.
  - `CartViewModel`: Manages active cart items, subtotal math, and invoices.
  - `ChatViewModel`: Drives chat dialog updates and bot responder triggers.
  - `NotificationViewModel`: Emits system announcements.
- **View**: UI widgets that build layout layouts according to active ViewModel changes.

### Database Design (SQLite Schema)
```sql
CREATE TABLE cards (
  card_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  rarity TEXT NOT NULL,
  market_price REAL NOT NULL,
  price_history TEXT NOT NULL, -- Stored as comma-separated values (CSV)
  description TEXT,
  image_url TEXT,
  hp INTEGER,
  attack_name TEXT,
  attack_damage INTEGER,
  weakness TEXT,
  retreat_cost INTEGER
);

CREATE TABLE cart (
  card_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL
);

CREATE TABLE orders (
  order_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  items_json TEXT NOT NULL, -- Serialized CartItem list
  total_amount REAL NOT NULL,
  status TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  shipping_address TEXT NOT NULL,
  payment_method TEXT NOT NULL
);

CREATE TABLE messages (
  message_id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  text TEXT NOT NULL,
  timestamp TEXT NOT NULL
);
```

---

## 4. Development Requirements & Proof of Execution

### UI Design System
- **Theme**: Cyber Dark Theme (`#121212` backgrounds).
- **Branding Accents**: Neon yellow elements (`Colors.amber`), crimson alerts (`Colors.redAccent`), and glowing colored borders corresponding to card elemental types.
- **Typographic Scale**: Outfit/Google Fonts style, using bold labels.

### State Management Flow
The app triggers UI updates through `ChangeNotifierProvider` and `context.watch<T>()` / `context.read<T>()`.
```
[User interacts with UI Widget] 
    --> [Triggers ViewModel Action (e.g. cartVM.addToCart)]
    --> [ViewModel edits Model / updates SQLite database]
    --> [ViewModel calls notifyListeners()]
    --> [UI Widgets rebuild responsively with updated values]
```

### Automated Tests Execution
We implemented automated tests covering unit calculations and widget layouts:
1. **Unit Test (`test/cart_test.dart`)**: Asserts Cart additions, quantity changes, shipping fees, and coupon application logic.
2. **Widget Test (`test/login_widget_test.dart`)**: Verifies Login UI layout, input form validation flags, and credentials helpers.

#### Test Execution Outputs:
All tests successfully pass:
```bash
$ flutter test
00:02 +1: CartViewModel Unit Tests Initial cart is empty
00:02 +2: CartViewModel Unit Tests Adding cards to cart updates totals
00:02 +3: CartViewModel Unit Tests Quantity update adjust calculations
00:03 +4: CartViewModel Unit Tests Applying coupon codes affects grand total
00:03 +5: CartViewModel Unit Tests Removing cards from cart works
00:03 +6: CartViewModel Unit Tests Clearing cart resets all states
00:03 +7: LoginScreen Widget Tests Login screen elements are rendered
00:04 +8: LoginScreen Widget Tests Submitting empty form triggers validation error alerts
00:04 +9: LoginScreen Widget Tests Auto-fill credentials helper button works
00:04 +10: App Boot Smoke Test
00:05 +10: All tests passed!
```

---

## 5. Demo & Function Walkthrough

### 1. Login Gate
Features Pokémon branding, input validation (e.g., checks for `@` and minimum 6-character password length), and a demo credentials helper button for grading.

### 2. Product Catalog
Displays cards in a double-column grid layout, each inside a glowing border reflecting its type. Includes instant searches and type filters (Fire, Water, Grass, Lightning, etc.).

### 3. Card Detail & 3D Flip
Tapping a card displays its details. Double-tapping the card triggers a 3D flip animation showing the card back. Underneath, a custom bezier curve outlines the card's 7-day price history.

### 4. Cart & Coupons
Allows quantity adjustment and item deletion. Applying coupon codes like `PIKACHU10` (10% off) or `CHARIZARD20` (20% off) instantly adjusts the total price.

### 5. Multi-Step Checkout
Guides users through address registration, payment selection (Credit Card, PayPal, or PokéGold), and displays a detailed final invoice receipt upon order placement.

### 6. Location Radar Map
A vector-drawn city grid map showing user coordinates (pulsing blue node) and card shops. Selecting a shop draws a route and provides step-by-step directions.

### 7. Support Chat
Provides real-time chat with Professor Oak. Selecting quick-reply chips generates instant, helpful responses after a realistic delay (complete with a typing indicator).

---

## 6. Conclusion & Discussion

### Pros
- **Premium UI**: Dark mode with custom vector-drawn graphics and 3D card flips provides a high-quality user experience.
- **Cross-Platform Compatibility**: Automatically falls back to SharedPreferences and memory-based persistence when SQLite is unavailable on Windows/Web.
- **Offline Capabilities**: Pre-loaded catalog data ensures the app remains usable offline.

### Cons & Future Scope
- **Static Map**: The custom vector map is ideal for a few store pins, but integrating real map tiles (e.g., Mapbox or Google Maps SDK) would be necessary for a global store directory.
- **Real Backend**: In the future, we plan to migrate the mock chat assistant to a real cloud-based Chatbot (like Gemini API) and replace the local SQLite fallback with Firebase Firestore to enable real-time trading.

---

## 7. Contribution Table

| Topic | Team Effort | Nguyen Van A | Tran Thi B | Le Van C |
| :--- | :--- | :--- | :--- | :--- |
| **Case Study Analysis** | 100% | 35% | 35% | 30% |
| **Business Analysis** | 100% | 30% | 30% | 40% |
| **System Design** | 100% | 40% | 40% | 20% |
| **Implementation** | 100% | 50% | 40% | 10% |
| **Documentation** | 100% | 30% | 30% | 40% |
| **Average Contribution** | **100%** | **37%** | **35%** | **28%** |
