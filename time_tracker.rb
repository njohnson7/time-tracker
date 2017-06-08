require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'psych'
require 'bcrypt'
require 'securerandom'
require 'stamp'
require 'awesome_print'

require_relative 'activity.rb'

SAMPLE_ACTIVITIES = [ Activity.new('Launch School', 0),
                      Activity.new('Work', 1),
                      Activity.new('Exercise', 2) ]

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

helpers do
  def current_time_str
    date = Time.now.stamp('Wed. June 8')
    time = Time.now.stamp('10:45 AM')
    "#{date} - <b>#{time}</b>"
  end

  def format_time(time)
    time.stamp('11:23 AM')
  end
end

def next_id
  max = session[:activities].map(&:id).max || -1
  max + 1
end

def status_422_error(msg, template)
  status 422
  session[:msg] = msg
  erb template
end

def find_activity_by_id(id)
  session[:activities].find { |activity| activity.id == id.to_i }
end

def signed_in?
  session[:username]
end

def valid_credentials?
  session[:username] == 'admin'
end

before do
  session[:activities] ||= SAMPLE_ACTIVITIES
end

get '/' do
  redirect '/activities'
end

get '/activities' do
  @activities = session[:activities]
  erb :activities
end

get '/activities/:id' do
  @activities = session[:activities]
  @activity = @activities.find { |activity| activity.id == params[:id].to_i }
  @activity = find_activity_by_id(params[:id])
  erb :activities { erb :activity }
end

get '/new' do
  erb :new
end

post '/new' do
  name = params[:name].to_s.strip
  if name.empty?
    status_422_error('Name cannot be empty', :new)
  elsif session[:activities].map(&:name).include?(name)
    status_422_error('Name already exists', :new)
  else
    session[:activities] << Activity.new(name, next_id)
    session[:msg] = 'Activity added'
    redirect '/'
  end
end

post '/activities/:id/delete' do
  unless valid_credentials?
    session[:msg] = 'You must be signed in to do that'
    redirect "/activities/#{params[:id]}"
  end

  activity = find_activity_by_id(params[:id])
  session[:activities].delete(activity)

  session[:msg] = "'#{activity.name}' has been deleted"
  redirect '/'
end

post '/activities/:id/start' do
  activity = find_activity_by_id(params[:id])
  start_time = params[:start_time]

  activity.start(start_time)
  session[:msg] = "'#{activity.name}' is now running"
  redirect "/activities/#{activity.id}"
end

post '/activities/:id/stop' do
  @activities = session[:activities]
  @activity = find_activity_by_id(params[:id])
  stop_time = params[:stop_time]

  if @activity.start_time > Activity.new_time(stop_time)
    status 422
    session[:msg] = 'Stop time must be after start time'
    erb :activities { erb :activity }
  else
    @activity.stop(stop_time)
    session[:msg] = "'#{@activity.name}' has been stopped"
    redirect "/activities/#{@activity.id}"
  end
end

post '/activities/:id/delete_history_item' do
  unless valid_credentials?
    session[:msg] = 'You must be signed in to do that'
    redirect "/activities/#{params[:id]}"
  end

  activity = find_activity_by_id(params[:id])
  activity.history.delete_if { |item| item.to_s == params[:item] }

  session[:msg] = 'Item has been deleted'
  redirect "/activities/#{params[:id]}"
end

get '/signin' do
  erb :signin
end

post '/signin' do
  username = params[:username].strip
  password = params[:password].strip

  if username.empty?
    status_422_error('Username cannot be empty', :signin)
  elsif password.empty?
    status_422_error('Password cannot be empty', :signin)
  elsif username != 'admin' || password != 'password'
    status_422_error('Invalid credentials', :signin)
  else
    session[:username] = username
    session[:msg] = "Welcome #{username}!"
    redirect '/'
  end
end

post '/signout' do
  session.delete(:username)
  session[:msg] = 'You are now signed out'
  redirect '/'
end
