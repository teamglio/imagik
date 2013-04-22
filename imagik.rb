require 'sinatra'
require 'aws-sdk'
require 'flickraw'
require 'rest-client'
require_relative 'mxit'

enable :sessions


configure do
	AWS.config(
	  :access_key_id => ENV['AWS_KEY'],
	  :secret_access_key => ENV['AWS_SECRET']
	)
	FlickRaw.api_key = ENV['FLICKR_KEY']
	FlickRaw.shared_secret = ENV['FLICKR_SECRET']
end


before do
	@mixup_ad = RestClient.get 'http://serve.mixup.hapnic.com/9502655'
end

get '/' do
	erb :search
end

post '/search' do
	session[:search] = params[:search]
	redirect to 'show/1'
end

get '/show/:page' do
	@photos = flickr.photos.search(:tags => session[:search], :license => 4, :content_type => 1, :safe_search => 2, :per_page => 3, :page => params[:page])
	erb :photos
end

get '/about' do
	erb :about
end

get '/feedback' do
	erb :feedback
end

post '/feedback' do
	ses = AWS::SimpleEmailService.new
	ses.send_email(
	  :subject => 'Imagik feedback',
	  :from => 'emile@silvis.co.za',
	  :to => 'emile@silvis.co.za',
	  :body_text => params['feedback'] + ' - ' + Mxit.new(request.env).user_id
	  )
	erb "Thanks! <a href='/'>Back</a>" 
end

get '/stats' do
	#protected!
	s3 = AWS::S3.new
	bucket = s3.buckets['emilesilvis']
	object = bucket.objects['mxitjobsearch/log.json']
	log = JSON.parse(object.read)

	queries = log.values.each do |record|
		record
	end

	users = queries.collect do |query|
		query["user"]
	end

	erb 'Number of queries: ' + queries.count.to_s + ' <br />Number of users: ' + users.uniq.count.to_s + '<br />Average queries per user: ' + format('%.2f', (queries.count.to_f/users.uniq.count.to_f))

end

error do
  'Sorry there was a nasty error: ' + env['sinatra.error'].message.to_s
end