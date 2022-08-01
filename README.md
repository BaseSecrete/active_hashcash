# ActiveHashcash

<img align="right" width="200px" src="logo.png" alt="Active Hashcash logo"/>

ActiveHashcash protects your Rails application against brute force attacks, DoS and bots.

Hashcash is proof-of-work algorithm, invented by Adam Back in 1997, to protect systems against denial of service attacks.
ActiveHashcash is an easy way to protect any Rails application against brute force attacks and some bots.

The idea is to force clients to spend some time to solve a hard problem that is very easy to verify for the server.
We have developped ActiveHashcash after seeing brute force attacks against our Rails application monitoring service [RorVsWild](https://rorvswild.com).

The idea is to enable ActiveHashcash on sensitive forms such as login and registration. While the user is filling the form,
ActiveHashcash performs the work in JavaScript and set the result into a hidden input text. The form cannot be submitted while the proof of work has not been found.
The user submits the form, and the stamp is verified by the controller in a before action.

It blocks bots that do not interpret JavaScript since the proof of work is not computed. For the more sophisticated bots, we are happy to slow them down.

Here is a [demo on a registration form](https://www.rorvswild.com/account/new) :

![Active Hashcash GIF preview](demo.gif)

## Limitations

The JavaScript implementation is 10 to 20 times slower than the official C version.
It needs some work and knowledges to be optimised. Unfortunately, I'm not a JavaScript expert.
Maybe you have good JS skills to optimize it ?

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

You must have Redis in order to prevent double spent stamps. Otherwise it will be useless.
It automatically tries to connect with the environement variables `ACTIVE_HASHCASH_REDIS_URL` or `REDIS_URL`.
You can also manually set the URL with `ActiveHashcash.redis_url = redis://user:password@localhost:6379`.

You should call `ActiveHashcash::Store#clean` once a day, to remove expired stamps.

## Complexity

Complexity is the most important parameter. By default its value is 20 and requires most of the time 5 to 20 seconds to be solved on a decent laptop.
The user won't wait that long, since he needs to fill the form while the problem is solving.
Howevever, if your application includes people with slow and old devices, then consider lowering this value, to 16 or 18.

You can change the complexity, either with `ActiveHashcash.bits = 20` or by overriding the method `hashcash_bits` in you controller.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_hashcash.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Made by Alexis Bernard at [Base Secrète](https://basesecrete.com).
