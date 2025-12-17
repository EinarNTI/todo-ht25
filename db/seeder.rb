require 'sqlite3'

db = SQLite3::Database.new("todos.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS todos')
  db.execute('DROP TABLE IF EXISTS categories')
  db.execute('DROP TABLE IF EXISTS todos_categories_rel')
  db.execute('DROP TABLE IF EXISTS users')
end

def create_tables(db)
  db.execute('CREATE TABLE todos (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, done BOOL, owner TEXT)')
  db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name INTEGER)')
  db.execute('CREATE TABLE todos_categories_rel (todos_id INTEGER, categories_id INTEGER)')
  db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)')
end

def populate_tables(db)
  db.execute('INSERT INTO todos (name, description, done, owner) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko", false, "admin")')
  db.execute('INSERT INTO todos (name, description, done, owner) VALUES ("Köp julgran", "En rödgran", false, "admin")')
  db.execute('INSERT INTO todos (name, description, done, owner) VALUES ("Pynta gran", "Glöm inte lamporna i granen och tomten", false, "admin")')
  db.execute('INSERT INTO categories (id, name) VALUES (1, "Private")')
  db.execute('INSERT INTO categories (id, name) VALUES (2, "Public")')
  db.execute('INSERT INTO categories (id, name) VALUES (3, "Other")')
  db.execute('INSERT INTO users (username, password) VALUES ("admin", "password")')
  db.execute('INSERT INTO todos_categories_rel (todos_id, categories_id) VALUES (1, 1)')
  db.execute('INSERT INTO todos_categories_rel (todos_id, categories_id) VALUES (2, 2)')
  db.execute('INSERT INTO todos_categories_rel (todos_id, categories_id) VALUES (3, 3)')
end

seed!(db)