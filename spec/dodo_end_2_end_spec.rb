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

        repeat times: rand(10), over: 5.hour do
          please do
            user = @users.sample
            content = Faker::Lorem.sentence
            @comments << Comment.new(content, @article, user)
          end
        end
      end
    end
  end

  # let(:window) do
  #   Dodo.over(1.week) do
  #     repeat times: 6 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     x = 2
  #   end
  # end

  # let(:window) do
  #   Dodo.over(1.week) do
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     over 100_800 do
  #       please do
  #         @authors << Author.new(Faker::Name.name)
  #       end
  #     end
  #     x=2
  #   end
  # end

  let(:logger) { Logger.new STDOUT }
  let(:progress) { Dodo::ProgressLogger.new logger }
  let(:runner) { Dodo::Runner.new progress: progress }
  subject { runner.call window, 3.weeks.ago, context }
  it 'should complete successfully' do
    subject
  end

  it 'should yield users and authors in order' do
    subject
    users_and_authors = context.instance_variable_get(:@users_and_authors)
    expect(users_and_authors.sort_by(&:created_at)).to eq users_and_authors
  end

  it 'should yield comments in order' do
    subject
    comments = context.instance_variable_get(:@comments)
    expect(comments.sort_by(&:created_at)).to eq comments
  end
end
