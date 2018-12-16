require "time_intervals"
require "time"

require "spec_helper"

RSpec.describe TimeIntervals::Interval do
  it "invalid interval" do
    expect { create_time_interval(nil, nil) }.to raise_error("Invalid interval")
    expect { create_time_interval(nil, "00:00:00") }.to raise_error("Invalid interval")
    expect { create_time_interval("00:01:00", nil) }.to raise_error("Invalid interval")
    expect { create_time_interval("00:01:00", "00:00:00") }.to raise_error("Invalid interval: [2014-06-19 00:01:00, 2014-06-19 00:00:00]")
  end

  it "empty interval" do
    expect { create_time_interval("00:01:00", "00:01:00") }.to_not raise_error
  end

  it "computes length in seconds" do
    expect(create_time_interval("00:00:00", "00:00:00").length_in_seconds).to eq(0)
    expect(create_time_interval("00:00:00", "00:00:30").length_in_seconds).to eq(30)
  end

  it "rounds fractional seconds" do
    expect(create_time_interval("00:00:00.025", "00:01:00.875")).to eq(create_time_interval("00:00:00", "00:01:01"))
  end

  it "includes time point" do
    expect(create_time_interval("00:02:00", "00:04:00").include?(time("00:02:00"))).to eq(true)
  end

  it "does not include time point in the future" do
    expect(create_time_interval("00:02:00", "00:04:00").include?(time("00:06:00"))).to eq(false)
  end

  it "does not include time point in the past" do
    expect(create_time_interval("00:02:00", "00:04:00").include?(time("00:01:00"))).to eq(false)
  end

  context "sorting" do
    it "sorts by start time" do
      time_intervals = [
        create_time_interval("00:01:00", "00:04:00"),
        create_time_interval("00:03:00", "00:04:00"),
        create_time_interval("00:02:00", "00:05:00")
      ]

      sorted_time_intervals = time_intervals.sort

      expect(sorted_time_intervals[0]).to eq(create_time_interval("00:01:00", "00:04:00"))
      expect(sorted_time_intervals[1]).to eq(create_time_interval("00:02:00", "00:05:00"))
      expect(sorted_time_intervals[2]).to eq(create_time_interval("00:03:00", "00:04:00"))
    end

    it "sorts by latest end time when start times are identical" do
      time_intervals = [
        create_time_interval("00:01:00", "00:04:00"),
        create_time_interval("00:01:00", "00:05:00"),
        create_time_interval("00:01:00", "00:03:00")
      ]

      sorted_time_intervals = time_intervals.sort

      expect(sorted_time_intervals[0]).to eq(create_time_interval("00:01:00", "00:05:00"))
      expect(sorted_time_intervals[1]).to eq(create_time_interval("00:01:00", "00:04:00"))
      expect(sorted_time_intervals[2]).to eq(create_time_interval("00:01:00", "00:03:00"))
    end
  end

  context "ordering" do
    it "before" do
      expect(create_time_interval("00:01:00", "00:02:00").before?(
        create_time_interval("00:02:00", "00:03:00")
      )).to eq(true)

      expect(create_time_interval("00:01:00", "00:02:00").before?(
        create_time_interval("00:01:40", "00:03:00")
      )).to eq(false)
    end

    it "after" do
      expect(create_time_interval("00:01:00", "00:02:00").after?(
        create_time_interval("00:00:00", "00:01:00")
      )).to eq(true)

      expect(create_time_interval("00:01:00", "00:02:00").after?(
        create_time_interval("00:00:00", "00:01:01")
      )).to eq(false)
    end
  end

  context "geometry" do
    it "disjoint" do
      expect(create_time_interval("00:01:00", "00:02:00").disjoint?(
        create_time_interval("00:02:00", "00:03:00")
      )).to eq(true)

      expect(create_time_interval("00:01:00", "00:02:00").disjoint?(
        create_time_interval("00:01:59", "00:03:00")
      )).to eq(false)

      expect(create_time_interval("00:01:00", "00:02:00").disjoint?(
        create_time_interval("00:00:30", "00:00:45")
      )).to eq(true)
    end

    it "overlap" do
      expect(create_time_interval("00:01:00", "00:02:00").overlaps?(
        create_time_interval("00:02:00", "00:03:00")
      )).to eq(false)

      expect(create_time_interval("00:01:00", "00:02:00").overlaps?(
        create_time_interval("00:01:59", "00:03:00")
      )).to eq(true)
    end
  end

  context "overlap_duration_in_seconds" do
    it "overlaps the end" do
      interval = create_time_interval("00:00:01", "00:00:10")
      overlaps_end = create_time_interval("00:00:06", "00:00:14")

      expect(interval.overlap_duration_in_seconds(overlaps_end)).to eq(4)
    end

    it "overlaps the start" do
      interval = create_time_interval("00:00:01", "00:00:10")
      overlaps_start = create_time_interval("00:00:00", "00:00:03")

      expect(interval.overlap_duration_in_seconds(overlaps_start)).to eq(2)
    end

    it "wholly overlaps" do
      interval = create_time_interval("00:00:01", "00:00:10")
      wholly_overlaps = create_time_interval("00:00:02", "00:00:05")

      expect(interval.overlap_duration_in_seconds(wholly_overlaps)).to eq(3)
    end

    it "does not overlap" do
      interval = create_time_interval("00:00:01", "00:00:10")
      does_not_overlap = create_time_interval("00:00:11", "00:00:12")

      expect(interval.overlap_duration_in_seconds(does_not_overlap)).to eq(0)
    end
  end

  def create_time_interval(started_at, ended_at)
    TimeIntervals::Interval.new(
      started_at.nil? ? nil : time(started_at),
      ended_at.nil? ? nil : time(ended_at)
    )
  end

  def time(time)
    Time.parse("2014-06-19T#{time}")
  end
end
