require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'
require 'sinatra/flash'
# ^gem install sinatra-flash

enable :sessions

# Redirect from '/' to '/todos'
get '/' do
    slim :login
end

post '/login' do
    usr = params[:username]
    pwd = params[:password]
    
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    result = db.execute("SELECT * FROM users")

    result.each do |row|
        if row["password"] == pwd and row["username"] == usr
            @login = true
        end
    end

    if @login
        session[:user] = usr
        redirect '/todos'
    else
        redirect '/'
    end
end

# Index page
get '/todos' do
    #Uses sinatra-flash to show an alert message
    if session[:user].nil?
        flash[:notice] = "You must be logged in to add a task."
        redirect '/'
    end

    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    @categories = {}
    @tasksUndone = db.execute("SELECT * FROM todos WHERE done = false AND owner = ?", session[:user])
    @tasksDone = db.execute("SELECT * FROM todos WHERE done = true AND owner = ?", session[:user])

    @tasksUndone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    @tasksDone.each do |item|
        @categories[item["id"]] = db.execute("SELECT name FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map {|row| row["name"]}.join(", ")
    end

    @categoryNames = {
    1 => db.execute("SELECT name FROM categories WHERE id = 1")[0]["name"],
    2 => db.execute("SELECT name FROM categories WHERE id = 2")[0]["name"],
    3 => db.execute("SELECT name FROM categories WHERE id = 3")[0]["name"]
    }

    slim :index
end

# Handles sorting by category
get '/todos/:category' do
    if session[:user].nil?
        flash[:notice] = "You must be logged in to add a task."
        redirect '/'
    end

    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    @category = params[:category].to_i

    @categories = {}
    @tasksUndoneTemp = db.execute("SELECT * FROM todos WHERE done = false AND owner = ?", session[:user])
    @tasksDoneTemp = db.execute("SELECT * FROM todos WHERE done = true AND owner = ?", session[:user])
 
    @tasksUndoneTemp.each do |item|
        @categories[item["id"]] = db.execute("SELECT categories.id FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map { |row| row["id"] }
    end

    @tasksDoneTemp.each do |item|
        @categories[item["id"]] = db.execute("SELECT categories.id FROM categories INNER JOIN todos_categories_rel ON categories.id = todos_categories_rel.categories_id WHERE todos_categories_rel.todos_id = ?", item["id"]).map { |row| row["id"] }
    end

    @tasksUndone = @tasksUndoneTemp.dup
    @tasksDone = @tasksDoneTemp.dup

    i = 0
    while i < @tasksUndone.length
        if !@categories[@tasksUndone[i]["id"]].include?(@category)
            @tasksUndone.delete_at(i)
            i -= 1
        end  
        i += 1
    end

    i = 0
    while i < @tasksDone.length
        if !@categories[@tasksDone[i]["id"]].include?(@category)
            @tasksDone.delete_at(i)
            i -= 1
        end  
        i += 1
    end

    @categoryNames = {
    1 => db.execute("SELECT name FROM categories WHERE id = 1")[0]["name"],
    2 => db.execute("SELECT name FROM categories WHERE id = 2")[0]["name"],
    3 => db.execute("SELECT name FROM categories WHERE id = 3")[0]["name"]
    }

    slim :index
end

# Adds a task
post '/todos/new' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    name = params[:name]
    description = params[:description]
    category = (params[:category])

    db.execute("INSERT INTO todos (name, description, done, owner) VALUES (?,?,?,?)",[name,description, 0, session[:user]])

    idInserted = db.execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]

    if category.nil?
        category = [3]
    end

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

    current = db.execute("SELECT done FROM todos WHERE id = ?", id)[0]["done"].to_i
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