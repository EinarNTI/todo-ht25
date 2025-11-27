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

    slim(:index)
end

# Adds a task
post '/new' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    query1 = params[:name]
    query2 = params[:description]

    db.execute("INSERT INTO todos (name, description, done) VALUES (?,?,?)",[query1,query2,0])
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