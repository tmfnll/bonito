# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'End to end' do
  class SimpleModel # :nodoc:
    attr_reader :created_at
    def initialize
      @created_at = Time.now
    end
  end

  class Author < SimpleModel # :nodoc:
    attr_reader :name
    def initialize(name)
      @name = name
      super()
    end
  end

  class User < SimpleModel # :nodoc:
    attr_reader :name, :email
    def initialize(name, email)
      @name = name
      @email = email
      super()
    end
  end

  class Article < SimpleModel # :nodoc:
    attr_reader :title, :author
    def initialize(title, author)
      @title = title
      @author = author
      super()
    end
  end

  class Comment < SimpleModel # :nodoc:
    attr_reader :content, :article, :user
    def initialize(content, article, user)
      @content = content
      @article = article
      @user = user
      super()
    end
  end

  let(:scope) do
    Dodo::Scope.new.tap do |scope|
      scope.authors = []
      scope.articles = []
      scope.users = []
      scope.comments = []
      scope.users_and_authors = []
    end
  end

  let(:serial) do
    Dodo.over 1.week do
      simultaneously do
        over 1.day do
          repeat times: 5, over: 1.day do
            please do
              name = Faker::Name.name
              author = Author.new(name)
              authors << author
              users_and_authors << author
            end
          end
        end

        also over: 1.day, after: 2.hours do
          repeat times: 10, over: 1.day do
            please do
              name = Faker::Name.name
              email = Faker::Internet.safe_email(name)
              user = User.new(name, email)
              users << user
              users_and_authors << user
            end
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
  end
  let(:scaled_serial) { serial }

  let(:logger) { Logger.new STDOUT }
  let(:progress_factory) { Dodo::ProgressBar.factory }
  let(:stretch) { 1 }
  let(:opts) { { stretch: stretch } }
  let(:scheduler) { serial.scheduler(distribution, scope, opts) }
  let(:progress) { progress_factory.call }
  let(:decorated_enum) do
    Dodo::ProgressDecorator.new scheduler, progress
  end

  let(:users_and_authors) { scope.users_and_authors }
  let(:authors) { scope.authors }
  let(:users) { scope.users }
  let(:articles) { scope.articles }
  let(:comments) { scope.comments }
  let(:comments_by_article) { comments.group_by(&:article) }

  subject! do
    Dodo.run scaled_serial, starting: 3.weeks.ago,
                            scope: scope,
                            progress_factory: progress_factory, **opts
  end

  context 'without scaling' do
    it 'should complete successfully' do
    end

    it 'should add 2 timelines to the top level serial' do
      expect(serial.to_a.size).to eq 2
    end

    let(:parallel) { serial.to_a.first }
    it 'should first add a parallel to the top level serial' do
      expect(parallel).to be_a Dodo::ParallelTimeline
    end

    it 'should add two serials to the parallel' do
      expect(parallel.to_a.size).to eq 2
    end

    it 'should add a single timeline to the first of these serial' do
      expect(parallel.to_a.first.to_a.size).to eq 1
    end

    it 'should add a serial to the first of these serials' do
      expect(parallel.to_a.first.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 5 timelines to this serial' do
      expect(parallel.to_a.first.to_a.first.to_a.size).to eq 5
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.first.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    it 'should add a single timeline to the second of these serial' do
      expect(parallel.to_a.last.to_a.size).to eq 1
    end

    it 'should add a serial to the second of these serials' do
      expect(parallel.to_a.last.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 10 timelines to this serial' do
      expect(parallel.to_a.last.to_a.first.to_a.size).to eq 10
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.last.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    let(:child_serial) { serial.to_a.last }
    it 'should then add a serial to the top level serial' do
      expect(child_serial).to be_a Dodo::SerialTimeline
    end

    it 'should add 10 timelines to this child_serial' do
      expect(child_serial.to_a.size).to eq 10
    end

    it 'should create 5 authors' do
      expect(authors.size).to eq 5
    end

    it 'should create 10 users' do
      expect(users.size).to eq 10
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    it 'should create users and authors over 1 day' do
      diff = (
        users_and_authors.last.created_at - users_and_authors.first.created_at
      )
      expect(diff).to be <= (1.day + 2.hours)
    end

    it 'should create authors over 1 day' do
      diff = authors.last.created_at - authors.first.created_at
      expect(diff).to be <= 1.day
    end

    it 'should create users and authors over 1 day' do
      diff = users.last.created_at - users.first.created_at
      expect(diff).to be <= 1.day
    end

    it 'should create all users and authors before any articles' do
      expect(
        users_and_authors.last.created_at
      ).to be < articles.first.created_at
    end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it 'should create a total of 5 articles' do
      expect(articles.size).to eq 5
    end

    it 'should create articles and comments over a period of 5 days' do
      diff = comments.last.created_at - articles.first.created_at
      expect(diff).to be <= 5.days
    end

    it 'should create comments over a period of 5 hours' do
      comments_by_article.each_value do |article_comments|
        diff = (
          article_comments.last.created_at - article_comments.first.created_at
        )
        expect(diff).to be <= 5.hours
      end
    end

    it 'should create all models over the course of a week' do
      diff = comments.last.created_at - users_and_authors.first.created_at
      expect(diff).to be <= 1.week
    end

    it 'should create no models before 3 weeks ago' do
      expect(users_and_authors.first.created_at).to be >= 3.weeks.ago
    end

    it 'should create no models after 2 weeks ago' do
      expect(comments.last.created_at).to be <= 2.weeks.ago
    end
  end

  context 'with the serial scaled by 2' do
    let(:factor) { 2 }
    let(:scaled_serial) { serial**2 }

    it 'should complete successfully' do
    end

    it 'should add 2 happenings to the top level serial' do
      expect(serial.to_a.size).to eq 2
    end

    let(:parallel) { serial.to_a.first }
    it 'should first add a parallel to the top level serial' do
      expect(parallel).to be_a Dodo::ParallelTimeline
    end

    it 'should add two serials to the parallel' do
      expect(parallel.to_a.size).to eq 2
    end

    it 'should add a single happening to the first of these serial' do
      expect(parallel.to_a.first.to_a.size).to eq 1
    end

    it 'should add a serial to the first of these serials' do
      expect(parallel.to_a.first.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 5 happenings to this serial' do
      expect(parallel.to_a.first.to_a.first.to_a.size).to eq 5
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.first.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    it 'should add a single happening to the second of these serial' do
      expect(parallel.to_a.last.to_a.size).to eq 1
    end

    it 'should add a serial to the second of these serials' do
      expect(parallel.to_a.last.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 10 happenings to this serial' do
      expect(parallel.to_a.last.to_a.first.to_a.size).to eq 10
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.last.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    let(:child_serial) { serial.to_a.last }
    it 'should then add a serial to the top level serial' do
      expect(child_serial).to be_a Dodo::SerialTimeline
    end

    it 'should add 10 happenings to this child_serial' do
      expect(child_serial.to_a.size).to eq 10
    end

    it 'should create 10 authors' do
      expect(authors.size).to eq 10
    end

    it 'should create 20 users' do
      expect(users.size).to eq 20
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    # xit 'should create users and authors over 1 day' do
    #   diff = (
    #     users_and_authors.last.created_at - users_and_authors.first.created_at
    #   )
    #   expect(diff).to be <= (1.day + 2.hours)
    # end

    # Certain time based test cases are expected to fail.  The reason why is
    # best illustrated with a direct reference to the following test case.
    # By paralellising the `serial` using the ** operator we are _effectively_
    # scheduling the serial twice and sorting by offset.  As such, the time
    # at which the first author is created in one of the parallelised 'versions'
    # of the serial may be very different from the time the first author is
    # created in the other 'version' despite the fact that in both cases the
    # authors required were created within the specified time frame.
    #
    # Skipping the tests until I can think of how to improve them.
    # xit 'should create authors over 1 day' do
    #   diff = authors.last.created_at - authors.first.created_at
    #   expect(diff).to be <= 1.day
    # end

    # xit 'should create users and authors over 1 day' do
    #   diff = users.last.created_at - users.first.created_at
    #   expect(diff).to be <= 1.day
    # end

    # xit 'should create all users and authors before any articles' do
    #   expect(
    #     users_and_authors.last.created_at
    #   ).to be < articles.first.created_at
    # end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it 'should create a total of 10 articles' do
      expect(articles.size).to eq 10
    end

    # xit 'should create articles and comments over a period of 5 days' do
    #   diff = comments.last.created_at - articles.first.created_at
    #   expect(diff).to be <= 5.days
    # end

    it 'should create comments over a period of 5 hours' do
      comments_by_article.each_value do |article_comments|
        diff = (
          article_comments.last.created_at - article_comments.first.created_at
        )
        expect(diff).to be <= 5.hours
      end
    end

    it 'should create all models over the course of a week' do
      diff = comments.last.created_at - users_and_authors.first.created_at
      expect(diff).to be <= 1.week
    end

    it 'should create no models before 3 weeks ago' do
      expect(users_and_authors.first.created_at).to be >= 3.weeks.ago
    end

    it 'should create no models after 2 weeks ago' do
      expect(comments.last.created_at).to be <= 2.weeks.ago
    end
  end

  context 'with a stretch factor of 2' do
    let(:stretch) { 2 }

    it 'should complete successfully' do
    end

    it 'should add 2 timelines to the top level serial' do
      expect(serial.to_a.size).to eq 2
    end

    let(:parallel) { serial.to_a.first }
    it 'should first add a parallel to the top level serial' do
      expect(parallel).to be_a Dodo::ParallelTimeline
    end

    it 'should add two serials to the parallel' do
      expect(parallel.to_a.size).to eq 2
    end

    it 'should add a single timeline to the first of these serial' do
      expect(parallel.to_a.first.to_a.size).to eq 1
    end

    it 'should add a serial to the first of these serials' do
      expect(parallel.to_a.first.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 5 timelines to this serial' do
      expect(parallel.to_a.first.to_a.first.to_a.size).to eq 5
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.first.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    it 'should add a single timeline to the second of these serial' do
      expect(parallel.to_a.last.to_a.size).to eq 1
    end

    it 'should add a serial to the second of these serials' do
      expect(parallel.to_a.last.to_a.first).to be_a Dodo::SerialTimeline
    end

    it 'it should add 10 timelines to this serial' do
      expect(parallel.to_a.last.to_a.first.to_a.size).to eq 10
    end

    it 'it should add only moments to this serial' do
      expect(
        parallel.to_a.last.to_a.first.to_a
      ).to all(be_a Dodo::Moment)
    end

    let(:child_serial) { serial.to_a.last }
    it 'should then add a serial to the top level serial' do
      expect(child_serial).to be_a Dodo::SerialTimeline
    end

    it 'should add 10 timelines to this child_serial' do
      expect(child_serial.to_a.size).to eq 10
    end

    it 'should create 5 authors' do
      expect(authors.size).to eq 5
    end

    it 'should create 10 users' do
      expect(users.size).to eq 10
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    it 'should create users and authors over 2 days and 4 hours' do
      diff = (
        users_and_authors.last.created_at - users_and_authors.first.created_at
      )
      expect(diff).to be <= (2.days + 4.hours)
    end

    it 'should create authors over 2 days' do
      diff = authors.last.created_at - authors.last.created_at
      expect(diff).to be <= 2.days
    end

    it 'should create users over a period less than 2 days' do
      diff = users.last.created_at - users.first.created_at
      expect(diff).to be <= 2.days
    end

    it 'should create all users and authors before any articles' do
      expect(
        users_and_authors.last.created_at
      ).to be < articles.first.created_at
    end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it 'should create a total of 5 articles' do
      expect(articles.size).to eq 5
    end

    it 'should create articles and comments over a period of 10 days' do
      diff = comments.last.created_at - articles.first.created_at
      expect(diff).to be <= 10.days
    end

    it 'should create comments over a period of 10 hours' do
      comments_by_article.each_value do |article_comments|
        diff = (
          article_comments.last.created_at - article_comments.first.created_at
        )
        expect(diff).to be <= 10.hours
      end
    end

    it 'should create all models over the course of 2 weeks' do
      diff = comments.last.created_at - users_and_authors.first.created_at
      expect(diff).to be <= 2.weeks
    end

    it 'should create no models before 3 weeks ago' do
      expect(users_and_authors.first.created_at).to be >= 3.weeks.ago
    end

    it 'should create no models after 1 week ago' do
      expect(comments.last.created_at).to be <= 1.week.ago
    end
  end
end
