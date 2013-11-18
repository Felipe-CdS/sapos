# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ThesisDefenseCommitteeParticipationsController < ApplicationController
  authorize_resource

  active_scaffold :"thesis_defense_committee_participation" do |config|
  	columns = [:enrollment, :professor]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:professor].form_ui = :record_select
  end
  record_select
end
