# Dodo


![build](https://travis-ci.org/TomFinill/dodo.svg?branch=master) [![Maintainability](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/maintainability)](https://codeclimate.com/github/TomFinill/dodo/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/42198ebf17bf127e0da6/test_coverage)](https://codeclimate.com/github/TomFinill/dodo/test_coverage)

## TL;DR

The **Demo Data Dodo** is a ruby DSL which provides a 
family of data structures that can be used to simulate the occurrence of 
interrelated events over a series of (nested) intervals.

`Dodo` uses [Timecop](https://github.com/travisjeffery/timecop) to _freeze_ 
time at instants specified by these data structures.

### Example

Suppose you work for a small media startup and you wish to create a set of data
that can be loaded into a demo environment in order to then be used by the sales 
department when presenting to potential customers.

This data could consist of models representing `Author`s and the `Article`s they 
write, as well as readers (or `User`s) and `Comment`s they leave on the 
aforementioned `Article`s.

Obviously, each `Article` should be created by an `Author` and the simulated
 creation time of each `Comment` should be _after_ that of its associated 
 `Article`.

`Dodo` could be used as follows to define this demo data set:

```ruby
Dodo.over 1.week do
  simultaneously over: 1.day do
    repeat times: 5 do
      please do
        name = Faker::Name.name
        author = Author.new(name)
        authors << author
        users_and_authors << author
      end
    end
  end.also over: 1.day do

    repeat times: 10 do
      please do
        name = Faker::Name.name
        email = Faker::Internet.safe_email(name)
        user = User.new(name, email)
        users << user
        users_and_authors << user
      end
    end
  end

  repeat times: 5, over: 5.days do
    please do
      author = authors.sample
      title = Faker::Company.bs
      self.article = Article.new(title, author)
      articles << article
    end

    repeat times: rand(10), over: 5.hours do
      please do
        user = users.sample
        content = Faker::Lorem.sentence
        comments << Comment.new(content, article, user)
      end
    end
  end
end
```
 
The above data structure (a `Dodo::Window` object, to be precise) will 
simulate the creation of objects (i.e. `Author`s, `Article`s etc.) over a
period of `1.week`:

```ruby
Dodo.over 1.week do
  # ... 
end
```

It will initially create 5 `Author`s and 10 `User`s, in some random order,
over the course of `1.day`. 

Then it will create an `Article` followed by up to 10 `Comment`s on said article.

```ruby
please do
  author = authors.sample
  title = Faker::Company.bs
  self.article = Article.new(title, author)
  articles << article
end

repeat times: rand(10), over: 5.hours do
  please do
    user = users.sample
    content = Faker::Lorem.sentence
    comments << Comment.new(content, article, user)
  end
end
```

This step will be repeated a total of five times over a period of
`5.days`

```ruby
repeat times: 5, over: 5.days do
  # ...  
end
```

![dodo](https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Dodo_%28PSF%29.png/203px-Dodo_%28PSF%29.png)
