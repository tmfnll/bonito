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

  class Context
    def initialize
      @authors = []
      @articles = []
      @users = []
      @comments = []
      @users_and_authors = []
    end
  end
  let(:context) { Context.new }

  let(:window) do
    Dodo.over 1.week do

      simultaneously over: 1.day do
        repeat times: 5 do
          please do
            name = Faker::Name.name
            author = Author.new(name)
            @authors << author
            @users_and_authors << author
          end
        end
      end.also over: 1.day, after: 2.hours do

        repeat times: 10 do
          please do
            name = Faker::Name.name
            email = Faker::Internet.safe_email(name)
            user = User.new(name, email)
            @users << user
            @users_and_authors << user
          end
        end
      end

      repeat times: 5, over: 5.days do
        please do
          author = @authors.sample
          title = Faker::Company.bs
          @article = Article.new(title, author)
         @articles << @article
        end

        repeat times: 2, over: 5.hour do
          please do
            user = @users.sample
            content = Faker::Lorem.sentence
            @comments << Comment.new(content, @article, user)
          end
        end
      end
    end
  end

  let(:logger) { Logger.new STDOUT }
  let(:progress) { Dodo::ProgressLogger.new logger }
  let(:runner) { Dodo::Runner.new progress: progress }

  let(:users_and_authors) { context.instance_variable_get(:@users_and_authors) }
  let(:authors) { context.instance_variable_get(:@authors) }
  let(:users) { context.instance_variable_get(:@users) }
  let(:articles) { context.instance_variable_get(:@articles) }
  let(:comments) { context.instance_variable_get(:@comments) }
  let(:comments_by_article) { comments.group_by { |comment| comment.article } }

  subject! { runner.call window, 3.weeks.ago, context }


  it 'should complete successfully' do
  end

  it 'should create users and authors in order' do
    expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
  end

  it 'should create users and authors over 1 day' do
    diff = users_and_authors.last.created_at - users_and_authors.last.created_at
    expect(diff).to be <= (1.day + 2.hours)
  end

  it 'should create authors over 1 day' do
    diff = authors.last.created_at - authors.last.created_at
    expect(diff).to be <= 1.day
  end

  it 'should create users and authors over 1 day' do
    diff = users.last.created_at - users.last.created_at
    expect(diff).to be <= 1.day
  end

  it "should create all users and authors before any articles" do
    expect(users_and_authors.last.created_at).to be < articles.first.created_at
  end

  it 'should create comments in order' do
    expect(comments.sort_by(&:created_at)).to eq comments
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
