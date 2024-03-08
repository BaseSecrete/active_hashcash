# ActiveHashcash

<img align="right" width="200px" src="logo.png" alt="Active Hashcash logo"/>

ActiveHashcash protects Rails applications against bots and brute force attacks without annoying humans.

Hashcash is proof-of-work algorithm, invented by Adam Back in 1997, to protect systems against denial of service attacks.
ActiveHashcash is an easy way to protect any Rails application against brute force attacks and bots.

The idea is to force clients to spend some time to solve a hard problem that is very easy to verify for the server.
We have developped ActiveHashcash after seeing brute force attacks against our Rails application monitoring service [RorVsWild](https://rorvswild.com).

ActiveHashcash is ideal to set up on sensitive forms such as login and registration.
While the user is filling the form, the problem is solved in JavaScript and set the result into a hidden input text.
The form cannot be submitted while the proof of work has not been found.
Then the user submits the form, and the stamp is verified by the controller in a before action.

It blocks bots that do not interpret JavaScript since the proof of work is not computed.
More sophisticated bots and brute force attacks are slow down.
Moreover the complexity increases automatically for IP addresses sending many requests.
Thus it becomes very CPU costly for attackers.

Finally legitimate users are not annoyed by asking to solve a puzzle or clicking on the all images containing a bus.
Here is a [demo on a registration form](https://www.rorvswild.com/session) :

![Active Hashcash GIF preview](demo.gif)

---

<img align="left" height="24px" src="rorvswild_logo.jpg" alt="RorVsWild logo"/>Made by <a href="https://www.rorvswild.com">RorVsWild</a>, performances & exceptions monitoring for Ruby on Rails applications.

---

## Limitations

The JavaScript implementation is 10 to 20 times slower than the official C version.
I first used the SubtleCrypto API but it is surprisingly slower than a custom SHA1 implementation.
Maybe I did in an unefficient way 2df3ba5?
Another idea would be to compile the work algortihm in wasm.

Unfortunately, I'm not a JavaScript expert.
Maybe you have good JS skills to optimize it?
Any help would be appreciate to better fights bots and brute for attacks!

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_hashcash"
```

Require hashcash from your JavaScript manifest.

```js
//= require hashcash
```

Add a Hashcash hidden field into the form you want to protect.

```erb
<form>
  <%= hashcash_hidden_field_tag %>
</form>
```

Then you have to define a `before_action :check_hashcash` in you controller.

```ruby
class SessionController < ApplicationController
  include ActiveHashcash

  # Only the action receiving the form needs to be protected
  before_action :check_hashcash, only: :create
end
```

To customize some behaviour, you can override most of the methods which begins with `hashcash_`.
Simply have a look to `active_hashcash.rb`.

From versiom 0.3.0, spent stamps are now stored into a relational database instead of Redis.
This prevents from spending stamp more than once.
You must run a migration:

```
rails active_hashcash:install:migrations
rails db:migrate
```

## Dashboard

There is a mountable dahsboard which allows to see all spent stamps.
It's not mandatory, but useful for monitoring purpose.

```ruby
# config/routes.rb
mount ActiveHashcash::Engine, at: "hashcash"
```

ActiveHashcash cannot guess how you handle user authentication, because it is different for all Rails applications.
So you have to monkey patch `ActiveHashcash::ApplicationController` in order to inject your own mechanism.
The patch can be saved wherever you want.
For example, I like to have all the patches in one place, so I put them in `lib/patches`.

```ruby
# lib/patches/active_hashcash.rb

ActiveHashcash::ApplicationController.class_eval do
    before_action :require_admin

    def require_admin
      # This example supposes there are current_user and User#admin? methods
      raise ActionController::RoutingError.new("Not found") unless current_user.try(:admin?)
    end
  end
end
```

Then you have to require the monkey patch.
Because it's loaded via require, it won't be reloaded in development.
Since you are not supposed to change this file often, it should not be an issue.

```ruby
# config/application.rb
config.after_initialize do
  require "patches/active_hashcash"
end
```

If you use Devise, you can check the permission directly from routes.rb:

```ruby
# config/routes.rb
authenticate :user, -> (u) { u.admin? } do # Supposing there is a User#admin? method
  mount ActiveHashcash::Engine, at: "hashcash" # http://localhost:3000/hashcash
end
```


### Before version 0.3.0

You must have Redis in order to prevent double spent stamps. Otherwise it will be useless.
It automatically tries to connect with the environement variables `ACTIVE_HASHCASH_REDIS_URL` or `REDIS_URL`.
You can also manually set the URL with `ActiveHashcash.redis_url = redis://user:password@localhost:6379`.

You should call `ActiveHashcash::Store#clean` once a day, to remove expired stamps.

## Complexity

Complexity is the most important parameter. By default its value is 20 and requires most of the time 5 to 20 seconds to be solved on a decent laptop.
The user won't wait that long, since he needs to fill the form while the problem is solving.
Howevever, if your application includes people with slow and old devices, then consider lowering this value, to 16 or 18.

You can change the minimum complexity, either with `ActiveHashcash.bits = 20` or by overriding the method `hashcash_bits` in you controller.

Since version 0.3.0, the complexity increases with the number of stamps spent during le last 24H from the same IP address.
Thus it becomes very efficient to slow down brute force attacks.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_hashcash.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Made by Alexis Bernard at [Base Secrète](https://basesecrete.com).
