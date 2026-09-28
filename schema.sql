-- Northwind schema (as loaded from the CSV exports; see load_data.py)

CREATE TABLE "categories" (
"categoryID" INTEGER,
  "categoryName" TEXT,
  "description" TEXT
);

CREATE TABLE "customers" (
"customerID" TEXT,
  "companyName" TEXT,
  "contactName" TEXT,
  "contactTitle" TEXT,
  "address" TEXT,
  "city" TEXT,
  "region" TEXT,
  "postalCode" TEXT,
  "country" TEXT,
  "phone" TEXT,
  "fax" TEXT
);

CREATE TABLE "employee_territories" (
"employeeID" INTEGER,
  "territoryID" TEXT
);

CREATE TABLE "employees" (
"employeeID" INTEGER,
  "lastName" TEXT,
  "firstName" TEXT,
  "title" TEXT,
  "titleOfCourtesy" TEXT,
  "birthDate" TEXT,
  "hireDate" TEXT,
  "address" TEXT,
  "city" TEXT,
  "region" TEXT,
  "postalCode" TEXT,
  "country" TEXT,
  "reportsTo" REAL
);

CREATE TABLE "order_details" (
"orderID" INTEGER,
  "productID" INTEGER,
  "unitPrice" REAL,
  "quantity" INTEGER,
  "discount" REAL
);

CREATE TABLE "orders" (
"orderID" INTEGER,
  "customerID" TEXT,
  "employeeID" INTEGER,
  "orderDate" TEXT,
  "requiredDate" TEXT,
  "shippedDate" TEXT,
  "shipVia" INTEGER,
  "freight" REAL,
  "shipName" TEXT,
  "shipAddress" TEXT,
  "shipCity" TEXT,
  "shipRegion" TEXT,
  "shipPostalCode" TEXT,
  "shipCountry" TEXT
);

CREATE TABLE "products" (
"productID" INTEGER,
  "productName" TEXT,
  "supplierID" INTEGER,
  "categoryID" INTEGER,
  "quantityPerUnit" TEXT,
  "unitPrice" REAL,
  "unitsInStock" INTEGER,
  "unitsOnOrder" INTEGER,
  "reorderLevel" INTEGER,
  "discontinued" INTEGER
);

CREATE TABLE "shippers" (
"shipperID" INTEGER,
  "companyName" TEXT,
  "phone" TEXT
);

CREATE TABLE "suppliers" (
"supplierID" INTEGER,
  "companyName" TEXT,
  "contactName" TEXT,
  "contactTitle" TEXT,
  "address" TEXT,
  "city" TEXT,
  "region" TEXT,
  "postalCode" TEXT,
  "country" TEXT,
  "phone" TEXT
);

