INSERT INTO hotel_bookings (
  id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at
)
SELECT
  gen_random_uuid(),
  ('00000000-0000-0000-0000-00000000000' || ((n % 4) + 1))::uuid,
  'hotel-' || lpad(((n % 12) + 1)::text, 2, '0'),
  (ARRAY['delhi', 'mumbai', 'jaipur', 'goa', 'bengaluru'])[1 + (n % 5)],
  CURRENT_DATE + ((n % 20) - 5),
  CURRENT_DATE + ((n % 20) + 1),
  (1800 + (n * 137) % 22000)::numeric(12, 2),
  (ARRAY['confirmed', 'pending', 'cancelled', 'completed'])[1 + (n % 4)],
  CURRENT_TIMESTAMP - ((n % 45) || ' days')::interval
FROM generate_series(1, 120) AS numbers(n);

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id, 'booking.created', jsonb_build_object('source', 'seed', 'version', 1), created_at
FROM hotel_bookings
WHERE id IN (SELECT id FROM hotel_bookings ORDER BY created_at DESC LIMIT 40);

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id, 'payment.updated', jsonb_build_object('provider', 'test-gateway', 'success', true), created_at + interval '1 hour'
FROM hotel_bookings
WHERE status IN ('confirmed', 'completed')
  AND id IN (SELECT id FROM hotel_bookings ORDER BY id LIMIT 30);
