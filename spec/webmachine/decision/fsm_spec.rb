require 'spec_helper'

describe Webmachine::Decision::FSM do
  include_context 'default resource'

  subject { described_class.new(resource, request, response) }

  describe 'handling of exceptions from decision methods' do
    let(:exception) { Exception.new }

    before do
      subject.stub(Webmachine::Decision::Flow::START) { raise exception }
    end

    it 'calls resource.handle_exception' do
      resource.should_receive(:handle_exception).with(exception)
      subject.run
    end

    it 'calls resource.finish_request' do
      resource.should_receive(:finish_request)
      subject.run
    end
  end

  describe 'handling of exceptions from resource.handle_exception' do
    let(:exception) { Exception.new('an error message') }

    before do
      subject.stub(Webmachine::Decision::Flow::START) { raise }
      resource.stub(:handle_exception) { raise exception }
    end

    it 'does not call resource.handle_exception again' do
      resource.should_receive(:handle_exception).once { raise }
      subject.run
    end

    it 'does not call resource.finish_request' do
      resource.should_not_receive(:finish_request)
      subject.run
    end

    it 'renders an error' do
      Webmachine.
        should_receive(:render_error).
        with(500, request, response, { :message => exception.message })
      subject.run
    end
  end

  describe 'handling of exceptions from resource.finish_request' do
    let(:exception) { Exception.new }

    before do
      resource.stub(:finish_request) { raise exception }
    end

    it 'calls resource.handle_exception' do
      resource.should_receive(:handle_exception).with(exception)
      subject.run
    end

    it 'does not call resource.finish_request again' do
      resource.should_receive(:finish_request).once { raise }
      subject.run
    end
  end

  it "sets the response code before calling finish_request" do
    resource_class.class_eval do
      class << self
        attr_accessor :current_response_code
      end

      def to_html
        201
      end

      def finish_request
        self.class.current_response_code = response.code
      end
    end

    subject.run

    resource_class.current_response_code.should be(201)
  end

  it 'respects a response code set by resource.finish_request' do
    resource_class.class_eval do
      def finish_request
        response.code = 451
      end
    end

    subject.run

    response.code.should be(451)
  end
end
