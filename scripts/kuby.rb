Kuby.define('Kubyapp') do
  environment(:production) do
    docker do
      insert(:vendor, before: :bundler_phase) do |dockerfile|
        dockerfile.copy('vendor', 'vendor')
      end

      image_url 'localhost:5000/kubyapp'
    end

    kubernetes do
      add_plugin :rails_app do
        tls_enabled false
      end

      provider :docker_desktop
    end
  end
end
