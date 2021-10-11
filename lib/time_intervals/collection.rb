require "forwardable"

#
# Represents an ordered collection of TimeIntervals::Intervals.
#
module TimeIntervals
  class Collection
    include Enumerable
    extend Forwardable

    ONE_HOUR_IN_SECONDS = 60 * 60

    def_delegators :time_intervals, :[], :each, :empty?, :hash, :length, :size, :to_ary

    attr_reader :time_intervals

    def self.wrap(intervals)
      time_intervals = intervals.map { |interval| Interval.new(interval.started_at, interval.ended_at) }
      new(time_intervals)
    end

    def initialize(time_intervals = [])
      @time_intervals = Array(time_intervals).sort
    end

    # Returns true if all of the contained TimeIntervals::Intervals are wholly contained
    # within the bounding interval.
    def all_intervals_within?(bounding_interval)
      length_in_seconds == intersect(bounding_interval).length_in_seconds
    end

    # Returns true if any of the contained TimeIntervals::Intervals overlap.
    def has_overlapping_intervals? # rubocop:disable Naming/PredicateName
      length_in_seconds != coalesce.length_in_seconds
    end

    # Returns a new coalesced collection of TimeIntervals::Intervals where any that
    # overlap or are adjacent are combined into a single TimeIntervals::Interval.
    #
    # Given these TimeIntervals::Intervals in the collection:
    #
    # [--------)
    #       [------)
    #              [-----)   [-------)
    #                             [-------)
    #
    # Calling #coalesce returns a TimeIntervals::Collection containing
    # these TimeIntervals::Intervals:
    #
    # [------------------)   [------------)
    #
    def coalesce
      return self if empty?

      coalescing = Interval.create(first)

      result = each_with_object([]) do |current, memo|
        if coalescing.ended_at < current.started_at
          memo << coalescing
          coalescing = Interval.create(current)
        else
          coalescing = Interval.new(
            coalescing.started_at,
            [coalescing.ended_at, current.ended_at].max
          )
        end
      end

      result << Interval.create(coalescing)

      Collection.new(result)
    end

    # Returns a new collection of TimeIntervals::Intervals that contains only
    # intersections with the specified intersections: either a nil,
    # a single TimeIntervals::Interval, or a TimeIntervals::Collection.
    #
    # Note: the intersections are assumed to be disjoint. That is,
    # none of the TimeIntervals::Intervals in intersections overlap.
    #
    # Given these TimeIntervals::Intervals in the collection:
    #
    # [--------)
    #       [------)
    #              [-----)   [-------)
    #                             [-------)
    #
    # Calling #intersect with these TimeIntervals::Intervals
    #
    #           [--------------) [------)
    #
    # returns a TimeIntervals::Collection containing these TimeIntervals::Intervals:
    #
    #           [--)
    #              [-----)   [-) [---)
    #                             [-----)
    #
    def intersect(intersections)
      result = Array(intersections).each_with_object([]) do |intersection, memo|
        memo.concat(intersect_with_time_interval(intersection))
      end

      Collection.new(result)
    end

    def partition_count
      partition_intervals = partition

      intersect_count(partition_intervals)
    end

    # Returns a new collection of TimeIntervals::Intervals that are partitions of
    # the original collection.
    #
    # Given the upper TimeIntervals::Intervals, #partition returns the lower TimeIntervals::Intervals:
    #
    # [--------)   [-----)   [---)
    # |     [------)     |   |   |
    # |     |  | [----)  |   |   |
    # |     |  | | |  |  |   |   |
    # |     |  | | |  |  |   |   |
    # [-----)  [-) [--)  [---)   |
    #       [--) [-)  [--)   [---)
    #
    def partition
      time_points = @time_intervals.flat_map { |i| [i.started_at, i.ended_at] }.uniq.sort
      start_time_points = time_points[0..-2]
      end_time_points = time_points[1..-1]
      raw_intervals = start_time_points.zip(end_time_points)
      Collection.new(raw_intervals.map { |r| Interval.new(*r) })
    end

    # Counts the number of TimeIntervals::Intervals that intersect with the given
    # collection of TimeIntervals::Intervals.
    #
    # Returns a list of [TimeIntervals::Interval, count] tuples. The TimeIntervals::Intervals in the result are
    # the TimeIntervals::Intervals from the argument.
    def intersect_count(intersections)
      counts = intersections.map { |slice| intersect_with_time_interval(slice).length }
      intersections.zip(counts)
    end

    # The sum of the lengths of the TimeIntervals::Intervals in the collection as hours.
    #
    def length_in_hours
      length_in_seconds.to_f / ONE_HOUR_IN_SECONDS
    end

    # The sum of the lengths of the TimeIntervals::Intervals in the collection as seconds.
    #
    def length_in_seconds
      time_intervals.reduce(0) { |total, time_intervals| total + time_intervals.length_in_seconds }
    end

    def ==(other)
      other.class == self.class && other.time_intervals == time_intervals
    end
    alias_method :eql?, :==

    private

    # Returns an array of TimeIntervals::Intervals that contains only intersections
    # with the specified intersecting TimeIntervals::Interval.
    #
    # Given these TimeIntervals::Intervals in the collection:
    #
    # [--------)
    #       [------)
    #              [-----)   [-------)
    #                             [-------)
    #
    # Calling #intersect_with_time_interval with this TimeIntervals::Interval
    #
    #           [---------------)
    #
    # returns this array of TimeIntervals::Intervals:
    #
    #           [--)
    #              [-----)   [--)
    #
    def intersect_with_time_interval(intersecting)
      each_with_object([]) do |current, memo|
        next unless intersecting.overlaps?(current)

        memo << Interval.new(
          [intersecting.started_at, current.started_at].max,
          [intersecting.ended_at, current.ended_at].min
        )
      end
    end
  end
end
