require 'spec_helper'

RSpec.describe 'End to end' do
  class SimpleModel
    attr_reader :created_at
    def initialize
      @created_at = Time.now
    end
  end

  class Author < SimpleModel
    attr_reader :name
    def initialize(name)
      @name = name
      super()
    end
  end

  class User < SimpleModel
    attr_reader :name, :email
    def initialize(name, email)
      @name = name
      @email = email
      super()
    end
  end

  class Article < SimpleModel
    attr_reader :title, :author
    def initialize(title, author)
      @title = title
      @author = author
      super()
    end
  end

  class Comment < SimpleModel
    attr_reader :content, :article, :user
    def initialize(content, article, user)
      @content = content
      @article = article
      @user = user
      super()
    end
  end


  let(:context) do
    Dodo::Context.new.tap do |context|
      context.authors = []
      context.articles = []
      context.users = []
      context.comments = []
      context.users_and_authors = []
    end
  end

  let(:window) do
    Dodo.over 1.week do

      simultaneously over: 1.day do
        repeat times: 5 do
          please do
            name = Faker::Name.name
            author = Author.new(name)
            self.authors << author
            self.users_and_authors << author
          end
        end
      end.also over: 1.day, after: 2.hours do

        repeat times: 10 do
          please do
            name = Faker::Name.name
            email = Faker::Internet.safe_email(name)
            user = User.new(name, email)
            self.users << user
            self.users_and_authors << user
          end
        end
      end

      repeat times: 5, over: 5.days do
        please do
          author = authors.sample
          title = Faker::Company.bs
          self.article = Article.new(title, author)
          self.articles << article
        end

        repeat times: rand(10), over: 5.hours do
          please do
            user = users.sample
            content = Faker::Lorem.sentence
            self.comments << Comment.new(content, article, user)
          end
        end
      end
    end
  end

  let(:logger) { Logger.new STDOUT }
  let(:progress) { Dodo::Bar.new }
  let(:cram) { 1 }
  let(:stretch) { 1 }
  let(:opts) { {cram: cram, stretch: stretch } }
  let(:distribution) { Dodo::Distribution.new 3.weeks.ago }
  let(:enumerator) { window.enum(distribution, context, opts)}
  let(:decorated_enum) { Dodo::ProgressDecorator.new enumerator, progress }
  let(:runner) { Dodo::Runner.new decorated_enum }

  let(:users_and_authors) { context.users_and_authors }
  let(:authors) { context.authors }
  let(:users) { context.users }
  let(:articles) { context.articles }
  let(:comments) { context.comments }
  let(:comments_by_article) { comments.group_by { |comment| comment.article } }

  subject! { runner.call }

  context "without scaling" do
    it 'should complete successfully' do
    end

    it "should add 2 happenings to the top level window" do
      expect(window.happenings.size).to eq 2
    end

    let(:container) { window.happenings.first }
    it "should first add a container to the top level window" do
      expect(container).to be_a Dodo::Container
    end

    it "should add two windows to the container" do
      expect(container.windows.size).to eq 2
    end

    it "should add a single happening to the first of these window" do
      expect(container.windows.first.happenings.size).to eq 1
    end

    it "should add a window to the first of these windows" do
      expect(container.windows.first.happenings.first).to be_a Dodo::Window
    end

    it "it should add 5 happenings to this window" do
      expect(container.windows.first.happenings.first.happenings.size).to eq 5
    end

    it "it should add only moments to this window" do
      expect(container.windows.first.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    it "should add a single happening to the second of these window" do
      expect(container.windows.last.happenings.size).to eq 1
    end

    it "should add a window to the second of these windows" do
      expect(container.windows.last.happenings.first).to be_a Dodo::Window
    end

    it "it should add 10 happenings to this window" do
      expect(container.windows.last.happenings.first.happenings.size).to eq 10
    end

    it "it should add only moments to this window" do
      expect(container.windows.last.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    let(:child_window) { window.happenings.last }
    it "should then add a window to the top level window" do
      expect(child_window).to be_a Dodo::Window
    end

    it "should add 10 happenings to this child_window" do
      expect(child_window.happenings.size).to eq 10
    end

    it "should create 5 authors" do
      expect(authors.size).to eq 5
    end

    it "should create 10 users" do
      expect(users.size).to eq 10
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    it 'should create users and authors over 1 day' do
      diff = users_and_authors.last.created_at - users_and_authors.first.created_at
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

    it "should create all users and authors before any articles" do
      expect(users_and_authors.last.created_at).to be < articles.first.created_at
    end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it "should create a total of 5 articles" do
      expect(articles.size).to eq 5
    end

    it 'should create articles and comments over a period of 5 days' do
      diff = comments.last.created_at - articles.first.created_at
      expect(diff).to be <= 5.days
    end

    it 'should create comments over a period of 5 hours' do
      comments_by_article.each_value do |article_comments|
        diff = article_comments.last.created_at - article_comments.first.created_at
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

  context "with a cram factor of 2" do

    let(:cram) { 2 }

    it 'should complete successfully' do
    end

    it "should add 2 happenings to the top level window" do
      expect(window.happenings.size).to eq 2
    end

    let(:container) { window.happenings.first }
    it "should first add a container to the top level window" do
      expect(container).to be_a Dodo::Container
    end

    it "should add two windows to the container" do
      expect(container.windows.size).to eq 2
    end

    it "should add a single happening to the first of these window" do
      expect(container.windows.first.happenings.size).to eq 1
    end

    it "should add a window to the first of these windows" do
      expect(container.windows.first.happenings.first).to be_a Dodo::Window
    end

    it "it should add 5 happenings to this window" do
      expect(container.windows.first.happenings.first.happenings.size).to eq 5
    end

    it "it should add only moments to this window" do
      expect(container.windows.first.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    it "should add a single happening to the second of these window" do
      expect(container.windows.last.happenings.size).to eq 1
    end

    it "should add a window to the second of these windows" do
      expect(container.windows.last.happenings.first).to be_a Dodo::Window
    end

    it "it should add 10 happenings to this window" do
      expect(container.windows.last.happenings.first.happenings.size).to eq 10
    end

    it "it should add only moments to this window" do
      expect(container.windows.last.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    let(:child_window) { window.happenings.last }
    it "should then add a window to the top level window" do
      expect(child_window).to be_a Dodo::Window
    end

    it "should add 10 happenings to this child_window" do
      expect(child_window.happenings.size).to eq 10
    end

    it "should create 10 authors" do
      expect(authors.size).to eq 10
    end

    it "should create 20 users" do
      expect(users.size).to eq 20
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    it 'should create users and authors over 1 day' do
      diff = users_and_authors.last.created_at - users_and_authors.first.created_at
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

    it "should create all users and authors before any articles" do
      expect(users_and_authors.last.created_at).to be < articles.first.created_at
    end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it "should create a total of 10 articles" do
      expect(articles.size).to eq 10
    end

    it 'should create articles and comments over a period of 5 days' do
      diff = comments.last.created_at - articles.first.created_at
      expect(diff).to be <= 5.days
    end

    it 'should create comments over a period of 5 hours' do
      comments_by_article.each_value do |article_comments|
        diff = article_comments.last.created_at - article_comments.first.created_at
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
  context "with a stretch factor of 2" do

    let(:stretch) { 2 }

    it 'should complete successfully' do
    end

    it "should add 2 happenings to the top level window" do
      expect(window.happenings.size).to eq 2
    end

    let(:container) { window.happenings.first }
    it "should first add a container to the top level window" do
      expect(container).to be_a Dodo::Container
    end

    it "should add two windows to the container" do
      expect(container.windows.size).to eq 2
    end

    it "should add a single happening to the first of these window" do
      expect(container.windows.first.happenings.size).to eq 1
    end

    it "should add a window to the first of these windows" do
      expect(container.windows.first.happenings.first).to be_a Dodo::Window
    end

    it "it should add 5 happenings to this window" do
      expect(container.windows.first.happenings.first.happenings.size).to eq 5
    end

    it "it should add only moments to this window" do
      expect(container.windows.first.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    it "should add a single happening to the second of these window" do
      expect(container.windows.last.happenings.size).to eq 1
    end

    it "should add a window to the second of these windows" do
      expect(container.windows.last.happenings.first).to be_a Dodo::Window
    end

    it "it should add 10 happenings to this window" do
      expect(container.windows.last.happenings.first.happenings.size).to eq 10
    end

    it "it should add only moments to this window" do
      expect(container.windows.last.happenings.first.happenings).to all(be_a Dodo::Moment)
    end

    let(:child_window) { window.happenings.last }
    it "should then add a window to the top level window" do
      expect(child_window).to be_a Dodo::Window
    end

    it "should add 10 happenings to this child_window" do
      expect(child_window.happenings.size).to eq 10
    end

    it "should create 5 authors" do
      expect(authors.size).to eq 5
    end

    it "should create 10 users" do
      expect(users.size).to eq 10
    end

    it 'should create users and authors in order' do
      expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
    end

    it 'should create users and authors over 2 days and 4 hours' do
      diff = users_and_authors.last.created_at - users_and_authors.first.created_at
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

    it "should create all users and authors before any articles" do
      expect(users_and_authors.last.created_at).to be < articles.first.created_at
    end

    it 'should create comments in order' do
      expect(comments.sort_by(&:created_at)).to eq comments
    end

    it "should create a total of 5 articles" do
      expect(articles.size).to eq 5
    end

    it 'should create articles and comments over a period of 10 days' do
      diff = comments.last.created_at - articles.first.created_at
      expect(diff).to be <= 10.days
    end

    it 'should create comments over a period of 10 hours' do
      comments_by_article.each_value do |article_comments|
        diff = article_comments.last.created_at - article_comments.first.created_at
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

    context "with rand achieving its upper bound" do

      # For each of the following tests, it is possible that we could see
      # failures despite there being no errors in the code.  This is because it
      # is allows possible that the random numbers generated by the
      # WindowEnumerator#offsets method all occur in the first half of the unused
      # duration.  Obviously, this probability is significantly reduced if
      # we increase the total number of moments occurring.  The simplest
      # way to do this is to bump the cram factor.
      let(:cram) { 10 }

      it 'should create users and authors over a period greater than 1 days and 2 hours' do
        diff = users_and_authors.last.created_at - users_and_authors.first.created_at
        expect(diff).to be > (1.day + 2.hours)
      end

      it "should create authors over a period greater than 1 day" do
        diff = authors.last.created_at - authors.first.created_at
        expect(diff).to be > 1.day
      end

      it "should create users over a period greater than 1 day" do
        diff = users.last.created_at - users.first.created_at
        expect(diff).to be > 1.day
      end

      it 'should create articles and comments over a period greater than 5 days' do
        diff = comments.last.created_at - articles.first.created_at
        expect(diff).to be > 5.days
      end

      it 'should create the final model after 2 weeks ago' do
        expect(comments.last.created_at).to be > 2.weeks.ago
      end
    end
  end

end
