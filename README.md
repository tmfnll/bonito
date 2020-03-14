# Bonito

![build](https://travis-ci.org/TomFinill/bonito.svg?branch=master) [![Maintainability](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/maintainability)](https://codeclimate.com/github/TomFinill/bonito/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/test_coverage)](https://codeclimate.com/github/TomFinill/bonito/test_coverage)

## TL;DR

**Bonito** is a ruby DSL for generating canned data where timing is important.  

`Bonito` uses [Timecop](https://github.com/travisjeffery/timecop) in simulate
the flow of time as it generates data.


#### `Bonito` can generate data in series:

Suppose we wish to simulate an online content creator's data, where _author_s
write _articles_ and _users_ _comment_ on these articles.

We could use `Bonito` to define a `serial timeline`:

```ruby
serial = Bonito.over 1.week do
  please do
    author = authors.sample
    title = Faker::Company.bs
    self.article = Article.new(title, author)
    articles << article
  end

  repeat times: rand(10), over: 5.days do
    please do
      user = users.sample
      content = Faker::Lorem.sentence
      comments << Comment.new(content, article, user)
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

This is achieved via a `Runner` object that takes a `Window` and uses it to 
evaluate `Moment`s.

```ruby
  Bonito.run parallel_window, starting: 8.weeks_ago
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
(using the above example, this may be the creation of some `Organisation` object
representing the news company for which articles are being written) as well
as events that we wish to be able to scale, such as the creation of `Article`
objects and their associated `Comment`s.

Using `Bonito`, we could define two timelines: a `singleton_timeline` 
that is run once per dataset and generates our 
`Organisation` model, as well as a `scalable_timeline`
that results in different sizes of data according to some size parameter.

These windows can then be combined as follows, where the size paramter `factor`
can be provided dynamically as, say, an argument provided to a `Rake` task.
 
```ruby
scaled = singleton_timeline + (scalable_timeline * factor)
```

The `scaled_timeline`, when run, will run the `scalable_timeline` `factor` times
in parallel.


