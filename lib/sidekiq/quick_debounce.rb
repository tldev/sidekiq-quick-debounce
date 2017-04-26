require 'sidekiq/api'

module Sidekiq
  class QuickDebounce
    CANCEL_EXPIRATION_BUFFER = 60 * 60 * 24

    def call(worker, msg, _queue, redis_pool = nil)
      @worker = worker.is_a?(String) ? worker.constantize : worker
      @msg = msg

      return yield unless quick_debounce?

      block = proc do |conn|
        fetch_current_options(conn)
        if current_jid
          self.class.cancel!(
            conn: conn,
            jid: current_jid,
            expires_at: current_runs_at + CANCEL_EXPIRATION_BUFFER,
          )
        end
        jid = yield
        update_options(conn, jid['jid'], @msg['at'])
        jid
      end

      if redis_pool
        redis_pool.with(&block)
      else
        Sidekiq.redis(&block)
      end
    end

    private

    def quick_debounce?
      (delayed? && quick_debounce_options) || false
    end

    def quick_debounce_options
      @quick_debounce_options ||= @worker.get_sidekiq_options['quick_debounce']
    end

    def update_options(conn, jid, runs_at)
      # Don't debounce next job if current job is running right now
      return if runs_at <= Time.now.to_f

      conn.setex(
        worker_key,
        runs_at.to_i - Time.now.to_i,
        { jid: jid, runs_at: runs_at }.to_json,
      )
    end

    def fetch_current_options(conn)
      @options ||= begin
        options = conn.get(worker_key)
        options ? JSON.parse(options) : {}
      end
    end

    def current_jid
      @options['jid']
    end

    def current_runs_at
      Time.at(@options['runs_at']) if @options['runs_at']
    end

    def worker_key
      @worker_key ||= begin
        hash = Digest::MD5.hexdigest(@msg['args'].to_json)
        "sidekiq_quick_debounce:#{@worker.name}:#{hash}"
      end
    end

    def delayed?
      !@msg['at'].nil?
    end

    class << self
      def cancelled?(jid:)
        Sidekiq.redis { |conn| conn.exists(cancel_namespace_key(jid)) }
      end

      def cancel!(conn:, jid:, expires_at:)
        conn.setex(cancel_namespace_key(jid), expires_at.to_i - Time.now.to_i, 1)
      end

      private

      def cancel_namespace_key(key)
        "sidekiq_quick_debounce:cancelled:#{key}"
      end
    end
  end
end
