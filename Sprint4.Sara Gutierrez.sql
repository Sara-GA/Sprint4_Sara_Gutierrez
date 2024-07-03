CREATE DATABASE Sprint4;

-- Empezamos a crear las tablas de dimensiones:

USE Sprint4;
CREATE TABLE products ( id  INT PRIMARY KEY,
Product_name VARCHAR (100),
Price VARCHAR (100),
Colour VARCHAR(100),
Weight DECIMAL (5,2),
Warehouse_id VARCHAR (100));

-- Y cargamos los datos:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM products;

-- Vamos haciendo lo mismo con el resto: 

CREATE TABLE credit_cards (id VARCHAR (100) PRIMARY KEY,
user_id VARCHAR (100),
iban VARCHAR (100),
pan VARCHAR (100),
pin VARCHAR (100),
cvv VARCHAR (100),
track1 VARCHAR(150),
track2 VARCHAR(150),
expiring_date VARCHAR (100));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM credit_cards;

CREATE TABLE companies (company_id VARCHAR (100) PRIMARY KEY,
company_name VARCHAR (100),
phone VARCHAR (100),
email VARCHAR (100),
country VARCHAR (100),
website VARCHAR (100));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM companies;

CREATE TABLE users_ca ( id VARCHAR (100) PRIMARY KEY,
name VARCHAR (100),
surname VARCHAR (100),
phone VARCHAR (100),
email VARCHAR (100),
birth_date VARCHAR (100),
country VARCHAR (100),
city VARCHAR (100),
postal_code VARCHAR (100),
address VARCHAR (100));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE users_ca
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM users_ca;

CREATE TABLE users_uk ( id VARCHAR (100) PRIMARY KEY,
name VARCHAR (100),
surname VARCHAR (100),
phone VARCHAR (100),
email VARCHAR (100),
birth_date VARCHAR (100),
country VARCHAR (100),
city VARCHAR (100),
postal_code VARCHAR (100),
address VARCHAR (100));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE users_uk
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM users_uk;

CREATE TABLE users_usa ( id VARCHAR (100) PRIMARY KEY,
name VARCHAR (100),
surname VARCHAR (100),
phone VARCHAR (100),
email VARCHAR (100),
birth_date VARCHAR (100),
country VARCHAR (100),
city VARCHAR (100),
postal_code VARCHAR (100),
address VARCHAR (100));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE users_usa
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM users_usa;

-- Unificamos las tablas de users:

CREATE TABLE users ( id VARCHAR (100) PRIMARY KEY,
name VARCHAR (100),
surname VARCHAR (100),
phone VARCHAR (100),
email VARCHAR (100),
birth_date VARCHAR (100),
country VARCHAR (100),
city VARCHAR (100),
postal_code VARCHAR (100),
address VARCHAR (100),
region VARCHAR (10));

INSERT INTO users (id, name, surname, phone, email, birth_date, country, city, postal_code, address, region)
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address,'CA' FROM users_ca;

INSERT INTO users (id, name, surname, phone, email, birth_date, country, city, postal_code, address, region)
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address,'UK' FROM users_uk;

INSERT INTO users (id, name, surname, phone, email, birth_date, country, city, postal_code, address, region)
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address,'USA' FROM users_usa;

SELECT * FROM users; 

-- Eliminamos las tablas de usuarios de usa, uk y ca porque ya no las necesitamos:

DROP TABLE users_ca;
DROP TABLE users_uk;
DROP TABLE users_usa;


-- Creamos la tabla de hechos:

CREATE TABLE transactions ( id VARCHAR (100) PRIMARY KEY,
card_id VARCHAR (100),
business_id VARCHAR (100),
timestamp datetime, 
amount DECIMAL (6,2),
decline INT,
product_ids VARCHAR (100),
user_id VARCHAR (100),
lat FLOAT, 
longitude FLOAT, 
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
FOREIGN KEY (business_id) REFERENCES companies(company_id),
FOREIGN KEY (product_ids) REFERENCES products(id),
FOREIGN KEY (user_id) REFERENCES users(id));

-- Cargamos los datos en transactions:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Corrección del error: Error Code: 3780. Referencing column 'product_ids' and referenced column 'id' in foreign key constraint 'transactions_ibfk_3' are incompatible.

ALTER TABLE products 
MODIFY COLUMN id VARCHAR(100);

-- Corrección del error: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`sprint4`.`transactions`, CONSTRAINT `transactions_ibfk_3` FOREIGN KEY (`product_ids`) REFERENCES `products` (`id`))
-- No puede referenciarse los Id de productos con la tabla de transactions porque en la columna de Id-product hay más de un elemento por fila.
-- Para ello vamos a eleminar la foreing key que hemos creado y crear una tabla intermedia que conecte con las dos:

SHOW CREATE TABLE transactions;  -- Obtener el nombre de la clave foránea
ALTER TABLE transactions DROP FOREIGN KEY transactions_ibfk_3; 


-- Creamos la tabla intermedia entre transactions and products: 

CREATE TABLE transaction_products (transaction_id VARCHAR(100),
    product_id VARCHAR (100),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id));
    
-- Introducimos los datos que vcogemos de las tablas transactions y products:

INSERT INTO transaction_products (transaction_id, product_id)
SELECT 
    id AS transaction_id, 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(product_ids, ' ', ''), ',', numbers.n), ',', -1)) AS product_id
FROM 
    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    INNER JOIN transactions ON CHAR_LENGTH(REPLACE(product_ids, ' ', '')) - CHAR_LENGTH(REPLACE(REPLACE(product_ids, ' ', ''), ',', '')) >= numbers.n - 1;

-- Comprobamos que todo esté correcto: 

SELECT * FROM transaction_products;

-- Cogemos esta transacción com ejemplo para comprobar:
-- 02C6201E-D90A-1859-B4EE-88D2986D3B02	19
-- 02C6201E-D90A-1859-B4EE-88D2986D3B02	1
-- 02C6201E-D90A-1859-B4EE-88D2986D3B02	71

SELECT product_ids, id FROM transactions 
WHERE ID = "02C6201E-D90A-1859-B4EE-88D2986D3B02";

SELECT * FROM transaction_products 
where transaction_id = "02C6201E-D90A-1859-B4EE-88D2986D3B02";

-- NIVEL 1

-- Ejercicio 1

SELECT name, surname, users.id
from users 
JOIN (SELECT count(id) as numtransactions, user_id
FROM transactions
GROUP BY user_id
having numtransactions > 30) as tabletransactions
ON users.id = tabletransactions.user_id;


-- O bien:

SELECT name, surname
FROM users
WHERE id IN (
    SELECT user_id
    FROM transactions
    GROUP BY user_id
    HAVING COUNT(id) > 30);

-- Ejercicio 2

SELECT round(avg(amount),2), iban, company_name
FROM transactions
JOIN credit_cards
ON transactions.card_id = credit_cards.id
JOIN companies
ON transactions.business_id = companies.company_id
WHERE company_name = "Donec Ltd"
GROUP BY iban;

-- O sólo con dos tablas:

SELECT company_id 
FROM companies
WHERE company_name = "Donec Ltd";

-- Sabemos ahora que el business_id de transactions tiene que ser = b-2242.

SELECT avg(amount), iban, business_id
FROM transactions
JOIN credit_cards
ON transactions.card_id = credit_cards.id
WHERE business_id = "b-2242"
GROUP BY iban;


