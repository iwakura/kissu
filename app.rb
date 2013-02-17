class Seppun < Sinatra::Base
  register Sinatra::Flash

  get '/' do
    erb :form
  end

  post '/export' do
    if params[:email] && params[:password] && !params[:email].empty? && !params[:password].empty?
      begin
        agent = Kisses.new
        agent.login params[:email], params[:password]
        agent.save_own_id
        agent.save_packs %w[inbox]
        arch = agent.dump_threads_to_temp_archive
        send_file arch.path, :type => 'application/zip', :disposition => 'attachment', :filename => 'my_chats.zip'
      rescue => e
      end
    end
    redirect '/'
  end


  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def csrf_tag
      Rack::Csrf.tag(env)
    end
    def csrf_token
      Rack::Csrf.token(env)
    end
  end
end
