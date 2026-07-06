Simulacro RiwiSupply — Soluciones

Nota: los SQL usan el esquema en inglés de la Sección 6 (canónico). Donde el enunciado y el esquema difieren, se indica.

Sección 1 · Conceptos fundamentales
1. B
La PK identifica unívocamente cada fila; no admite NULL ni duplicados.
2. C
NOT NULL.
3. C
FOREIGN KEY (referencia a riwi_suppliers(id)).
4. B
Solo una PK por tabla y no admite NULL. Ojo: la redacción 'un solo NULL' de UNIQUE es imprecisa; PostgreSQL permite varios NULL en columna UNIQUE.
5. C
Elimina en cascada los registros hijos.

Sección 2 · Normalización
6. C
1FN: valores atómicos, sin grupos repetitivos.
7. A
Se viola 1FN por valores no estandarizados. Matiz: estrictamente es calidad de datos + entidad mezclada; defender estandarización si preguntan.
8. C
3FN (dependencia transitiva id_registro → id_proveedor → ciudad). Se crea riwi_suppliers con ciudad.
10. B
riwi_purchases(id, fecha, supplier_id→, product_id→, unit_price, quantity).

Pregunta 9 — Normalización aplicada
(a) 1FN: valores no atómicos/no estandarizados; una sola tabla mezcla varias entidades.
(b) 2FN: nombre_proveedor, ciudad_proveedor dependen de id_proveedor; nombre_producto, categoria, precio, unidad dependen de id_producto (dependencias parciales).
(c) 3FN: id_reg → id_proveedor → ciudad_proveedor; id_reg → id_producto → categoria (transitivas).
(d) Esquema final:
riwi_cities(id_city, name, department)
riwi_categories(id_category, name)
riwi_suppliers(id_supplier, name, nit, city_id→riwi_cities)
riwi_products(id_product, name, unit_of_measure, unit_price, category_id→riwi_categories)
riwi_purchases(id_purchase, purchase_date, supplier_id→riwi_suppliers)
riwi_purchase_details(id, purchase_id→riwi_purchases, product_id→riwi_products, quantity)
Nota: el precio del pago va en el detalle (el mismo producto cambia de precio entre compras). El precio de catálogo iría en riwi_products.


Sección 3 · Modelo Entidad-Relación
11. B
1:N (un proveedor, muchas compras).
12. C
N:M con tabla intermedia riwi_purchase_details.
13. B
Entidad riwi_inventory_movements.
14. B
Bodega ↔ responsable único = 1:1.

Pregunta 15 — MER
riwi_cities(PK id) ──1:N── riwi_suppliers(PK id, FK city_id)
riwi_categories(PK id) ──1:N── riwi_products(PK id, FK category_id)
riwi_suppliers ──1:N── riwi_purchases(PK id, FK supplier_id)
riwi_purchases ──N:M── riwi_products  [riwi_purchase_details(FK purchase_id, FK product_id)]
riwi_products ──1:N── riwi_inventory_movements(PK id, FK product_id, FK warehouse_id)
riwi_warehouses(PK id) ──1:N── riwi_inventory_movements


Sección 4 · DDL
16. B
ALTER TABLE ... ADD COLUMN.
17. B
city_id es FK a riwi_cities.

Pregunta 18 — CREATE TABLE
CREATE TABLE riwi_categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);
 
CREATE TABLE riwi_products (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    unit_of_measure VARCHAR(30) NOT NULL,
    category_id     INT NOT NULL REFERENCES riwi_categories(id),
    stock           INT DEFAULT 0
);
 
CREATE TABLE riwi_warehouses (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL UNIQUE,
    city         VARCHAR(100) NOT NULL,
    address      TEXT,
    manager_name VARCHAR(100) NOT NULL
);

Pregunta 19 — ALTER / DROP
ALTER TABLE riwi_suppliers ADD COLUMN email VARCHAR(120) UNIQUE;
ALTER TABLE riwi_warehouses ALTER COLUMN address TYPE TEXT;
DROP TABLE IF EXISTS riwi_temp_data;
20. A
Tabla intermedia con PK compuesta (purchase_id, product_id) y ambas FK.

  
Sección 5 · DML
21. B
Error unique_violation.
Pregunta 22 — INSERT
INSERT INTO riwi_suppliers (name, nit, city_id, email)
VALUES ('TecnoPartes Ltda', '700345678-5', 3, 'tecnopartes@empresa.com');
 
INSERT INTO riwi_products (name, unit_price, unit_of_measure, category_id, stock)
VALUES ('Tornillo hexagonal 1/2 pulgada', 1200.00, 'UNIDAD', 1, 100);
 
INSERT INTO riwi_purchases (purchase_date, supplier_id)
VALUES (CURRENT_DATE, (SELECT id FROM riwi_suppliers WHERE nit = '700345678-5'));
 
INSERT INTO riwi_purchase_details (purchase_id, product_id, quantity, unit_price)
VALUES (
    (SELECT MAX(id) FROM riwi_purchases),
    (SELECT id FROM riwi_products WHERE name = 'Tornillo hexagonal 1/2 pulgada'),
    50, 1200.00
);
Pregunta 23 — UPDATE / DELETE
UPDATE riwi_suppliers
SET email = 'nuevo_email@distribuidora.com',
    name  = 'Distribuidora Electrónica Medellín'
WHERE id = 2;
 
UPDATE riwi_products
SET stock = stock - 10
WHERE id = 3 AND stock >= 10;
 
DELETE FROM riwi_inventory_movements
WHERE movement_type = 'EGRESO' AND movement_date < '2023-01-01';
 
DELETE FROM riwi_suppliers s
WHERE s.id = 99
  AND NOT EXISTS (SELECT 1 FROM riwi_purchases p WHERE p.supplier_id = s.id);


Sección 6 · Consultas SQL
24. B
LEFT JOIN trae todo lo izquierdo + coincidencias; INNER solo coincidencias.
P25 — Stock por producto
SELECT p.name AS producto, c.name AS categoria, p.unit_of_measure, p.stock
FROM riwi_products p
JOIN riwi_categories c ON c.id = p.category_id
ORDER BY p.stock ASC;
P26 — Movimientos por bodega
SELECT w.name AS bodega, m.movement_type, COUNT(*) AS total_movimientos
FROM riwi_inv_movs m
JOIN riwi_warehouses w ON w.id = m.warehouse_id
GROUP BY w.name, m.movement_type
HAVING COUNT(*) > 5
ORDER BY total_movimientos DESC;
P27 — Total comprado por proveedor
SELECT s.name AS proveedor, ci.name AS ciudad,
       COUNT(DISTINCT pu.id) AS num_compras,
       COALESCE(SUM(pd.quantity * pd.unit_price), 0) AS valor_total
FROM riwi_suppliers s
LEFT JOIN riwi_cities ci       ON ci.id = s.city_id
LEFT JOIN riwi_purchases pu    ON pu.supplier_id = s.id
LEFT JOIN riwi_purch_detail pd ON pd.purchase_id = pu.id
GROUP BY s.name, ci.name
ORDER BY valor_total DESC;
P28 — Producto más comprado
SELECT p.name, SUM(pd.quantity) AS total_unidades
FROM riwi_purch_detail pd
JOIN riwi_products p ON p.id = pd.product_id
GROUP BY p.name
ORDER BY total_unidades DESC
FETCH FIRST 1 ROW ONLY;
P29 — Valor de inventario por bodega
SELECT w.name AS bodega, w.city AS ciudad,
       SUM(m.quantity * p.unit_price) AS valor_inventario
FROM riwi_inv_movs m
JOIN riwi_warehouses w ON w.id = m.warehouse_id
JOIN riwi_products p   ON p.id = m.product_id
GROUP BY w.name, w.city
HAVING SUM(m.quantity * p.unit_price) > 500000
ORDER BY valor_inventario DESC;
Advertencia: sumar quantity sin distinguir ENTRADA/SALIDA no es stock real. Correcto: SUM(CASE WHEN movement_type='ENTRADA' THEN quantity ELSE -quantity END).
P30 — Proveedores por encima del promedio
SELECT s.name, SUM(pd.quantity * pd.unit_price) AS total_comprado
FROM riwi_suppliers s
JOIN riwi_purchases pu     ON pu.supplier_id = s.id
JOIN riwi_purch_detail pd  ON pd.purchase_id = pu.id
GROUP BY s.id, s.name
HAVING SUM(pd.quantity * pd.unit_price) > (
    SELECT AVG(total) FROM (
        SELECT SUM(pd2.quantity * pd2.unit_price) AS total
        FROM riwi_purchases pu2
        JOIN riwi_purch_detail pd2 ON pd2.purchase_id = pu2.id
        GROUP BY pu2.supplier_id
    ) sub
);
31. B
LEFT JOIN ... WHERE m.id IS NULL. (C con NOT IN falla si hay NULL.)
P32 — Categorías con precio promedio > 10.000
SELECT c.name AS categoria, COUNT(p.id) AS num_productos,
       AVG(p.unit_price) AS precio_promedio
FROM riwi_categories c
JOIN riwi_products p ON p.category_id = c.id
GROUP BY c.name
HAVING AVG(p.unit_price) > 10000
ORDER BY precio_promedio DESC;
33. B
HAVING.

  
Sección 7 · Vistas y transacciones
34. B
Vista = consulta almacenada, tabla virtual.
P35 — Vista
CREATE VIEW vw_riwi_stock_by_product AS
SELECT p.name AS producto, c.name AS categoria,
       p.unit_of_measure, p.stock
FROM riwi_products p
JOIN riwi_categories c ON c.id = p.category_id;
P36 — Transacción
BEGIN;
 
SAVEPOINT sp_antes_proveedor;
INSERT INTO riwi_suppliers (name, nit)
VALUES ('Metales del Pacífico Ltda', '950111222-3');
 
SAVEPOINT sp_antes_producto;
INSERT INTO riwi_products (name, unit_price, unit_of_measure, category_id)
VALUES ('Lámina de acero', 45000, 'und', 1);
-- Si el producto ya existiera (unique_violation):
-- ROLLBACK TO SAVEPOINT sp_antes_producto;
 
COMMIT;
37. B
ROLLBACK deshace toda la transacción; ROLLBACK TO SAVEPOINT solo hasta el punto de guarda, manteniendo la transacción activa.

  
Sección 8 · Detección de errores
38. B
Sin PK y con atributos de otras entidades (viola normalización).
39. C
Bodega↔movimientos como 1:1 es incorrecto; debe ser 1:N.
Pregunta 40 — Script con errores
Errores: 1) id INT sin PK → SERIAL PRIMARY KEY. 2) FOREING KEY → FOREIGN KEY. 3) riwi_product → riwi_products. 4) el INSERT lista columnas dentro de VALUES; sintaxis correcta INSERT INTO t (cols) VALUES (...). 5) HAVING movement_type inválido (no agregada ni en GROUP BY) → eliminar. 6) ORDER → ORDER BY, y ordenar por SUM(quantity) o product_id.
Versión corregida:
CREATE TABLE riwi_inventory_movements (
    id            SERIAL PRIMARY KEY,
    movement_date DATE NOT NULL,
    movement_type VARCHAR(10),
    quantity      INT,
    product_id    INT,
    warehouse_id  INT,
    FOREIGN KEY (product_id)   REFERENCES riwi_products(id),
    FOREIGN KEY (warehouse_id) REFERENCES riwi_warehouses(id)
);
 
INSERT INTO riwi_inventory_movements
    (movement_date, movement_type, quantity, product_id, warehouse_id)
VALUES ('2024-01-15', 'ENTRADA', 50, 1, 2);
 
SELECT product_id, SUM(quantity)
FROM riwi_inventory_movements
WHERE movement_type = 'ENTRADA'
GROUP BY product_id
ORDER BY SUM(quantity) DESC;
