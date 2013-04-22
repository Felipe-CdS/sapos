require "spec_helper"

describe PhaseDuration do
  let(:phase_duration) { PhaseDuration.new }
  subject { phase_duration }
  describe "Validations" do
    describe "phase" do
      context "should be valid when" do
        it "phase is not null" do
          phase_duration.phase = Phase.new
          phase_duration.should have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase is null" do
          phase_duration.phase = nil
          phase_duration.should have_error(:blank).on :phase
        end
      end
    end
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          phase_duration.level = Level.new
          phase_duration.should have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          phase_duration.level = nil
          phase_duration.should have_error(:blank).on :level
        end
      end
    end
    describe "deadline" do
      context "should be valid when" do
        it "is equal or greater than one day" do
          phase_duration.deadline_months = 0
          phase_duration.deadline_semesters = 0
          phase_duration.deadline_days = 1
          phase_duration.should have(0).errors_on :deadline
        end
      end
      context "should have error blank_duration when" do
        it "equals 0" do
          phase_duration.deadline_days = 0
          phase_duration.deadline_months = 0
          phase_duration.deadline_semesters = nil
          phase_duration.should have_error(:blank_deadline).on :deadline
        end
      end
    end
  end
end