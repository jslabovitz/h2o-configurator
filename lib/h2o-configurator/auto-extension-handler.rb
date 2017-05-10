module H2OConfigurator

  class AutoExtensionHandler

    def call(env)
      if env['PATH_INFO'] =~ %r{(/|\.\w+)$}
        [399, {}, []]
      else
        [307, {'x-reproxy-url' => env['PATH_INFO'] + '.html'}, []]
      end
    end

  end

end