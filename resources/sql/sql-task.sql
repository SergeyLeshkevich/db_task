-- 1.Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT model ->> 'en' AS model,
       fare_conditions,
       count(fare_conditions)
FROM aircrafts_data
         INNER JOIN seats s ON aircrafts_data.aircraft_code = s.aircraft_code
GROUP BY fare_conditions, model
ORDER BY model;

-- 2.Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT model ->> 'en' AS model, count(fare_conditions) AS count
FROM aircrafts_data
         INNER JOIN seats s on aircrafts_data.aircraft_code = s.aircraft_code
GROUP BY model
ORDER BY count DESC
LIMIT 3;

-- 3.Найти все рейсы, которые задерживались более 2 часов
SELECT flight_no, scheduled_departure, actual_departure
FROM flights
WHERE actual_departure - scheduled_departure > INTERVAL '2 hour';

-- 4.Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'),
--     с указанием имени пассажира и контактных данных
SELECT passenger_name, contact_data, fare_conditions, book_date
FROM tickets
         INNER JOIN ticket_flights tf on tickets.ticket_no = tf.ticket_no
         INNER JOIN bookings b on tickets.book_ref = b.book_ref
WHERE fare_conditions = 'Business'
ORDER BY book_date DESC
LIMIT 10;

-- 5.Найти все рейсы, у которых нет забронированных мест в бизнес-классе
-- (fare_conditions = 'Business')
SELECT DISTINCT f.flight_no
FROM flights f
WHERE NOT EXISTS (SELECT *
                  FROM seats s
                  WHERE s.aircraft_code = f.aircraft_code
                    AND s.fare_conditions = 'Business');

-- 6.Получить с  писок аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT airport_name ->> 'en' AS airport_name, city ->> 'en' AS city
FROM airports_data ad
         INNER JOIN flights f on ad.airport_code = f.departure_airport
WHERE f.actual_departure - f.scheduled_departure > INTERVAL '1 minute';

-- 7.Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта,
-- отсортированный по убыванию количества рейсов
SELECT DISTINCT airport_name ->> 'en' AS airport_name, count(departure_airport) AS count
FROM airports_data
         INNER JOIN flights f on airports_data.airport_code = f.departure_airport
group by airport_name
ORDER BY count DESC;

-- 8.Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено
--     и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT *
FROM flights f
WHERE (f.scheduled_arrival != f.actual_arrival);

-- 9.Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT ad.aircraft_code, model ->> 'ru' AS model, fare_conditions
FROM aircrafts_data As ad
         INNER JOIN seats s on ad.aircraft_code = s.aircraft_code
WHERE fare_conditions != 'Economy'
  AND model ->> 'ru' = 'Аэробус A321-200';

-- 10.Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT air.city, air.airport_code, air.airport_name
FROM (SELECT city, count(*)
      FROM airports
      GROUP BY city
      HAVING count(*) > 1) AS a
         JOIN airports AS air ON a.city = air.city
ORDER BY air.city, air.airport_name;

-- 11.Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT t.passenger_id,
       t.passenger_name,
       SUM(b.total_amount) AS total_booking_amount
FROM tickets t
         JOIN bookings b ON t.book_ref = b.book_ref
GROUP BY t.passenger_id, t.passenger_name
HAVING SUM(b.total_amount) >
       (SELECT AVG(total_amount)
        FROM bookings);

-- 12.Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT *
FROM flights_v fv
WHERE fv.departure_city = 'Екатеринбург'
  AND fv.arrival_city = 'Москва'
  AND status = 'On Time'
ORDER BY fv.scheduled_departure
LIMIT 1;

-- 13.Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT concat('Cheapest N:', min_tecket_no, ', price = ', min_amount)  AS cheapest,
       concat('Expensive N:', max_ticket_no, ', price = ', max_amount) AS expensive
FROM (SELECT ticket_no AS max_ticket_no,
             amount    AS max_amount
      FROM ticket_flights
      ORDER BY amount DESC
      LIMIT 1) AS max,
     (SELECT ticket_no AS min_tecket_no,
             amount    AS min_amount
      FROM ticket_flights
      ORDER BY amount
      LIMIT 1) AS min;

-- 14.Написать DDL таблицы Customers , должны быть поля id , firstName, LastName, email , phone. Добавить ограничения
-- на поля (constraints)
CREATE TABLE customers
(
    id        BIGSERIAL PRIMARY KEY,
    firstName VARCHAR(25) NOT NULL CHECK (firstName ~* '^[A-Za-z]+$'),
    lastName  VARCHAR(25) NOT NULL CHECK (lastName ~* '^[A-Za-z]+$'),
    email     VARCHAR(30) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    phone     VARCHAR(25) NOT NULL CHECK (phone LIKE '+%')
);

-- 15.Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу
-- customers + constraints
CREATE TABLE IF NOT EXISTS orders
(
    id         BIGSERIAL PRIMARY KEY,
    customerId BIGSERIAL NOT NULL REFERENCES customers (id),
    quantity   INTEGER   NOT NULL CHECK (quantity > 0)
);

-- 16.Написать 5 insert в эти таблицы
INSERT INTO customers (firstName, lastName, email, phone)
VALUES ('Lawrence', 'Luna', 'lawrence@gmail.com', '+39(3580)330-06-56'),
       ('Amy', 'Carter', 'carter@yandex.ru', '+113(91)293-37-50'),
       ('Alexis', 'Moreno', 'moreno111@mail.ru', '+9(02)830-26-13'),
       ('Denise', 'Cisneros', 'cisneros_denise@gmail.com', '+70(81)006-63-59'),
       ('Brian', 'Meyer', 'brian_meyer@gmail.com', '+348(386)340-47-65');

INSERT INTO orders (customerId, quantity)
VALUES (1, 10),
       (2, 15),
       (3, 6),
       (4, 3),
       (5, 17);

-- 17.Удалить таблицы
DROP TABLE IF EXISTS orders, customers;