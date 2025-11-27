require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'

# Index page
get '/' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    @tasksUndone = db.execute("SELECT * FROM todos WHERE done = false")
    @tasksDone = db.execute("SELECT * FROM todos WHERE done = true")

    slim :index
end

# Adds a task
post '/new' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    name = params[:name]
    description = params[:description]
    private = params[:private]

    db.execute("INSERT INTO todos (name, description, private, done) VALUES (?,?,?,?)",[name,description,private,0])
    redirect('/')
end

# Toggles doneness
post '/:id/toggle' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    id = params[:id].to_i

    current = db.get_first_value("SELECT done FROM todos WHERE id = ?", id).to_i
    new_state = current == 1 ? 0 : 1

    db.execute("UPDATE todos SET done = ? WHERE id = ?", [new_state, id])

    redirect('/')
end

# Deletes a task
post '/:id/delete' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    id = params[:id].to_i
    db.execute("DELETE FROM todos WHERE id = ?", id)
    redirect('/')
end

# Opens edit page

get '/:id/edit' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = false

    @id = params[:id].to_i

    @name = db.execute("SELECT name FROM todos WHERE id = ?", @id)[0][0]
    @description = db.execute("SELECT description FROM todos WHERE id = ?", @id)[0][0]

    slim :update
end

# Submits the edit

post '/:id/edit' do
    id = params[:id]
    name = params[:name]
    description = params[:description]

    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    db.execute("UPDATE todos SET name = ?, description = ? WHERE id = ?", [name, description, id])

    redirect '/'
end