module H2OConfigurator

  class Handler

    def call(env)
      host_dir = env['HOST_DIR']
      path = env['PATH_INFO']
      redirect_path = host_dir + path.sub(%r{/$}, '') + '.redirect'
      if File.exist?(redirect_path)
        location, status = File.read(redirect_path).split(/\s+/, 2)
        status = status.to_i
        [status, {'location' => location}, []]
      elsif path =~ %r{(/|\.\w+)$}
        [399, {}, []]
      else
        [307, {'x-reproxy-url' => path + '.html'}, []]
      end
    end

  end

end

H2OConfigurator::Handler.new