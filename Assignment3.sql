-- **********************************************
-- Jianbo Zhao(20893089)
-- CS 338 Spring 2024
-- Assignment 3, Questions 1, 2, and 3
-- **********************************************

-- for output
.headers on
.mode column

-- Q1
DROP TABLE IF EXISTS demo;
DROP TABLE IF EXISTS CustomerCustomerDemo;
DROP TABLE IF EXISTS CustomerDemographics;

-- Q2
CREATE TABLE IF NOT EXISTS ArchivedOrders (
    OrderID INTEGER,
    ProductID INTEGER,
    CustomerID TEXT,
    EmployeeID INTEGER,
    OrderDate TEXT,
    RequiredDate TEXT,
    ShippedDate TEXT,
    ShipVia INTEGER,
    Freight REAL DEFAULT 0,
    ShipName TEXT,
    ShipAddress TEXT,
    ShipCity TEXT,
    ShipRegion TEXT,
    ShipPostalCode TEXT,
    ShipCountry TEXT,
    UnitPrice REAL DEFAULT 0 CHECK (UnitPrice >= 0),
    Quantity INTEGER DEFAULT 1 CHECK (Quantity > 0),
    Discount REAL DEFAULT 0 CHECK (Discount BETWEEN 0 AND 1),
    ArchivedDate TEXT DEFAULT (datetime('now')),

    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ShipVia) REFERENCES Shippers(ShipperID)
);

-- Q3
-- Copy the old orders to the new table
INSERT INTO ArchivedOrders (OrderID, ProductID, CustomerID, 
                            EmployeeID, OrderDate, RequiredDate, 
                            ShippedDate, ShipVia, Freight, ShipName, 
                            ShipAddress, ShipCity, ShipRegion, 
                            ShipPostalCode, ShipCountry,
                            UnitPrice, Quantity, Discount)
SELECT DISTINCT o.OrderID, od.ProductID, o.CustomerID, 
       o.EmployeeID, o.OrderDate, o.RequiredDate, 
       o.ShippedDate, o.ShipVia, o.Freight, 
       o.ShipName, o.ShipAddress, o.ShipCity, 
       o.ShipRegion, o.ShipPostalCode, o.ShipCountry, 
       od.UnitPrice, od.Quantity, od.Discount
FROM Orders o
JOIN "Order Details" od ON o.OrderID = od.OrderID
WHERE o.OrderDate < '2016-08-01';

-- Delete the old orders
DELETE FROM "Order Details"
WHERE OrderID IN (SELECT OrderID FROM Orders WHERE OrderDate < '2016-08-01');

DELETE FROM Orders
WHERE OrderDate < '2016-08-01';

-- Output
SELECT COUNT(*) AS OrdersCount FROM Orders;
SELECT COUNT(*) AS OrderDetailsCount FROM "Order Details";
SELECT COUNT(*) AS ArchivedOrdersCount FROM ArchivedOrders;


-- Q4
SELECT COUNT(*) AS NumberOfProducts
FROM Products p
JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE s.CompanyName = 'Ma Maison';

-- Q5
SELECT AVG(ProductCount) AS AvgProductsPerCategory
FROM (
    SELECT COUNT(*) AS ProductCount
    FROM Products
    GROUP BY CategoryID
) AS CategoryProductCounts;

-- Q6
SELECT RegionID, RegionDescription, EmployeeCount
FROM (
    SELECT r.RegionID, r.RegionDescription, 
  			COUNT(e.EmployeeID) AS EmployeeCount
    FROM Regions r
    JOIN Territories t ON r.RegionID = t.RegionID
    JOIN EmployeeTerritories et ON t.TerritoryID = et.TerritoryID
    JOIN Employees e ON et.EmployeeID = e.EmployeeID
    GROUP BY r.RegionID, r.RegionDescription
) AS RegionEmployeeCounts
ORDER BY EmployeeCount DESC
LIMIT 1;

-- Q7
SELECT COUNT(*) AS NumberOfCustomers
FROM (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
    HAVING OrderCount > 10
) AS MoreThan10Orders;

-- Q8
SELECT c.CompanyName, c.City, c.Country
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE s.CompanyName = 'United Package';

-- Q9
SELECT e.EmployeeID, 
		e.ReportsTo AS ManagerID, 
		COUNT(et.TerritoryID) AS ManagerTerritoryCount
FROM Employees e
JOIN Employees m ON e.ReportsTo = m.EmployeeID
JOIN EmployeeTerritories et ON m.EmployeeID = et.EmployeeID
GROUP BY e.EmployeeID, e.ReportsTo;


-- Q10
-- Add the new shipper if it does not already exist
INSERT INTO Shippers (ShipperID, CompanyName, Phone)
SELECT 4, 'Waterloo Shipping', '11111111'
WHERE NOT EXISTS (
    SELECT 1 FROM Shippers WHERE ShipperID = 4
);

-- Calculate Avg for each shipper
SELECT s.CompanyName, 
       COUNT(o.OrderID) AS NumberOfOrders, 
       AVG((od.UnitPrice * od.Quantity - od.Discount)) AS AvgTotalCost
FROM Shippers s
JOIN Orders o ON s.ShipperID = o.ShipVia
JOIN "Order Details" od ON o.OrderID = od.OrderID
GROUP BY s.CompanyName
HAVING COUNT(DISTINCT od.ProductID) > 5;
