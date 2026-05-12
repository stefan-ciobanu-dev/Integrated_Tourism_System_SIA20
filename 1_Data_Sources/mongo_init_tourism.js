// ============================================================================
// MongoDB Init Script — Tourism Data (DS3)
// Database: tourism_data
// Collections: bookings, currencies
// ============================================================================

db = db.getSiblingDB('tourism_data');

// ============================================================================
// COLLECTION 1: bookings (from DS3_BOOKINGS.json structure)
// ============================================================================
db.bookings.drop();
db.bookings.insertMany([
  {
    "booking_id": "BK001",
    "booking_date": "2025-01-15",
    "guest": {
      "guest_id": "G001",
      "first_name": "John",
      "last_name": "Smith",
      "email": "john.smith@email.com",
      "country_of_origin": "United Kingdom",
      "age_group": "30-40"
    },
    "itinerary": {
      "destination": "Barcelona",
      "travel_type": "Tourism",
      "start_date": "2025-03-01",
      "end_date": "2025-03-08",
      "duration_days": 7
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL003", "quantity": 2, "price_per_unit": 150, "currency": "EUR", "subtotal": 300 },
      { "item_type": "hotel", "item_id": "7", "quantity": 7, "price_per_unit": 175, "currency": "EUR", "subtotal": 1225 }
    ],
    "totals": { "subtotal_eur": 1525, "tax_rate": 0.21, "tax_amount": 320.25, "total_eur": 1845.25, "payment_status": "Confirmed", "payment_date": "2025-01-16" },
    "agent_id": "AG001"
  },
  {
    "booking_id": "BK002",
    "booking_date": "2025-01-16",
    "guest": {
      "guest_id": "G002",
      "first_name": "Maria",
      "last_name": "Garcia",
      "email": "maria.garcia@email.com",
      "country_of_origin": "Spain",
      "age_group": "26-35"
    },
    "itinerary": {
      "destination": "Vienna",
      "travel_type": "Cultural",
      "start_date": "2025-02-14",
      "end_date": "2025-02-18",
      "duration_days": 4
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL007", "quantity": 2, "price_per_unit": 140, "currency": "EUR", "subtotal": 280 },
      { "item_type": "hotel", "item_id": "8", "quantity": 4, "price_per_unit": 245, "currency": "EUR", "subtotal": 980 }
    ],
    "totals": { "subtotal_eur": 1260, "tax_rate": 0.20, "tax_amount": 252.00, "total_eur": 1512.00, "payment_status": "Confirmed", "payment_date": "2025-01-17" },
    "agent_id": "AG002"
  },
  {
    "booking_id": "BK003",
    "booking_date": "2025-02-01",
    "guest": {
      "guest_id": "G003",
      "first_name": "Hans",
      "last_name": "Mueller",
      "email": "hans.mueller@email.de",
      "country_of_origin": "Germany",
      "age_group": "36-50"
    },
    "itinerary": {
      "destination": "Bucharest",
      "travel_type": "Business",
      "start_date": "2025-03-10",
      "end_date": "2025-03-13",
      "duration_days": 3
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL005", "quantity": 1, "price_per_unit": 120, "currency": "EUR", "subtotal": 120 },
      { "item_type": "hotel", "item_id": "3", "quantity": 3, "price_per_unit": 195, "currency": "EUR", "subtotal": 585 }
    ],
    "totals": { "subtotal_eur": 705, "tax_rate": 0.19, "tax_amount": 133.95, "total_eur": 838.95, "payment_status": "Confirmed", "payment_date": "2025-02-02" },
    "agent_id": "AG003"
  },
  {
    "booking_id": "BK004",
    "booking_date": "2025-02-10",
    "guest": {
      "guest_id": "G004",
      "first_name": "Pierre",
      "last_name": "Dupont",
      "email": "pierre.dupont@email.fr",
      "country_of_origin": "France",
      "age_group": "51-65"
    },
    "itinerary": {
      "destination": "Budapest",
      "travel_type": "Wellness",
      "start_date": "2025-04-01",
      "end_date": "2025-04-07",
      "duration_days": 6
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL027", "quantity": 2, "price_per_unit": 170, "currency": "EUR", "subtotal": 340 },
      { "item_type": "hotel", "item_id": "9", "quantity": 6, "price_per_unit": 130, "currency": "EUR", "subtotal": 780 }
    ],
    "totals": { "subtotal_eur": 1120, "tax_rate": 0.27, "tax_amount": 302.40, "total_eur": 1422.40, "payment_status": "Confirmed", "payment_date": "2025-02-11" },
    "agent_id": "AG001"
  },
  {
    "booking_id": "BK005",
    "booking_date": "2025-02-15",
    "guest": {
      "guest_id": "G005",
      "first_name": "Elena",
      "last_name": "Popescu",
      "email": "elena.popescu@email.ro",
      "country_of_origin": "Romania",
      "age_group": "26-35"
    },
    "itinerary": {
      "destination": "Paris",
      "travel_type": "Tourism",
      "start_date": "2025-05-10",
      "end_date": "2025-05-15",
      "duration_days": 5
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL017", "quantity": 2, "price_per_unit": 125, "currency": "EUR", "subtotal": 250 },
      { "item_type": "hotel", "item_id": "16", "quantity": 5, "price_per_unit": 350, "currency": "EUR", "subtotal": 1750 }
    ],
    "totals": { "subtotal_eur": 2000, "tax_rate": 0.20, "tax_amount": 400.00, "total_eur": 2400.00, "payment_status": "Confirmed", "payment_date": "2025-02-16" },
    "agent_id": "AG004"
  },
  {
    "booking_id": "BK006",
    "booking_date": "2025-03-01",
    "guest": {
      "guest_id": "G006",
      "first_name": "Isabella",
      "last_name": "Rossi",
      "email": "isabella.rossi@email.it",
      "country_of_origin": "Italy",
      "age_group": "18-25"
    },
    "itinerary": {
      "destination": "Amsterdam",
      "travel_type": "Tourism",
      "start_date": "2025-06-01",
      "end_date": "2025-06-05",
      "duration_days": 4
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL019", "quantity": 1, "price_per_unit": 150, "currency": "EUR", "subtotal": 150 },
      { "item_type": "hotel", "item_id": "11", "quantity": 4, "price_per_unit": 185, "currency": "EUR", "subtotal": 740 }
    ],
    "totals": { "subtotal_eur": 890, "tax_rate": 0.21, "tax_amount": 186.90, "total_eur": 1076.90, "payment_status": "Confirmed", "payment_date": "2025-03-02" },
    "agent_id": "AG002"
  },
  {
    "booking_id": "BK007",
    "booking_date": "2025-03-10",
    "guest": {
      "guest_id": "G007",
      "first_name": "Stefan",
      "last_name": "Novak",
      "email": "stefan.novak@email.cz",
      "country_of_origin": "Czech Republic",
      "age_group": "36-50"
    },
    "itinerary": {
      "destination": "Brasov",
      "travel_type": "Adventure",
      "start_date": "2025-07-15",
      "end_date": "2025-07-22",
      "duration_days": 7
    },
    "booking_items": [
      { "item_type": "hotel", "item_id": "4", "quantity": 7, "price_per_unit": 140, "currency": "EUR", "subtotal": 980 }
    ],
    "totals": { "subtotal_eur": 980, "tax_rate": 0.19, "tax_amount": 186.20, "total_eur": 1166.20, "payment_status": "Confirmed", "payment_date": "2025-03-11" },
    "agent_id": "AG003"
  },
  {
    "booking_id": "BK008",
    "booking_date": "2025-03-20",
    "guest": {
      "guest_id": "G008",
      "first_name": "Lars",
      "last_name": "Jensen",
      "email": "lars.jensen@email.dk",
      "country_of_origin": "Denmark",
      "age_group": "26-35"
    },
    "itinerary": {
      "destination": "Rome",
      "travel_type": "Cultural",
      "start_date": "2025-04-20",
      "end_date": "2025-04-25",
      "duration_days": 5
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL023", "quantity": 2, "price_per_unit": 100, "currency": "EUR", "subtotal": 200 },
      { "item_type": "hotel", "item_id": "12", "quantity": 5, "price_per_unit": 170, "currency": "EUR", "subtotal": 850 }
    ],
    "totals": { "subtotal_eur": 1050, "tax_rate": 0.22, "tax_amount": 231.00, "total_eur": 1281.00, "payment_status": "Confirmed", "payment_date": "2025-03-21" },
    "agent_id": "AG005"
  },
  {
    "booking_id": "BK009",
    "booking_date": "2025-04-01",
    "guest": {
      "guest_id": "G009",
      "first_name": "Yuki",
      "last_name": "Tanaka",
      "email": "yuki.tanaka@email.jp",
      "country_of_origin": "Japan",
      "age_group": "26-35"
    },
    "itinerary": {
      "destination": "London",
      "travel_type": "Tourism",
      "start_date": "2025-08-01",
      "end_date": "2025-08-10",
      "duration_days": 9
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL011", "quantity": 1, "price_per_unit": 720, "currency": "USD", "subtotal": 720 },
      { "item_type": "hotel", "item_id": "20", "quantity": 9, "price_per_unit": 290, "currency": "GBP", "subtotal": 2610 }
    ],
    "totals": { "subtotal_eur": 3100, "tax_rate": 0.20, "tax_amount": 620.00, "total_eur": 3720.00, "payment_status": "Pending", "payment_date": null },
    "agent_id": "AG001"
  },
  {
    "booking_id": "BK010",
    "booking_date": "2025-04-05",
    "guest": {
      "guest_id": "G010",
      "first_name": "Andrei",
      "last_name": "Ionescu",
      "email": "andrei.ionescu@email.ro",
      "country_of_origin": "Romania",
      "age_group": "36-50"
    },
    "itinerary": {
      "destination": "Lisbon",
      "travel_type": "Tourism",
      "start_date": "2025-09-01",
      "end_date": "2025-09-08",
      "duration_days": 7
    },
    "booking_items": [
      { "item_type": "hotel", "item_id": "1", "quantity": 7, "price_per_unit": 220, "currency": "EUR", "subtotal": 1540 }
    ],
    "totals": { "subtotal_eur": 1540, "tax_rate": 0.23, "tax_amount": 354.20, "total_eur": 1894.20, "payment_status": "Confirmed", "payment_date": "2025-04-06" },
    "agent_id": "AG004"
  },
  {
    "booking_id": "BK011",
    "booking_date": "2025-04-15",
    "guest": {
      "guest_id": "G011",
      "first_name": "Sophie",
      "last_name": "Martin",
      "email": "sophie.martin@email.fr",
      "country_of_origin": "France",
      "age_group": "18-25"
    },
    "itinerary": {
      "destination": "Prague",
      "travel_type": "Cultural",
      "start_date": "2025-06-20",
      "end_date": "2025-06-24",
      "duration_days": 4
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL017", "quantity": 1, "price_per_unit": 125, "currency": "EUR", "subtotal": 125 },
      { "item_type": "hotel", "item_id": "10", "quantity": 4, "price_per_unit": 95, "currency": "EUR", "subtotal": 380 }
    ],
    "totals": { "subtotal_eur": 505, "tax_rate": 0.21, "tax_amount": 106.05, "total_eur": 611.05, "payment_status": "Confirmed", "payment_date": "2025-04-16" },
    "agent_id": "AG002"
  },
  {
    "booking_id": "BK012",
    "booking_date": "2025-05-01",
    "guest": {
      "guest_id": "G012",
      "first_name": "Carlos",
      "last_name": "Fernandez",
      "email": "carlos.fernandez@email.es",
      "country_of_origin": "Spain",
      "age_group": "51-65"
    },
    "itinerary": {
      "destination": "Berlin",
      "travel_type": "Business",
      "start_date": "2025-05-20",
      "end_date": "2025-05-23",
      "duration_days": 3
    },
    "booking_items": [
      { "item_type": "flight", "item_id": "FL015", "quantity": 1, "price_per_unit": 160, "currency": "EUR", "subtotal": 160 },
      { "item_type": "hotel", "item_id": "13", "quantity": 3, "price_per_unit": 110, "currency": "EUR", "subtotal": 330 }
    ],
    "totals": { "subtotal_eur": 490, "tax_rate": 0.19, "tax_amount": 93.10, "total_eur": 583.10, "payment_status": "Confirmed", "payment_date": "2025-05-02" },
    "agent_id": "AG003"
  }
]);

print("Bookings collection: " + db.bookings.countDocuments() + " documents inserted");

// ============================================================================
// COLLECTION 2: currencies (from DS3_CURRENCIES.json structure)
// ============================================================================
db.currencies.drop();
db.currencies.insertOne({
  "base_currency": "EUR",
  "extraction_date": "2025-01-15",
  "rates": [
    { "currency_code": "USD", "currency_name": "United States Dollar", "exchange_rate": 1.0850, "region": "North America", "symbol": "$" },
    { "currency_code": "GBP", "currency_name": "British Pound Sterling", "exchange_rate": 0.8450, "region": "Europe", "symbol": "£" },
    { "currency_code": "JPY", "currency_name": "Japanese Yen", "exchange_rate": 163.4200, "region": "Asia", "symbol": "¥" },
    { "currency_code": "CHF", "currency_name": "Swiss Franc", "exchange_rate": 0.9450, "region": "Europe", "symbol": "CHF" },
    { "currency_code": "SEK", "currency_name": "Swedish Krona", "exchange_rate": 11.2300, "region": "Europe", "symbol": "kr" },
    { "currency_code": "DKK", "currency_name": "Danish Krone", "exchange_rate": 7.4450, "region": "Europe", "symbol": "kr" },
    { "currency_code": "NOK", "currency_name": "Norwegian Krone", "exchange_rate": 11.5850, "region": "Europe", "symbol": "kr" },
    { "currency_code": "PLN", "currency_name": "Polish Zloty", "exchange_rate": 4.3250, "region": "Europe", "symbol": "zł" },
    { "currency_code": "CZK", "currency_name": "Czech Koruna", "exchange_rate": 25.1200, "region": "Europe", "symbol": "Kč" },
    { "currency_code": "HUF", "currency_name": "Hungarian Forint", "exchange_rate": 393.5000, "region": "Europe", "symbol": "Ft" },
    { "currency_code": "RON", "currency_name": "Romanian Leu", "exchange_rate": 4.9750, "region": "Europe", "symbol": "lei" },
    { "currency_code": "TRY", "currency_name": "Turkish Lira", "exchange_rate": 32.8500, "region": "Europe", "symbol": "₺" },
    { "currency_code": "AUD", "currency_name": "Australian Dollar", "exchange_rate": 1.6250, "region": "Oceania", "symbol": "A$" },
    { "currency_code": "CAD", "currency_name": "Canadian Dollar", "exchange_rate": 1.4650, "region": "North America", "symbol": "C$" },
    { "currency_code": "BRL", "currency_name": "Brazilian Real", "exchange_rate": 5.3200, "region": "South America", "symbol": "R$" }
  ]
});

print("Currencies collection: " + db.currencies.countDocuments() + " documents inserted");

// ============================================================================
// Verification
// ============================================================================
print("\n=== MongoDB Tourism Data Verification ===");
print("Database: tourism_data");
print("Collections: " + db.getCollectionNames());
print("Bookings count: " + db.bookings.countDocuments());
print("Currencies count: " + db.currencies.countDocuments());
print("Sample booking: " + JSON.stringify(db.bookings.findOne({booking_id: "BK001"}), null, 2));
