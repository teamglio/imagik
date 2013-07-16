require 'sinatra'
require 'aws-sdk'
require 'flickraw'
require 'dotenv'
require 'firebase'
require 'nestful'
require_relative 'lib/imagik.rb'

enable :sessions

configure do
	#Dotenv.load if settings.development?
	Firebase.base_uri = "https://glio-mxit-users.firebaseio.com/#{ENV['MXIT_APP_NAME']}/"
	FlickRaw.api_key = ENV['FLICKR_KEY']
	FlickRaw.shared_secret = ENV['FLICKR_SECRET']
	AWS.config(
	  :access_key_id => ENV['AWS_KEY'],
	  :secret_access_key => ENV['AWS_SECRET']
	)		
end

before do
	@mixup_ad = Nestful.get("http://serve.mixup.hapnic.com/#{ENV['MXIT_APP_NAME']}").body
end

get '/' do
	create_user unless get_user
	erb :search
end

post '/search' do
	session[:search] = params[:search]
	redirect to 'show/1'
end

get '/show/:page' do
	@photos = flickr.photos.search(:tags => session[:search], :license => 4, :content_type => 1, :safe_search => 1, :per_page => 3, :page => params[:page])
	erb :photos
end

get '/about' do
	erb :about
end

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	mxit_user = MxitUser.new(request.env)
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'Imagik feedback',
	  :from => 'mxitappfeedback@glio.co.za',
	  :to => 'mxitappfeedback@glio.co.za',
	  :body_text => params['feedback'] + ' - ' + mxit_user.user_id
	  )
	erb "Thanks! <a href='/'>Back</a>" 
end

helpers do
	def get_user
		mxit_user = MxitUser.new(request.env)
		data = Firebase.get(mxit_user.user_id).response.body
		data == "null" ? nil : data
	end
	def create_user
		mxit_user = MxitUser.new(request.env)
		Firebase.set(mxit_user.user_id, {:date_joined => Time.now})
	end
end

error do
  'Sorry there was a nasty error: ' + env['sinatra.error'].message.to_s
end