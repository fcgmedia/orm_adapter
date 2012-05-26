require 'spec_helper'
require 'orm_adapter/example_app_shared'

if !defined?(Dynamoid)
  puts "** require 'dynamoid' to run the specs in #{__FILE__}"
else
  Dynamoid.configure do |config|
    config.adapter = 'local'
    config.namespace = 'orm_adapter_spec'
  end

  module DynamoidOrmSpec
    class User
      include Dynamoid::Document
      field :name
      field :rating
      has_many :notes, :class_name => 'DynamoidOrmSpec::Note'
    end

    class Note
      include Dynamoid::Document
      field :body, :default => "made by orm"
      belongs_to :owner, :class_name => 'DynamoidOrmSpec::User'
    end

    # here be the specs!
    describe Dynamoid::Document::OrmAdapter do
      before do
        User.all.each{|r| r.delete }
        Note.all.each{|r| r.delete }
      end

      describe "the OrmAdapter class" do
        subject { Dynamoid::Document::OrmAdapter }

        specify "#model_classes should return all document classes" do
          (subject.model_classes & [User, Note]).to_set.should == [User, Note].to_set
        end
      end

      it_should_behave_like "example app with orm_adapter" do
        let(:user_class) { User }
        let(:note_class) { Note }
      end
    end
  end
end
