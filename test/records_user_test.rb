require File.dirname(__FILE__) + '/test_helper'

class Article
  attr_accessor :creator, :updater, :deleter
  def precreate; end 
  def predestroy; end 
  def preupdate; end

  def save; true ; end
  def update_attributes(*a); true ; end
  def destroy; true ; end
end

class Comment
  attr_accessor :editor, :commentor, :spamchecker

  def save; true ; end
  def update_attributes(*a); true ; end
  def destroy; true ; end
end

class Link
  def save; true ; end
  def update_attributes(*a); true ; end
  def destroy; true ; end
end





class UserstampDefaultsTest < ActionController::TestCase
  class ArticlesController < InheritedResources::Base
    records_user
  protected
    def create_resource(obj)
      obj.precreate
      super
    end

    def update_resource(obj, params)
      obj.preupdate
      super
    end

    def destroy_resource(obj)
      obj.predestroy
      super
    end

    def current_user
      "Joe"
    end
  end

  tests ArticlesController

  def setup
    @article = Article.new
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
    Article.stubs(:new).returns(@article)
    Article.stubs(:find).returns(@article)
  end

  def test_assigns_creator_and_updater_on_create
    post :create
    assert_equal('Joe', assigns(:article).creator)
    assert_equal('Joe', assigns(:article).updater)
    assert_equal(nil, assigns(:article).deleter)
  end

  def test_create_inherits_cleanly
    @article.expects(:precreate)
    @article.expects(:save).returns true

    post :create
  end

  def test_assigns_only_updater_on_update
    @article.creator = "Bob"
    post :update, :id => '12'
    assert_equal('Bob', assigns(:article).creator)
    assert_equal('Joe', assigns(:article).updater)
    assert_equal(nil,   assigns(:article).deleter)
  end

  def test_update_inherits_cleanly
    Article.expects(:find).with("12").returns @article

    @article.expects(:preupdate)
    @article.expects(:update_attributes).returns(true)
    post :update, :id => '12'
  end

  def test_assigns_deleter_on_delete
    @article.creator = "Bob"
    @article.updater = "Sue"
    delete :destroy, :id => '12'
    assert_equal("Bob", assigns(:article).creator)
    assert_equal("Sue", assigns(:article).updater)
    assert_equal("Joe", assigns(:article).deleter)
  end

  def test_destroy_inherits_cleanly
    Article.expects(:find).with("12").returns @article
    @article.expects(:predestroy)
    @article.expects(:destroy).returns(true)
    delete :destroy, :id => '12'
  end
end

class UserstampRedefinedTest < ActionController::TestCase
  class CommentsController < InheritedResources::Base
    records_user :updater => :editor, :creator => :commentor, :deleter => :spamchecker, 
      :current_user => :logged_in_as

    def logged_in_as
      "Joe"
    end
  end

  tests CommentsController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')

    @comment = Comment.new
    [:new, :find].each{|m| Comment.stubs(m).returns @comment }
  end

  def test_create_assigns_correctly
    post :create
    assert_equal("Joe", assigns(:comment).editor)
    assert_equal("Joe", assigns(:comment).commentor)
    assert_equal(nil,   assigns(:comment).spamchecker)
  end

  def test_update_assigns_correctly
    put :update, :id => "2"
    assert_equal(nil,   assigns(:comment).commentor)
    assert_equal("Joe", assigns(:comment).editor)
    assert_equal(nil,   assigns(:comment).spamchecker)
  end

  def test_destroy_assigns_correctly
    put :destroy, :id => "2"
    assert_equal(nil,   assigns(:comment).commentor)
    assert_equal(nil,   assigns(:comment).editor)
    assert_equal("Joe", assigns(:comment).spamchecker)
  end
end

class UserstampIgnoresUntrackedValues < ActionController::TestCase
  class LinksController < InheritedResources::Base
    records_user
    def current_user
      "Joe"
    end
  end

  tests LinksController
  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
    @link = Link.new
    [:new, :find].each{|m| Link.stubs(m).returns @link}
  end

  def test_does_not_attempt_to_assign_missing_creator_attribute
    post :create
  end

  def test_does_not_attempt_to_assign_missing_updater_attribute
    put :update, :id => '12'
  end

  def test_does_not_attempt_to_assign_missing_deleter_attribute
    delete :destroy, :id => '12'
  end
end
