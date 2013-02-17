require 'mechanize'
require 'json'
require 'zip/zip'

class Kisses
  LOGIN_URL = 'http://www.12kisses.com/sign-in'
  RENEW_DELAY = 60
  MESSAGES_PER_PAGE = 10
  # available packs (folders): inbox bl sent trash

  attr_accessor :verbose

  def initialize(&block)
    make_agent
    if block_given?
      if block.arity == 1
        yield self
      else
        instance_eval &block
      end
    end
  end

  def make_agent
    @agent = Mechanize.new do |a|
      a.user_agent_alias = 'Windows IE 8'
      a.max_history = 1
    end
  end

  def login(email, password)
    @agent.get(LOGIN_URL)
    form = @agent.page.form_with(:name => 'loginform')
    form.email = email
    form.pass = password
    form.checkbox_with(:name => 'remember').check
    form.submit
  end

  def stay_online_till(end_time)
    @stay_till = end_time
    stay_online
  end

  def status_link(other_id = 0)
    "/mail-folders?ajax=1&get=folders&id=#{@my_id}&id2=0&_=#{timestamp}"
  end

  def list_threads_link(pack = 'inbox', page = 1)
    "/mail-users?ajax=1&get=users&folder=#{pack}&id=#@my_id&p=#{page}&_=#{timestamp}"
  end

  def thread_link(other_user_id, page = 1, pack = 'inbox')
    "/mail-msgs?ajax=1&get=msgs&folder=#{pack}&p=#{page}&id=#@my_id&id2=#{other_user_id}&_=#{timestamp}"
  end


  def timestamp
    "#{Time.now.to_i}#{'%03d' % rand(999)}"
  end

  def stay_online
    begin
      @agent.get status_link
      puts @agent.page.body
      sleep RENEW_DELAY
    end until Time.now > @stay_till
  end

  def save_own_id
    @agent.get('/')
    @my_id = @agent.page.link_with(:href => %r{/my}).node[:href].match(/id=(\d+)/)[1]
  end

  def print_counter
    puts @agent.page.at('#menu_mail_check_count').text rescue nil
  end

  def dump_threads
    @threads.each do |thread, messages|
      export_thread_to_file(thread, messages)
    end
  end

  def dump_threads_to_archive
    return if @threads.empty?
    archive_path = File.join('/tmp/', archive_name)
    puts "Dumping to #{archive_path}" if verbose
    dump_threads_to_zip archive_path
  end

  def dump_threads_to_temp_archive
    return if @threads.empty?
    tempfile = Tempfile.new archive_name
    dump_threads_to_zip tempfile.path
    tempfile.rewind
    tempfile
  end

  def dump_threads_to_zip(archive_path)
    Zip::ZipOutputStream.open(archive_path) do |arc|
      @threads.each do |thread, messages|
        tempfile = dump_thread_to_tempfile(thread, messages)
        arc.put_next_entry thread_filename(thread)
        arc.print tempfile.read
      end
    end
  end

  def save_packs(packs)
    @threads = []
    packs.each do |pack|
      save_thread_pack pack
    end
  end

  def save_thread_pack(name)
    exported = 0
    total = 1
    page = 1
    while exported < total do
      @agent.get(list_threads_link(name, page))
      threads = JSON.parse @agent.page.body.strip
      save_threads threads
      exported += threads['usrs'].count
      page += 1
      total = threads['total'].to_i
    end
  end

  def save_threads(threads)
    @users = { @my_id.to_i => 'me' }
    threads['usrs'].each do |thread|
      save_thread thread
    end
  end

  def save_name(thread)
    other_name = thread['uname']
    @users[thread['usr'].to_i] = other_name.empty? ? 'Other' : other_name
  end

  def save_thread(thread)
    save_name thread
    messages = []
    (thread['all'].to_f / MESSAGES_PER_PAGE).ceil.times do |page|
      @agent.get thread_link(thread['usr'], page + 1)
      thread_part = JSON.parse @agent.page.body.strip
      messages.concat thread_part['msgs']
    end
    @threads << [thread, messages]
  end

  def export_thread_to_file(thread, messages)
    filename = "/tmp/#{thread_filename thread}"
    puts "Dumping to #{filename}" if verbose
    File.open(filename, 'w') do |fd|
      fd.puts thread_text(messages)
    end
  end

  def dump_thread_to_tempfile(thread, messages)
    file = Tempfile.new(thread_filename(thread))
    file.puts thread_text(messages)
    file.rewind
    file
  end

  def thread_filename(thread)
    "thread_#{@my_id}_with_#{thread['usr']}.txt"
  end

  def archive_name
    "threads_by_#{@my_id}_#{Time.now.to_i}.zip"
  end


  def thread_text(messages)
    content = ''
    nick_length = @users.collect {|uid, nick| nick.length }.max
    messages.sort_by { |msg| msg['mail_id'].to_i }.each do |msg|
      content += sprintf("[%27s] %#{nick_length+1}s \n", msg['msg_sent'].sub('&nbsp;', ' '), @users[msg['msg_from'].to_i])
      content += "\t#{msg['msg_text']}\n\n"
    end
    content
  end
end
