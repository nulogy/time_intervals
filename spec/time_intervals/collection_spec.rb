require "time_intervals"
require "time"

require "spec_helper"

RSpec.describe TimeIntervals::Collection do
  describe "#initialize" do
    it "accepts no Intervals" do
      expect(TimeIntervals::Collection.new).to be_empty
    end

    it "accepts nil Intervals" do
      expect(TimeIntervals::Collection.new(nil)).to be_empty
    end

    it "accepts empty Intervals" do
      expect(TimeIntervals::Collection.new([])).to be_empty
    end

    it "accepts single Intervals" do
      expect(TimeIntervals::Collection.new(create_interval("03:15:00", "04:30:00")).length).to eq(1)
    end

    it "accepts array of multiple Intervals" do
      expect(TimeIntervals::Collection.new([
        create_interval("03:15:00", "04:30:00"),
        create_interval("05:00:00", "06:00:00")
      ]).length).to eq(2)
    end

    it "accepts another TimeIntervals::Collection" do
      another = create_collection([
        ["03:15:00", "04:30:00"],
        ["05:00:00", "06:00:00"]
      ])

      expect(TimeIntervals::Collection.new(another).length).to eq(2)
    end
  end

  describe "#all_intervals_within?" do
    it "when empty" do
      subject = create_subject([])

      bounding_interval = create_interval("03:15:00", "04:30:00")

      expect(subject.all_intervals_within?(bounding_interval)).to be(true)
    end

    it "for a single Interval" do
      subject = create_subject([
        ["03:15:00", "04:00:00"]
      ])

      bounding_interval = create_interval("03:15:00", "04:30:00")

      expect(subject.all_intervals_within?(bounding_interval)).to be(true)
    end

    it "for a at least one Interval prior to bounding Interval" do
      subject = create_subject([
        ["03:00:00", "03:30:00"],
        ["03:45:00", "04:00:00"]
      ])

      bounding_interval = create_interval("03:15:00", "04:30:00")

      expect(subject.all_intervals_within?(bounding_interval)).to be(false)
    end

    it "for a at least one Interval subsequent to bounding Interval" do
      subject = create_subject([
        ["03:15:00", "04:00:00"],
        ["04:15:00", "04:35:00"]
      ])

      bounding_interval = create_interval("03:15:00", "04:30:00")

      expect(subject.all_intervals_within?(bounding_interval)).to be(false)
    end
  end

  describe "#has_overlapping_intervals?" do
    it "when empty" do
      subject = create_subject([])

      expect(subject.has_overlapping_intervals?).to be(false)
    end

    it "for a single Interval" do
      subject = create_subject([
        ["00:00:00", "02:00:00"]
      ])

      expect(subject.has_overlapping_intervals?).to be(false)
    end

    it "for disjoint Intervals" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["04:00:00", "05:00:00"]
      ])

      expect(subject.has_overlapping_intervals?).to be(false)
    end

    it "for overlapping Intervals" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["01:00:00", "02:00:00"],
        ["03:00:00", "04:00:00"]
      ])

      expect(subject.has_overlapping_intervals?).to be(true)
    end
  end

  describe "#coalesce" do
    it "when empty" do
      subject = create_subject([])

      expect(subject.coalesce).to be_empty
    end

    it "for a single Interval" do
      subject = create_subject([
        ["00:00:00", "02:00:00"]
      ])

      expect(subject.coalesce).to eq(subject)
    end

    it "for disjoint Intervals" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["04:00:00", "05:00:00"]
      ])

      expect(subject.coalesce).to eq(subject)
    end

    it "identical overlapping Intervals" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["00:00:00", "02:00:00"],
        ["03:00:00", "04:00:00"]
      ])

      expected = create_collection([
        ["00:00:00", "02:00:00"],
        ["03:00:00", "04:00:00"]
      ])

      expect(subject.coalesce).to eq(expected)
    end

    it "contained overlapping Intervals" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["00:30:00", "01:30:00"],
        ["03:00:00", "04:00:00"]
      ])

      expected = create_collection([
        ["00:00:00", "02:00:00"],
        ["03:00:00", "04:00:00"]
      ])

      expect(subject.coalesce).to eq(expected)
    end

    it "contained overlapping Intervals into one Interval" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["00:30:00", "01:30:00"],
        ["01:00:00", "03:00:00"],
        ["01:00:00", "04:00:00"]
      ])

      expected = create_collection([
        ["00:00:00", "04:00:00"]
      ])

      expect(subject.coalesce).to eq(expected)
    end

    it "adjacent Intervals into one Interval" do
      subject = create_subject([
        ["00:00:00", "02:00:00"],
        ["02:00:00", "03:00:00"],
        ["03:00:00", "04:00:00"]
      ])

      expected = create_collection([
        ["00:00:00", "04:00:00"]
      ])

      expect(subject.coalesce).to eq(expected)
    end
  end

  describe "#intersect" do
    subject do
      create_subject([
        ["00:00:00", "00:09:00"],
        ["00:06:00", "00:13:00"],
        ["00:13:00", "00:19:00"],
        ["00:23:00", "00:32:00"],
        ["00:28:00", "00:36:00"]
      ])
    end

    it "nil intersections" do
      expect(subject.intersect(nil)).to be_empty
    end

    it "no intersections" do
      expect(subject.intersect([])).to be_empty
    end

    it "empty intersection" do
      intersection = create_interval("00:02:00", "00:02:00")

      expected = create_collection([
        ["00:02:00", "00:02:00"]
      ])

      expect(subject.intersect(intersection)).to eq(expected)
    end

    it "single Interval intersection" do
      intersection = create_interval("00:02:00", "00:07:00")

      expected = create_collection([
        ["00:02:00", "00:07:00"],
        ["00:06:00", "00:07:00"]
      ])

      expect(subject.intersect(intersection)).to eq(expected)
    end

    it "multiple Intervals intersection" do
      intersection = create_collection([
        ["00:10:00", "00:25:00"],
        ["00:27:00", "00:35:00"]
      ])

      expected = create_collection([
        ["00:10:00", "00:13:00"],
        ["00:13:00", "00:19:00"],
        ["00:23:00", "00:25:00"],
        ["00:27:00", "00:32:00"],
        ["00:28:00", "00:35:00"]
      ])

      expect(subject.intersect(intersection)).to eq(expected)
    end
  end

  describe "#intersect with a single Intervals intersection" do
    context "with overlapping TimeIntervals" do
      subject {
        create_subject([
          ["00:30:00", "02:00:00"],
          ["01:00:00", "04:00:00"]
        ])
      }

      it "when partially intersecting first" do
        intersect_with = create_interval("00:00:00", "01:00:00")

        expected = create_collection([
          ["00:30:00", "01:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end

      it "when identical to first" do
        intersect_with = create_interval("00:30:00", "02:00:00")

        expected = create_collection([
          ["00:30:00", "02:00:00"],
          ["01:00:00", "02:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end

      it "when partially intersecting both" do
        intersect_with = create_interval("01:00:00", "02:30:00")

        expected = create_collection([
          ["01:00:00", "02:30:00"],
          ["01:00:00", "02:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end
    end

    context "with disjoint Intervals" do
      subject {
        create_subject([
          ["00:30:00", "02:00:00"],
          ["03:00:00", "04:00:00"]
        ])
      }

      it "when partially intersecting first" do
        intersect_with = create_interval("00:00:00", "01:00:00")

        expected = create_collection([
          ["00:30:00", "01:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end

      it "when fully intersecting first" do
        intersect_with = create_interval("00:30:00", "02:30:00")

        expected = create_collection([
          ["00:30:00", "02:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end

      it "when partially intersecting both" do
        intersect_with = create_interval("01:00:00", "03:30:00")

        expected = create_collection([
          ["01:00:00", "02:00:00"],
          ["03:00:00", "03:30:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end

      it "when partially intersecting second" do
        intersect_with = create_interval("03:15:00", "04:30:00")

        expected = create_collection([
          ["03:15:00", "04:00:00"]
        ])

        expect(subject.intersect(intersect_with)).to eq(expected)
      end
    end
  end

  describe "#length_in_seconds" do
    it "when empty" do
      subject = create_subject([])

      expect(subject.length_in_seconds).to eq(0)
    end

    it "for multiple Intervals" do
      subject = create_subject(
        [                           # Seconds
          ["00:00:00", "00:00:30"], #   30
          ["00:00:00", "00:01:00"], #   60
          ["00:00:10", "00:00:25"]  #   15
        ]
      )

      expect(subject.length_in_seconds).to eq(105)
    end
  end

  describe "#length_in_hours" do
    it "for multiple Intervals" do
      subject = create_subject(
        [                           # Minutes
          ["00:00:00", "00:30:00"], #   30
          ["00:00:00", "01:00:00"], #   60
          ["00:10:00", "00:25:00"]  #   15
        ]
      )

      expect(subject.length_in_hours).to eq(1.75)
    end
  end

  describe ".partition count" do
    it "generates a histogram of how many Intervals overlap in any period" do
      subject = create_subject([
        ["00:00:00", "00:30:00"],
        ["00:00:00", "01:00:00"],
        ["00:10:00", "00:25:00"]
      ])

      expected = create_collection([
        ["00:00:00", "00:10:00"],
        ["00:10:00", "00:25:00"],
        ["00:25:00", "00:30:00"],
        ["00:30:00", "01:00:00"]
      ])
      expected_counts = [2, 3, 2, 1]

      expect(subject.partition_count).to eq(expected.zip(expected_counts))
    end
  end

  def create_collection(specification)
    TimeIntervals::Collection.new(specification.map { |(s, e)| create_interval(s, e) })
  end

  alias_method :create_subject, :create_collection

  def create_interval(started_at, ended_at)
    TimeIntervals::Interval.new(as_time(started_at), as_time(ended_at))
  end

  def as_time(time_component)
    Time.parse("2014-06-19T#{time_component}")
  end
end
