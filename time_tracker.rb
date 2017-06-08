require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'psych'
require 'bcrypt'
require 'securerandom'
require 'awesome_print'

require_relative 'activity.rb'

SAMPLE_ACTIVITIES = [ Activity.new('Launch School', 0),
                      Activity.new('Work', 1),
                      Activity.new('Exercise', 2) ]

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
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
  activity = find_activity_by_id(params[:id])
  session[:activities].delete(activity)

  session[:msg] = "'#{activity.name}' has been deleted"
  redirect '/'
end
