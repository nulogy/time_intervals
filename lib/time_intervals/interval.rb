#
# Represents an interval in time.
#
# Each TimeIntervals is interpreted as: [started_at, ended_at). That is, include
# the started_at time and exclude the ended_at time.
#
# Note: both started_at and ended_at are values in seconds without the fractional
# part that represents microseconds.
#

module TimeIntervals
  class Interval
    include Comparable

    attr_reader :started_at, :ended_at
    alias_method :start_at, :started_at
    alias_method :end_at, :ended_at

    def self.create(interval)
      new(interval.started_at, interval.ended_at)
    end

    def initialize(started_at, ended_at)
      raise "Invalid interval" if started_at.nil? || ended_at.nil?

      @started_at = as_seconds(started_at)
      @ended_at = as_seconds(ended_at)

      raise "Invalid interval: #{self}" if @ended_at < @started_at
    end

    def length_in_seconds
      ended_at - started_at
    end

    def after?(other)
      other.ended_at <= started_at
    end

    def before?(other)
      ended_at <= other.started_at
    end

    def disjoint?(other)
      before?(other) || after?(other)
    end

    def overlaps?(other)
      !disjoint?(other)
    end

    def overlap_duration_in_seconds(other)
      return 0 if disjoint?(other)

      [other.ended_at, ended_at].min - [other.started_at, started_at].max
    end

    def include?(time)
      started_at <= time && time < ended_at
    end

    def to_s
      "[#{format(started_at)}, #{format(ended_at)}]"
    end

    def <=>(other)
      comparison = started_at <=> other.started_at
      comparison.zero? ? (other.ended_at <=> ended_at) : comparison
    end

    def ==(other)
      other.class == self.class && other.state == state
    end

    alias_method :eql?, :==

    def hash
      state.hash
    end

    protected

    def state
      [started_at, ended_at]
    end

    private

    # Round any fractional seconds.
    #
    def as_seconds(time_value)
      time_value.round
    end

    def format(time_value)
      time_value.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
