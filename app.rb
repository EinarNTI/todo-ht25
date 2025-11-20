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

    db.execute("INSERT INTO todos (name, description) VALUES (?,?)",[query1,query2])
    redirect('/')
end

# Toggles doneness
post '/:id/toggle' do
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    id = params[:id]

    state = db.execute("SELECT done FROM todos WHERE id = ?", id)
    state = !state
    
    db.execute("UPDATE todos SET done = ? WHERE id = ?", [state, id])

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