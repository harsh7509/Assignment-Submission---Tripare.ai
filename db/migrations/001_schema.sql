CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE hotel_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  hotel_id VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  checkin_date DATE NOT NULL,
  checkout_date DATE NOT NULL,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT valid_booking_dates CHECK (checkout_date > checkin_date)
);

CREATE TABLE booking_events (
  id BIGSERIAL PRIMARY KEY,
  booking_id UUID NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hotel_bookings_city_created_org_status
  ON hotel_bookings (city, created_at, org_id, status);

CREATE INDEX idx_booking_events_booking_created
  ON booking_events (booking_id, created_at);
