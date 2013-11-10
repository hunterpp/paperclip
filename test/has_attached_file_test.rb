require './test/helper'
require 'paperclip/has_attached_file'

class HasAttachedFileTest < Test::Unit::TestCase
  context '#define_on' do
    should 'define a setter on the class object' do
      assert_adding_attachment('avatar').defines_method('avatar=')
    end

    should 'define a getter on the class object' do
      assert_adding_attachment('avatar').defines_method('avatar')
    end

    should 'define a query on the class object' do
      assert_adding_attachment('avatar').defines_method('avatar?')
    end

    should 'define a method on the class to get all of its attachments' do
      assert_adding_attachment('avatar').defines_class_method('attachment_definitions')
    end

    should 'flush errors as part of validations' do
      assert_adding_attachment('avatar').defines_validation
    end

    should 'register the attachment with Paperclip::AttachmentRegistry' do
      assert_adding_attachment('avatar').registers_attachment
    end

    should 'define an after_save callback' do
      assert_adding_attachment('avatar').defines_callback('after_save')
    end

    should 'define a before_destroy callback' do
      assert_adding_attachment('avatar').defines_callback('before_destroy')
    end

    should 'define an after_commit callback' do
      assert_adding_attachment('avatar').defines_callback('after_commit')
    end

    should 'define the Paperclip-specific callbacks' do
      assert_adding_attachment('avatar').defines_callback('define_paperclip_callbacks')
    end

    should 'define Mongoid fields on Mongoid objects' do
      assert_adding_attachment('avatar').defines_mongoid_field('avatar_file_name', String)
      assert_adding_attachment('avatar').defines_mongoid_field('avatar_content_type', String)
      assert_adding_attachment('avatar').defines_mongoid_field('avatar_file_size', Integer)
      assert_adding_attachment('avatar').defines_mongoid_field('avatar_updated_at', Time)
    end

    should 'not define Mongoid fields on ActiveRecord objects' do
      assert_adding_attachment('avatar').not_define_mongoid_fields_on_active_record
    end
  end

  private

  def assert_adding_attachment(attachment_name)
    AttachmentAdder.new(attachment_name)
  end

  class AttachmentAdder
    include Mocha::API
    include Test::Unit::Assertions

    def initialize(attachment_name)
      @attachment_name = attachment_name
    end

    def defines_method(method_name)
      a_class = stub_class

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {})

      assert_received(a_class, :define_method) do |expect|
        expect.with(method_name)
      end
    end

    def defines_class_method(method_name)
      a_class = stub_class
      a_class.class.stubs(:define_method)

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {})

      assert_received(a_class, :extend) do |expect|
        expect.with(Paperclip::HasAttachedFile::ClassMethods)
      end
    end

    def defines_validation
      a_class = stub_class

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {})

      assert_received(a_class, :validates_each) do |expect|
        expect.with(@attachment_name)
      end
    end

    def registers_attachment
      a_class = stub_class
      Paperclip::AttachmentRegistry.stubs(:register)

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {size: 1})

      assert_received(Paperclip::AttachmentRegistry, :register) do |expect|
        expect.with(a_class, @attachment_name, {size: 1})
      end
    end

    def defines_callback(callback_name)
      a_class = stub_class

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {})

      assert_received(a_class, callback_name.to_sym)
    end

    def defines_mongoid_field(field, type)
      m_class = stub_mongoid_class

      Paperclip::HasAttachedFile.define_on(m_class, @attachment_name, {})

      assert_received(m_class, :field) do |expect|
        expect.with(field.to_sym, :type => type)
      end
    end

    def not_define_mongoid_fields_on_active_record
      a_class = stub_class

      Paperclip::HasAttachedFile.define_on(a_class, @attachment_name, {})

      assert !have_received(:field).matches?(a_class)
    end

    private

    def stub_class
      stub('class',
           validates_each: nil,
           define_method: nil,
           after_save: nil,
           before_destroy: nil,
           after_commit: nil,
           define_paperclip_callbacks: nil,
           extend: nil,
           included_modules: [],
           name: 'Billy')
    end

    def stub_mongoid_class
      stub('class',
           validates_each: nil,
           define_method: nil,
           after_save: nil,
           before_destroy: nil,
           after_commit: nil,
           define_paperclip_callbacks: nil,
           extend: nil,
           field: nil,
           included_modules: [::Mongoid::Document],
           name: 'Mongo')
    end
  end
end
