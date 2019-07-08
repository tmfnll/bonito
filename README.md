# Bonito

![build](https://travis-ci.org/TomFinill/bonito.svg?branch=master) [![Maintainability](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/maintainability)](https://codeclimate.com/github/TomFinill/bonito/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/test_coverage)](https://codeclimate.com/github/TomFinill/bonito/test_coverage)

## TL;DR

**Bonito** is a ruby DSL for generating canned data.  It can simulate, by 
 _freezing time_, sequences of events happening in series and parallel in 
 order to approximate any kind of live data.

`Bonito` uses [Timecop](https://github.com/travisjeffery/timecop) in order to
 perform this _freezing_. 

![bonito](https://live.staticflickr.com/3363/3278938654_a9991fa129_z.jpg)

### An example is worth a thousand theorems

#### Timeline Definition

Suppose you work for a small media startup and you wish to create a set of data
that can be loaded into a demo environment in order to then be used by the sales 
department when presenting to potential customers.

This data could consist of models representing `Author`s and the `Article`s they 
write, as well as readers (or `User`s) and `Comment`s they leave on the 
aforementioned `Article`s.

Obviously, each `Article` should be created by an `Author` and the simulated
 creation time of each `Comment` should be _after_ that of its associated 
 `Article`.  In fact, we can consider the data to consist of a collection of 
 _timelines_ where each timeline includes the creation of an `Article` by an 
 `Author` with this being followed afterwards by a series of `Comment`s on the
 `Article` being created by `User`s.
 
`Bonito` offers a `Window` object to model such timelines. 

Each `Window` has a duration in which events occur.  These events are referred 
to in `Bonito` as `Moment`s.  

For example, a `Window` representing the timeline described above could be 
created as follows:

```ruby
example_window = Bonito.over 1.week do
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

Here, via the `over` method on the `Bonito` module, a `Window` is defined.  Within
this window a series of `Moment`s are defined. Firstly, the `Window#please` method 
is invoked to define the event.  In this case the event consists of creating an
`Article`.

After this, we wish to define `Moment`s in which many `Comment`s are created for
the `Article`.

To do this we use the `Window#repeat` method. This method accepts a block along 
with a `times` parameter and an `over` parameter and inserts a new, child `Window`
into the current, parent window.  The contents of the child window will be
that defined by the block repeated `times` times.

This means that the child `Window` defines up to 9 (`rand(10)`) `Moment`s
where each such `Moment` creates a `Comment` belonging to the previously 
created `Article`.

_Now_, suppose we intend to simulate the creation of multiple `Article`s and 
their associated `Comment`s.  One way to achieve this would be to repeat the 
previously defined `Window` via the `repeat` command:

```ruby
serial_window = Bonito.over 10.weeks do
  repeat times: 5 do
    use example_window
  end
end
``` 

However this approach has a serious drawback: all events will occur _in series_.
The second `Article` will not be created until all the `Comment`s on the first 
`Article` have been created and similarly the third `Article` will be preceded by
all `Comment`s on the second.

Ideally what we want is for `Articles` and `Comment`s to be _interleaved_.

We can achieve this using the `Window#simultaneously`
method to create a `Container` object, used to define parallel timelines. We 
then fill that container with the same, `Window` five times, using the 
`Container#use` method.

```ruby
parallel_window = Bonito.over 2.weeks do
  simultaneously do
    repeat times: 5 do
      use example_window 
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

_However_, a typical use case may require different data set sizes for 
different applications: For example, a large dataset to live in a staging 
environment in order to sanity check releases and a small, easy to load dataset 
that can be used locally while developing.

Suppose we have certain events that we wish to occur only once, 
(using the above example, this may be the creation of some `Organisation` object
representing the news company for which articles are being written) as well
as events that we wish to be able to scale, such as the creation of `Article`
objects and their associated `Comment`s.

Using `Bonito`, we could define two windows: a `singleton_window` that is run once per
dataset and generates our `Organisation` model, as well as a `scalable_window`
that results in different sizes of data according to some size parameter.

These windows can then be combined as follows, where the size paramter `factor`
can be provided dynamically as, say, an argument provided to a `Rake` task.
 
```ruby
scaled_window = singleton_window + (scalable_window * factor)
```

The `scaled_window`, when run, will run the `scalable_window` `factor` times
in parallel.


