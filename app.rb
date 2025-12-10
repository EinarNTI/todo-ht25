require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'

# Redirect from '/' to '/todos'
get '/' do
    redirect '/todos'  
end

# Index page
get '/todos' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    @categories = {}
    @tasksUndone = db.execute("SELECT * FROM todos WHERE done = false")
    @tasksDone = db.execute("SELECT * FROM todos WHERE done = true")

    @tasksUndone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    p @tasksUndone
    p " "
    p @categories

    @tasksDone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    slim :index
end

# Handles sorting by category
get '/todos/:category' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    @category = params[:category]

    @categories = {}
    @tasksUndone = db.execute("SELECT * FROM todos WHERE done = false")
    @tasksDone = db.execute("SELECT * FROM todos WHERE done = true")

    @tasksUndone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    whereContains = []
    i = 0

    @categories.each do |item|
        if item[1].include?(@category)
            whereContains << i
        end
        i += 1
    end
    @sortedUndone = []
    

    @tasksDone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    slim :index
end

# Adds a task
post '/todos/new' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    name = params[:name]
    description = params[:description]
    category = (params[:category])
    category.map! {|item| item.to_i}

    db.execute("INSERT INTO todos (name, description, done) VALUES (?,?,?)",[name,description,0])

    idInserted = db.execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]

    category.each do |item|
        db.execute("INSERT INTO todos_categories_rel (todos_id, categories_id) VALUES (?,?)", [idInserted, item])
    end

    redirect('/todos')
end

# Toggles doneness
post '/todos/:id/toggle' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    id = params[:id].to_i

    current = db.get_first_value("SELECT done FROM todos WHERE id = ?", id).to_i
    new_state = current == 1 ? 0 : 1

    db.execute("UPDATE todos SET done = ? WHERE id = ?", [new_state, id])

    redirect('/todos')
end

# Deletes a task
post '/todos/:id/delete' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    id = params[:id].to_i
    db.execute("DELETE FROM todos WHERE id = ?", id)
    redirect('/todos')
end

# Opens edit page
get '/todos/:id/edit' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = false

    @id = params[:id].to_i

    @name = db.execute("SELECT name FROM todos WHERE id = ?", @id)[0][0]
    @description = db.execute("SELECT description FROM todos WHERE id = ?", @id)[0][0]

    slim :edit
end

# Submits the edit
post '/todos/:id/edit' do
    id = params[:id]
    name = params[:name]
    description = params[:description]

    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    db.execute("UPDATE todos SET name = ?, description = ? WHERE id = ?", [name, description, id])

    redirect '/todos'
end