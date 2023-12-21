# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::Ability

  ADMISSION_PROCESS_CONFIG = [
    Admissions::AdmissionProcess,
    Admissions::AdmissionProcessPhase,
  ]

  ADMISSION_FORM_CONFIG = [
    Admissions::FormTemplate, Admissions::FormField,
  ]

  ADMISSION_COMMITTEE = [
    Admissions::AdmissionCommitteeMember, Admissions::AdmissionCommittee,
  ]

  ADMISSION_PHASE = [
    Admissions::AdmissionPhase,
    Admissions::AdmissionPhaseCommittee,
    Admissions::FormCondition
  ]

  ADMISSION_FILLED_MODELS = [
    Admissions::FilledForm, Admissions::FilledFormField,
    Admissions::FilledFormFieldScholarity,
    Admissions::LetterRequest,
  ]

  ADMISSION_FORM_EVALUATION = [
    Admissions::AdmissionPhaseEvaluation, Admissions::AdmissionPhaseResult
  ]

  ADMISSION_APPLICATION = [
    Admissions::AdmissionApplication, Admissions::AdmissionPendency
  ] + ADMISSION_FILLED_MODELS + ADMISSION_FORM_EVALUATION

  ADMISSION_MODELS = (
    ADMISSION_PROCESS_CONFIG +
    ADMISSION_FORM_CONFIG +
    ADMISSION_COMMITTEE +
    ADMISSION_PHASE +
    ADMISSION_APPLICATION
  )

  def initialize_admissions(user, roles)
    if roles[:manager]
      can :undo_consolidation, Admissions::AdmissionApplication
      can :override, Admissions::AdmissionApplication
    end
    if roles[Role::ROLE_ADMINISTRADOR] || roles[Role::ROLE_COORDENACAO]
      can :manage, ADMISSION_MODELS
    end
    if roles[Role::ROLE_SECRETARIA]
      can :manage, ADMISSION_PROCESS_CONFIG
      can :read, ADMISSION_FORM_CONFIG
      can :manage, ADMISSION_COMMITTEE
      can [:read, :update], Admissions::AdmissionApplication
      can :read, ADMISSION_FILLED_MODELS
      can [:read, :destroy], ADMISSION_FORM_EVALUATION
    end
    if roles[Role::ROLE_PROFESSOR]
      application_condition = {
        pendencies: {
          user_id: user.id
        }
      }
      can :read_pendencies, Admissions::AdmissionApplication
      can :read, Admissions::AdmissionApplication, application_condition
      can :update, Admissions::AdmissionApplication, application_condition
      can :read, Admissions::AdmissionPhaseEvaluation, user: user
      can :read, Admissions::LetterRequest,
        admission_application: application_condition
      can :read, Admissions::AdmissionPhaseResult,
        admission_application: application_condition
      can :read, Admissions::FilledForm, admission_phase_evaluation: {
        user: user
      }
      can :read, Admissions::FilledForm, admission_phase_result: {
        admission_application: application_condition
      }
      can :read, Admissions::FilledForm, letter_request: {
        admission_application: application_condition
      }
      can :read, Admissions::FilledForm,
        admission_application: application_condition
    end

    cannot :create, Admissions::AdmissionApplication
    cannot [:create, :update, :destroy], Admissions::AdmissionPendency
    cannot [:create, :update, :destroy], ADMISSION_FILLED_MODELS
    cannot [:create, :update], ADMISSION_FORM_EVALUATION

    can :download, Admissions::FilledFormField
    can :manage, ActiveScaffoldWorkaround
  end
end