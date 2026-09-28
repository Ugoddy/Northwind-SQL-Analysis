"""Build northwind.db from the Northwind CSV exports.

Usage: put the CSV files in a folder called data/ next to this script, then run:
    python load_data.py

Cleaning applied:
  - the text 'NULL' becomes a real SQL NULL
  - timestamps like '1996-07-04 00:00:00.000' become plain dates ('1996-07-04')
  - territory IDs and postal codes are kept as text so leading zeros survive
  - bulky/irrelevant columns are dropped (binary photos, free-text notes, fax/home page)
"""
import pandas as pd
import sqlite3

DATA = 'data/'

# ID-like codes (e.g. territory '06897', postal '05021') must stay text, or leading zeros are lost
TEXT_COLS = ['territoryID', 'postalCode', 'shipPostalCode']

def load(name, drop=()):
    df = pd.read_csv(DATA + name, na_values=['NULL'], dtype={c: str for c in TEXT_COLS})
    return df.drop(columns=[c for c in drop if c in df.columns])

tables = {
    'customers': load('customers.csv'),
    'employees': load('employees.csv', drop=['photo', 'notes', 'photoPath', 'homePhone', 'extension']),
    'categories': load('categories.csv', drop=['picture']),
    'suppliers': load('suppliers.csv', drop=['homePage', 'fax']),
    'shippers': load('shippers.csv'),
    'products': load('products.csv'),
    'orders': load('orders.csv'),
    'order_details': load('order-details.csv'),
    'employee_territories': load('employee-territories.csv'),
}

for col in ['orderDate', 'requiredDate', 'shippedDate']:
    tables['orders'][col] = pd.to_datetime(tables['orders'][col]).dt.strftime('%Y-%m-%d')
for col in ['birthDate', 'hireDate']:
    tables['employees'][col] = pd.to_datetime(tables['employees'][col]).dt.strftime('%Y-%m-%d')

conn = sqlite3.connect('northwind.db')
for name, df in tables.items():
    df.to_sql(name, conn, if_exists='replace', index=False)
    print(f'{name}: {len(df)} rows')
conn.close()
