# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingConfigsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::RankingConfig" do |config|
    # config.list.sorting = { name: "ASC" }
    config.create.label = :create_ranking_config_label
    columns = [
      :name, :ranking_columns, :ranking_groups, :ranking_processes
    ]

    config.columns = columns
    config.columns[:ranking_columns].show_blank_record = false
    config.columns[:ranking_groups].show_blank_record = false
    config.columns[:ranking_processes].show_blank_record = false

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name],
    full_text_search: true,
    model: "Admissions::RankingConfig"
  )
end
