UPDATE customer_tabs SET payment_method_id = NULL WHERE customer_id = 5112489;
UPDATE customers SET processors = NULL WHERE customer_id = 5112489;
DELETE FROM payment_methods WHERE customer_id = 5112489;