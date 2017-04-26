require 'spec_helper'
require 'sidekiq/quick_debounce'
require 'sidekiq'

class QuickDebouncedWorker
  include Sidekiq::Worker

  sidekiq_options quick_debounce: true

  def perform(_a, _b); end
end

describe Sidekiq::QuickDebounce do
  after do
    Sidekiq.redis(&:flushdb)
  end

  let(:set) { Sidekiq::ScheduledSet.new }

  it 'queues a job normally at first' do
    QuickDebouncedWorker.perform_in(60, 'foo', 'bar')
    set.size.must_equal 1, 'set.size must be 1'
  end

  it 'cancels existing job for repeat jobs within the debounce time' do
    jid = QuickDebouncedWorker.perform_in(60, 'foo', 'bar')
    QuickDebouncedWorker.perform_in(60, 'foo', 'bar')
    Sidekiq::QuickDebounce.cancelled?(jid: jid).must_equal true, 'first jid must be cancelled'
    set.size.must_equal 2, 'set.size must be 2'
  end

  it 'debounces jobs based on their arguments' do
    jid = QuickDebouncedWorker.perform_in(60, 'boo', 'far')
    QuickDebouncedWorker.perform_in(60, 'foo', 'bar')
    Sidekiq::QuickDebounce.cancelled?(jid: jid).must_equal false, 'first jid must not be cancelled'
    set.size.must_equal 2, 'set.size must be 2'
  end

  it 'creates the job immediately when given an instant job' do
    QuickDebouncedWorker.perform_async('foo', 'bar')
    set.size.must_equal 0, 'set.size must be 0'
  end
end
