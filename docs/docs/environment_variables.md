---
id: environment-variables
title: Environment Variables
sidebar_label: Environment Variables
slug: /environment-variables
---

Environment variables can be specified via the command line on deploy and made available to your Rails app when it starts. By default, Kuby will automatically copy over any environment variable that begins with `RAILS_`, eg. `RAILS_SERVE_STATIC_FILES`, `RAILS_CACHE_ID`, etc.

## Custom Environment Variables

You can specify additional key/value pairs by adding them in your Kuby config. Since Kuby config is just Ruby, you're free to pull in environment variables, specify static values, etc. All the key/value pairs you specify will show up as environment variables available to your app when it starts.

```ruby
Kuby.define('my-app') do
  environment(:production) do
    plugin(:rails_app) do
      env do
        data do
          add 'MY_ENV_VAR', ENV['MY_ENV_VAR']
          add 'MY_STATIC_ENV_VAR', '123abc'
        end
      end
    end
  end
end
```

Set `MY_ENV_VAR` via the command line when running `kuby deploy` like so:

```bash
MY_ENV_VAR='some value' bundle exec kuby -e production deploy
```
