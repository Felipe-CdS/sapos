# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariable < ActiveRecord::Base
  attr_accessible :name, :value, :variable

  has_paper_trail

  validates :variable, :presence => true

  after_save :reschedule_notifier

  def reschedule_notifier
    return unless (variable_changed? || value_changed?)
    return unless ['notification_frequency', 'notification_start_at'].include? variable 
    Notifier.instance.start_job(false)
  end

  def self.single_advisor_points
  	config = CustomVariable.find_by_variable(:single_advisor_points)
  	config.nil? ? 1.0 : config.value.to_f 
  end

  def self.multiple_advisor_points
  	config = CustomVariable.find_by_variable(:multiple_advisor_points)
  	config.nil? ? 0.5 : config.value.to_f 
  end

  def self.program_level
    config = CustomVariable.find_by_variable(:program_level)
    config.nil? ? nil : config.value.to_i 
  end

  def self.identity_issuing_country
    config = CustomVariable.find_by_variable(:identity_issuing_country)
    Country.find_by_name(config.nil? ? "Brasil": config.value)
  end

  def self.notification_frequency
    config = CustomVariable.find_by_variable(:notification_frequency)
    config.nil? ? "1d" : config.value.to_s 
  end

  def self.notification_start_at
    config = CustomVariable.find_by_variable(:notification_start_at)
    config.nil? ? "12:00" : config.value.to_s 
  end

  def self.class_schedule_text
    config = CustomVariable.find_by_variable(:class_schedule_text)
    config.nil? ? "" : config.value
  end

  def self.redirect_email
    config = CustomVariable.find_by_variable(:redirect_email)
    config.nil? ? nil : (config.value || '')
  end

  def self.notification_footer
    config = CustomVariable.find_by_variable(:notification_footer)
    config.nil? ? "" : config.value
  end

end
