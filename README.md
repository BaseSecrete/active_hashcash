# ActiveHashcash

Protect Rails applications against bots and brute force attacks without annoying humans.

<div><img align="right" width="200px" src="logo.png" alt="Active Hashcash logo"/></div>

Hashcash is proof-of-work algorithm, invented by Adam Back in 1997, to protect systems against denial of service attacks.
ActiveHashcash is an easy way to protect any Rails application against brute force attacks and bots.

The idea is to force clients to spend some time to solve a hard problem that is very easy to verify for the server.
We have developed ActiveHashcash after seeing brute force attacks against our Rails application monitoring service [RorVsWild](https://rorvswild.com).

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

<div><img align="left" height="24px" src="rorvswild_logo.jpg" alt="RorVsWild logo"/>Made by <a href="https://www.rorvswild.com">RorVsWild</a>, performances & exceptions monitoring for Ruby on Rails applications.</div>

---

## Installation

Add this line to your application's Gemfile and run `bundle install`:

```ruby
gem "active_hashcash"
```

Stamps are stored into the database to prevents from spending them more than once.
You must install and run a migration:

```
rails active_hashcash:install:migrations
rails db:migrate
```

Then you have to include ActiveHashcash and add a `before_action :check_hashcash` in you controller:

```ruby
class SessionController < ApplicationController
  include ActiveHashcash

  # Only the action receiving the form needs to be protected
  before_action :check_hashcash, only: :create
end
```

The action `SessionController#create` is now protected.
The final step is compute the hashcash from the client side.
Start by adding a Hashcash hidden field into the form you want to protect.

```erb
<form>
  <%= hashcash_hidden_field_tag %>
</form>
```

Require hashcash from your JavaScript manifest.

```js
//= require hashcash
```

Or, link hashcash to your JavaScript manifest and load it to your head.

```js
//= link hashcash.js
```

```erb
<%= javascript_include_tag "hashcash", "data-turbo-track": "reload", defer: true %>
```

The hashcash stamp will be set in the hidden input once computed and the submit button enabled.

To customize behaviours, you can override methods of ActiveHashcash module.



### Dashboard

There is a mountable dashboard which allows to see all spent stamps.
It's not mandatory, but useful for monitoring purpose.

![ActiveHashcash dashboard](active_hashcash_dashboard.png "ActiveHashcash dashboard")

```ruby
# config/routes.rb
mount ActiveHashcash::Engine, at: "hashcash"
```

ActiveHashcash cannot guess how user authentication is handled, because it is different for all Rails applications.
So here is 3 options.

#### Inheritance

By default ActiveHashcash extends `ActionController::Base`, but you can change it to any controller, such as `AdminController`.

```ruby
# config/initializers/active_hashcash.rb
Rails.application.configure do
  ActiveHashcash.base_controller_class = "AdminController"
end
```
#### Monkey patching

Monkey patching `ActiveHashcash::ApplicationController` let you inject your own mechanism.

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

Then the patch has to be loaded from after initialization:

```ruby
# config/application.rb
config.after_initialize do
  require "patches/active_hashcash"
end
```

#### With Devise

Permission check can be achieved directly from routes.rb:

```ruby
# config/routes.rb
authenticate :user, -> (u) { u.admin? } do # Supposing there is a User#admin? method
  mount ActiveHashcash::Engine, at: "hashcash" # http://localhost:3000/hashcash
end
```

### Before version 0.3.0

You must have Redis in order to prevent double spent stamps. Otherwise it will be useless.
It automatically tries to connect with the environment variables `ACTIVE_HASHCASH_REDIS_URL` or `REDIS_URL`.
You can also manually set the URL with `ActiveHashcash.redis_url = redis://user:password@localhost:6379`.

You should call `ActiveHashcash::Store#clean` once a day, to remove expired stamps.

To upgrade from 0.2.0 you must run the migration :

```
rails active_hashcash:install:migrations
rails db:migrate
```

## Complexity

Complexity controls the base proof-of-work difficulty.
Increasing by one double the work time.
By default its value is 20 and you can change it with `ActiveHashcash.bits = 24` or by overriding the method `hashcash_bits` in the controller.

### Penalities

A penality is added for pushy IPs which submit valid stamps too fast.
The goal is to slow down attackers using a botnet.
The penality rules can be defined like this.

```ruby
ActiveHashcash.penalty_rules = [
  {period: 1.hour, rate: 0.5},
  {period: 24.hours, rate: 0.25}
]
```

For every valid stamps sent less than an hour ago, a penality of 0.5 is added.
Then, for every valid stamp sent between 1 and 24 hours ago a penality of 0.25 is added.
Thus, if an IP sent 1 stamp one minue ago, and 3 others few hours ago, it add a complexity of `(1 * 0.5 + 3 * 0.25).floor # => 1`.
So next hashcash must have a complexity of `ActiveHashcash.bits + 1`.

If you have many users behind the same IP, such as a NAT, you can either lower the rates or disable the penality.
In your controller, override the method `hashcash_bits_penality`:

```ruby
class ApplicationController
  def hashcash_bits_penality
    # Only the base complexity (ActiveHashcash.bits) will apply for people with IP 1.2.3.4
    hashcash_ip_address == "1.2.3.4" ? 0 : super
  end
end
```

Or, if someone is attacking you from a specific country:

```ruby
class ApplicationController
  def hashcash_bits_penality
    geoip.country(hashcash_ip_address).country_code == "XX" ? super + 2 : super
  end
end
```

## Limitations

The JavaScript implementation is slower than the official C version.
It uses a pure JS SHA-256 implementation running inside a Web Worker, which keeps the main thread responsive while mining.
A synchronous tight loop avoids the per-call async overhead of `crypto.subtle.digest()`, making it the fastest browser-side approach across Chrome and Safari.

No `crypto.subtle` or secure context (HTTPS) is required, so it works in any environment including plain HTTP during development.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/BaseSecrete/active_hashcash.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Made by [Alexis Bernard](https://alexis.bernard.io/).
