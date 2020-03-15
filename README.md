# Bonito

_Data, in a can_

![build](https://travis-ci.org/TomFinill/bonito.svg?branch=master) [![Maintainability](https://api.codeclimate.com/v1/badges/15ad4524ca0d4c0cdff4/maintainability)](https://codeclimate.com/github/tmfnll/bonito/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/15ad4524ca0d4c0cdff4/test_coverage)](https://codeclimate.com/github/tmfnll/bonito/test_coverage)

## TL;DR

_`Bonito` is a ruby DSL for generating canned data where timing is important._  

`Bonito` uses [Timecop](https://github.com/travisjeffery/timecop) to simulate
the flow of time as it generates data.

## Introduction

At the core of `Bonito` is the concept of a _timeline_.  A timeline is a sort
of schema that defines in what time period each of a sequence of actions can
occur.

An action in `Bonito` is called a `Moment` and is considered to have a duration
of `0` itself.

#### `Bonito` can generate data in series:

Suppose we wish to simulate an online content creator's data, where _author_s
write _articles_ and _users_ _comment_ on these articles.

We could use `Bonito` to define a `serial timeline`:

```ruby
# First we create data structures to store out data and keep track of them in
# a `Scope` object: 
scope = Bonito::Scope.new.tap do |scope|
  scope.authors = []
  scope.articles = []
  scope.users = []
  scope.comments = []
  scope.users_and_authors = []
end

# Next we define out serial timeline:
serial = Bonito.over 1.week do
  please do |scope|  # The `please` method denotes the definition of an action
    author = scope.authors.sample
    title = Faker::Company.bs
    scope.article = Article.new(title, author)
    scope.articles << article
  end

  repeat times: rand(10), over: 5.days do
    please do |scope|
      user = scope.users.sample
      content = Faker::Lorem.sentence
      scope.comments << Comment.new(content, scope.article, user)
    end
  end
end
```

This _timeline_ specifies the creation of an instance of `Article` _followed by_
the creation of _up to_ 10 `Comment` belonging to that `Article`. 
The `created_at` time on the `Article` will be before that of each of the
`Comment`s. The total elapsed time between the creation of the `Article` and
the creation of the final `Comment` will not be more than `1.week`.


#### `Bonito` can generate data in parallel:

Consider the timeline `serial` we defined above.  We might realistically want
to generate data that represents many authors working _simultaneously_ on
articles with users then commenting on these once they have been published.

This can be done as follows:

```ruby
parallel = Bonito.over 2.weeks do
  simultaneously do
    repeat times: 5 do
      use serial
    end
  end
end
```

The above will create 5 `Article`s, each having up to 9 `Comment`s where the
moment at which `Article` is created is independent of any other `Article` or
`Comment`.  The times at which the `Comment`s are created, meanwhile, are
dependent _only_ on the `Article` to which they belong.

#### Execution

Now we have defined the _shape_ of the data we wish to create, it remains 
to actually create it.  

This is achieved via a `Runner` object that takes a timeline and uses it to 
evaluate the individual actions. It distributes these actions randomly yet
within the confines of the schedule defined by the timeline.

```ruby
  Bonito.run parallel_window, scope: scope, starting: 8.weeks_ago
```

This will take the `Window` object `parallel_window` and distribute the `Moment`s
it contains according to its configuration, mapping each `Moment` to a point
in time relative to the start time given by the `starting` parameter.

## Scaling

A typical use case may require different data set sizes for
different applications: For example, a large dataset to live in a staging 
environment in order to sanity check releases and a small, easy to load dataset 
that can be used locally while developing.

Suppose we have certain events that we wish to occur only once,
(using the above example, this may be the creation of some `Publication` object
representing the newspaper for which articles are being written) as well
as events that we wish to be able to scale, such as the creation of `Article`
objects and their associated `Comment`s.

Using `Bonito`, we could define two timelines: a `singleton_timeline` 
that is run once per dataset and generates our 
`Organisation` model, as well as a `scalable_timeline`
that results in different sizes of data according to some size parameter.

These timelines can then be combined as follows, where the size parameter `n`
can be provided dynamically as, say, an argument provided to a `Rake` task.
 
```ruby
scaled = singleton_timeline + (scalable_timeline ** n)
```

The `scaled_timeline`, when run, will run the `scalable_timeline` `n` times
in parallel.

## Scoping

Data can be shared amongst `Moments` via a `Scope` object.
Attributes on a `Scope` object are available within the **current** serial 
timeline and in all **child** serial timelines.

Consider the following example:

```ruby
Bonito.over 1.week do
  please do |scope|
    scope.foo = 'bar'
  end

  over 2.days do
    please do |scope|
      puts scope.foo # prints 'bar'
    end

    please do |scope|
      scope.foo = 'baz'
    end

    please do |scope|
      puts scope.foo # now prints 'baz'
    end
  end
  
  please do |scope|
    puts scope.foo # still prints 'bar'
  end
end
```

## An Example

Consider the following:

```ruby
# Initialise the data store, in practice a database would probably be used for 
# this. Defined this way, these variables are available globally.
 
scope = Bonito::Scope.new.tap do |scope|
  scope.publications = []
  scope.authors = []
  scope.articles = []
  scope.users = []
  scope.comments = []
  scope.users_and_authors = []
end

# We only ever want to create publication, regardless of how we scale, so we 
# create a setup timeline to handle this
singleton_timeline = Bonito.over 1.day do
  please do |scope|
    scope.publications << Publication.new
  end
end


scalable_timeline = Bonito.over 1.week do
  # Make the publication available to the current timeline.
  please do |scope|
    scope.publication = scope.publications.first
  end
  # Simultaneously create authors and users, interweaving the two.
  simultaneously do
    over 1.day do
      # Create 5 authors over the course of a day 
      repeat times: 5, over: 1.day do
        please do |scope|
          name = Faker::Name.name
          author = Author.new(name)
          scope.authors << author
          scope.users_and_authors << author
        end
      end
    end

    # Create 10 users, also over one day, waiting at least 2 hours before 
    # creating the first. 
    also over: 1.day, after: 2.hours do
      repeat times: 10, over: 1.day do
        please do |scope|
          name = Faker::Name.name
          email = Faker::Internet.safe_email(name)
          user = User.new(name, email)
          scope.users << user
          scope.users_and_authors << user
        end
      end
    end
  end
  
  # Repeat the following sequence of events 5 times over 5 days
  repeat times: 5, over: 5.days do
    # Choose one of the existing authors and create an article belonging to that
    # author. 
    please do |scope|
      author = scope.authors.sample
      title = Faker::Company.bs
      scope.article = Article.new(title, author, scope.publication)
      scope.articles << scope.article
    end
    
    # Choose one of the existing users and have them leave a comment on the 
    # article that was just created. 
    repeat times: rand(10), over: 5.hours do
      please do |scope|
        user = scope.users.sample
        content = Faker::Lorem.sentence
        scope.comments << Comment.new(content, scope.article, user)
      end
    end
  end
end

# Finally, we run the timeline to generate our data 
scale = 5
scaled_timeline = singleton_timeline + (scalable_timeline ** scale)

Bonito.run scaled_timeline, scope: scope, starting: 8.weeks_ago
```


