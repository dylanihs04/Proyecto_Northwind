--VENTAS
--1. Cuantas ordenes se realizaron y cuanto se facturo en total
SELECT
	COUNT(DISTINCT O.OrderID) AS TOTAL_ORDENES,
	SUM((UnitPrice * Quantity) * (1 - Discount)) AS INGRESO_TOTAL
FROM Orders O
JOIN [Order Details] OD
	ON O.OrderID = OD.OrderID


--2. Cual es la facturacion total por año
SELECT
	YEAR(OrderDate) AS AÑO,
	SUM((UnitPrice * Quantity) * (1 - Discount)) AS FACTURACION
FROM Orders O
JOIN [Order Details] OD
	ON O.OrderID = OD.OrderID
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate)


--3. Cual es la facturacion mensual por año
SELECT 
	YEAR(OrderDate) AS AÑO, 
	MONTH(OrderDate) AS MES, 
	SUM((UnitPrice * Quantity) * (1 - Discount)) AS FACTURACION 
FROM Orders O
JOIN [Order Details] OD 
	ON O.OrderID = OD.OrderID
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY AÑO, MES


--4. Cual es el valor promedio de una orden
WITH order_total AS (
	SELECT 
		O.OrderID, 
		SUM((UnitPrice * Quantity) * (1 - Discount)) AS valor 
	FROM Orders O
	JOIN [Order Details] OD
		ON O.OrderID = OD.OrderID 
	GROUP BY O.OrderID)

SELECT AVG(valor) as PROMEDIO FROM order_total


--5. Que porcentaje de ordenes tiene descuento
SELECT 
    CAST(COUNT(DISTINCT CASE WHEN OD.Discount > 0 THEN O.OrderID END) * 100.0
        / COUNT(DISTINCT O.OrderID) AS DECIMAL(5,2)) AS PORCENTAJE
FROM Orders O
JOIN [Order Details] OD
    ON O.OrderID = OD.OrderID;




--6. Cuales son las 10 ordenes con mayor valor (mas dinero facturado)
SELECT TOP 10
	O.OrderID, 
	SUM(UnitPrice*Quantity*(1-Discount)) AS VALOR 
FROM Orders O
JOIN [Order Details] OD
	ON O.OrderID = OD.OrderID
GROUP BY O.OrderID
ORDER BY VALOR DESC


--Clientes
--7. Cuantos clientes hay por pais
SELECT 
	COUNT(CustomerID) AS CANTIDAD_CLIENTES, 
	Country 
FROM Customers
GROUP BY Country
ORDER BY CANTIDAD_CLIENTES DESC


--8. Cuales son los 10 clientes que mas ingresos generan (dinero que la empresa recibe de esos clientes)
SELECT TOP 10
	C.CompanyName, 
	SUM(UnitPrice*Quantity*(1-Discount)) AS INGRESOS 
FROM Customers C
JOIN Orders O 
	ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD 
	ON O.OrderID = OD.OrderID
GROUP BY C.CompanyName
ORDER BY INGRESOS DESC


--9. Cual es el ingreso promedio generado por cliente
WITH INGRESOS_GENERADOS AS (
	SELECT 
		C.CompanyName, 
		SUM(UnitPrice*Quantity*(1-Discount)) AS INGRESOS 
	FROM Customers C
	JOIN Orders O 
		ON C.CustomerID = O.CustomerID
	JOIN [Order Details] OD 
		ON O.OrderID = OD.OrderID
	GROUP BY C.CompanyName)

SELECT AVG(INGRESOS) as PROMEDIO_INGRESOS FROM INGRESOS_GENERADOS

--10. Que clientes han realizado mas de 10 ordenes
SELECT 
	C.CompanyName, 
	COUNT(*) AS CANTIDAD_ORDENES 
FROM Customers C
JOIN Orders O 
	ON C.CustomerID = O.CustomerID
GROUP BY C.CompanyName
HAVING COUNT(*) > 10
ORDER BY CANTIDAD_ORDENES


--11. Clientes que han comprado productos de mas de 5 categorias distintas
SELECT
	C.CompanyName,
	COUNT(DISTINCT P.CategoryID) AS CANT_CATEGORIAS
FROM Customers C
JOIN Orders O
	ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD
	ON O.OrderID = OD.OrderID
JOIN Products P
	ON OD.ProductID = P.ProductID
GROUP BY C.CompanyName
HAVING COUNT(DISTINCT P.CategoryID) > 5


--12. Clientes que generan pedidos cuyo valor maximo supera los 10000
WITH VALOR_GENERADO AS (
	SELECT
		O.OrderID,
		C.CompanyName,
		SUM(UnitPrice * Quantity * (1 - Discount)) AS VALOR_GENERADO
	FROM Customers C
	JOIN Orders O
		ON C.CustomerID = O.CustomerID
	JOIN [Order Details] OD
		ON O.OrderID = OD.OrderID
	GROUP BY O.OrderID, C.CompanyName)

SELECT 
	CompanyName, 
	MAX(VALOR_GENERADO) AS VALOR_MAXIMO
FROM VALOR_GENERADO VP
GROUP BY CompanyName
HAVING MAX(VALOR_GENERADO) > 10000


--Productos
--13. Cuales categorias generan mas ingresos (evaluar desempeño por linea de producto)
SELECT 
	C.CategoryName, 
	SUM(OD.UnitPrice * OD.Quantity * (1 - Discount)) AS INGRESOS
FROM Categories C
JOIN Products P
	ON C.CategoryID = P.CategoryID
JOIN [Order Details] OD
	ON P.ProductID = OD.ProductID
GROUP BY C.CategoryName
ORDER BY INGRESOS


--14. Que categorias tiene mas de 10 productos activos
SELECT
	C.CategoryName,
	COUNT(ProductID)
FROM Categories C
JOIN Products P
	ON C.CategoryID = P.CategoryID
where P.Discontinued = 0
GROUP BY C.CategoryName
HAVING COUNT(ProductID) > 10


--15. Cuáles son los 10 productos más vendidos por ingresos
SELECT TOP 10
	P.ProductName, 
	SUM(OD.UnitPrice * OD.Quantity * (1 - Discount)) AS INGRESOS 
FROM Products P
JOIN [Order Details] OD 
	ON P.ProductID = OD.ProductID
GROUP BY P.ProductName
ORDER BY INGRESOS DESC


--16. Cual es el precio promedio por categoria
SELECT 
	C.CategoryName, 
	AVG(P.UnitPrice) AS PRECIO_PROMEDIO 
FROM Categories C
JOIN Products P 
	ON C.CategoryID = P.CategoryID
GROUP BY C.CategoryName;


--17. Que productos tienen un precio mayor al promedio de su categoria
SELECT
	C.CategoryName,
	P.ProductName,
	P.UnitPrice
FROM Products P
JOIN Categories C
	ON P.CategoryID = C.CategoryID
WHERE P.UnitPrice > (
	SELECT AVG(UnitPrice)
	FROM Products
	WHERE CategoryID = p.CategoryID
)


--Empleados
--18. Que empleados gestionan pedidos cuyo monto promedio sea superior al promedio general
WITH PROMEDIO_GENERAL AS (
	SELECT 
		O.OrderID,
		O.EmployeeID,
		SUM(UnitPrice * Quantity * (1 - Discount)) AS MONTO
	FROM Orders O
	JOIN [Order Details] OD 
		ON O.OrderID = OD.OrderID
	GROUP BY O.OrderID,O.EmployeeID)

SELECT 
	CONCAT(FirstName,' ',LastName) as Nombre, 
	AVG(MONTO) AS MONTO_PROMEDIO
FROM PROMEDIO_GENERAL PG
JOIN Employees E 
	ON PG.EmployeeID = E.EmployeeID
GROUP BY CONCAT(FirstName,' ',LastName)
HAVING AVG(MONTO) > (SELECT AVG(MONTO) FROM PROMEDIO_GENERAL)
ORDER BY MONTO_PROMEDIO DESC


