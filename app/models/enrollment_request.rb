# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequest < ApplicationRecord
  belongs_to :enrollment
  has_many :class_enrollment_requests, :dependent => :destroy
  has_many :course_classes, through: :class_enrollment_requests
  has_many :enrollment_request_comments, :dependent => :destroy

  has_paper_trail

  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => YearSemester::SEMESTERS}
  validates :enrollment, :presence => true
  validates_uniqueness_of :enrollment, :scope => [:year, :semester]
  validates :class_enrollment_requests, :length => { minimum: 1, message: :at_least_one_class}
  
  validate :that_valid_insertion_is_not_set_to_false
  validate :that_valid_removal_is_not_set_to_false

  accepts_nested_attributes_for :class_enrollment_requests, :course_classes

  attr_accessor :valid_insertion, :valid_removal

  def status
    all_effected = true
    all_valid = true
    any_invalid = false
    class_enrollment_requests.each do |cer|
      cer_status = cer.status
      if cer_status != ClassEnrollmentRequest::EFFECTED
        all_effected = false
        all_valid = false if cer_status != ClassEnrollmentRequest::VALID
      end
      if cer_status == ClassEnrollmentRequest::INVALID
        any_invalid = true
      end
    end
    status = ClassEnrollmentRequest::REQUESTED
    status = ClassEnrollmentRequest::VALID if all_valid
    status = ClassEnrollmentRequest::EFFECTED if all_effected
    status = ClassEnrollmentRequest::INVALID if any_invalid
    status
  end

  def self.pendency_condition(user=nil)
    user ||= current_user
    return ["0 = -1"] if user.blank? 
    return ["0 = -1"] if user.cannot?(:read_pendencies, EnrollmentRequest) && user.cannot?(:read_advisement_pendencies, EnrollmentRequest)

    er = EnrollmentRequest.arel_table.dup
    cer = ClassEnrollmentRequest.arel_table
    er.table_alias = 'er'
    check_status = er
      .join(cer)
      .on(cer[:enrollment_request_id].eq(er[:id]))
      .where(cer[:status].eq(ClassEnrollmentRequest::REQUESTED))
    
    return [
      EnrollmentRequest.arel_table[:id].in(check_status.project(er[:id])).to_sql
    ] if user.can?(:read_pendencies, EnrollmentRequest)
    
    return ["0 = -1"] if user.professor.blank?

    check_status = check_status.where(er[:enrollment_id].in(user.professor.enrollments.map(&:id)))
    [EnrollmentRequest.arel_table[:id].in(check_status.project(er[:id])).to_sql]
  end

  def student_change!
    self.last_student_change_at = Time.current
    self.student_view_at = self.last_student_change_at 
  end

  def last_student_read_time
    time_list = [self.created_at]
    time_list << self.last_student_change_at unless self.last_student_change_at.nil? 
    time_list << self.student_view_at unless self.student_view_at.nil?
    time_list.max
  end

  def last_staff_read_time
    time_list = [self.created_at - 1.minute]
    time_list << self.last_staff_change_at unless self.last_staff_change_at.nil? 
    time_list.max
  end

  def student_unread_messages(user=nil)
    user ||= current_user
    comp_time = self.last_student_read_time
    self.enrollment_request_comments.filter { |comment|  comment.updated_at > comp_time && comment.user != user }.count
  end

  def to_label
    "[#{self.year}.#{self.semester}] #{self.enrollment.to_label}"
  end

  def course_class_ids
    self.class_enrollment_requests.collect { |cer| cer.course_class_id }
  end

  def assign_course_class_ids(course_classes, class_schedule=nil)
    # course classes is a list of strings representing course_class ids
    request_change = {
      remove_class_enrollments: [],
      remove_class_enrollment_requests: [],
      insert_class_enrollment_requests: [],
      existing_class_enrollment_requests: [],
    }
    self.valid_removal = true
    self.valid_insertion = true

    prepare_removal_of_course_classes(course_classes, class_schedule, request_change)
    prepare_insertion_of_course_classes(course_classes, class_schedule, request_change)
    request_change
  end

  def valid_request?(request_change)
    self.valid? && request_change[:remove_class_enrollments].all? { |ce| ce.can_destroy? }
  end

  def save_request(request_change)
    if self.valid_request?(request_change)
      ActiveRecord::Base.transaction do
        self.save!
        request_change[:remove_class_enrollments].each do |ce|
          ce.class_enrollment_request = nil
          ce.destroy!
        end
      end
      return true
    end
    false
  end

  def valid_destroy?(class_schedule=nil)
    return false if ! self.can_destroy?
    return false if ! class_schedule.nil? && ! class_schedule.main_enroll_open? && ! class_schedule.adjust_enroll_remove_open?
    return false if self.class_enrollment_requests.any? do |cer|
      if cer.status == ClassEnrollmentRequest::EFFECTED
        next true if ! cer.class_enrollment.can_destroy?
      end
      ! cer.can_destroy?
    end
    true
  end

  def destroy_request(class_schedule=nil)
    if ! self.valid_destroy?(class_schedule)
      errors.add(:base, :impossible_removal)
      return false
    end
    ActiveRecord::Base.transaction do
      self.class_enrollment_requests.each do |cer| 
        if cer.status == ClassEnrollmentRequest::EFFECTED
          class_enrollment = cer.class_enrollment
          cer.destroy!
          class_enrollment.class_enrollment_request = nil
          class_enrollment.destroy!
        end
      end
      self.destroy!
    end
    true
  end

  protected

  def that_valid_insertion_is_not_set_to_false
    return if valid_insertion.nil? || self.valid_insertion

    errors.add(:base, :impossible_insertion)
  end

  def that_valid_removal_is_not_set_to_false
    return if valid_removal.nil? || self.valid_removal

    errors.add(:base, :impossible_removal)
  end

  def prepare_removal_of_course_classes(course_classes, class_schedule, request_change)
    class_enrollment_requests.each do |cer|
      next if course_classes.include? cer.course_class_id.to_s
  
      if class_schedule.blank? || class_schedule.open_for_removing_class_enrollments?
        if cer.status == ClassEnrollmentRequest::EFFECTED
          cer.class_enrollment.mark_for_destruction
          request_change[:remove_class_enrollments] << cer.class_enrollment
        end
        cer.mark_for_destruction
        request_change[:remove_class_enrollment_requests] << cer
      else 
        self.valid_removal = false
      end
    end
  end

  def prepare_insertion_of_course_classes(course_classes, class_schedule, request_change)
    course_classes.each do |course_class_id|
      next if course_class_id.empty?

      attributes = { course_class_id: course_class_id }
      cer = self.class_enrollment_requests.find_by(attributes)
      if cer.present?
        request_change[:existing_class_enrollment_requests] << cer
      else
        if class_schedule.nil? || class_schedule.open_for_inserting_class_enrollments?
          request_change[:insert_class_enrollment_requests] << self.class_enrollment_requests.build(attributes)
        else
          self.valid_insertion = false
        end
      end
    end
  end
end
