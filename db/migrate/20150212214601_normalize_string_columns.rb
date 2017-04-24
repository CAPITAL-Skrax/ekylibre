class NormalizeStringColumns < ActiveRecord::Migration
  LIMITS = [
    [:gap_items, [:currency], 3],
    [:crumbs, %i[device_uid nature], 255],
    [:financial_years, [:currency], 3],
    [:financial_years, [:code], 20],
    [:entities, [:country], 2],
    [:entities, [:language], 3],
    [:entities, [:siren], 9],
    [:entities, [:vat_number], 20],
    [:entities, [:activity_code], 30],
    [:entities, %i[deliveries_conditions number], 60],
    [:entities, %i[currency first_name full_name last_name meeting_origin nature picture_content_type picture_file_name type], 255],
    [:imports, %i[archive_content_type archive_file_name nature state], 255],
    [:outgoing_payment_modes, [:name], 50],
    [:product_memberships, %i[nature originator_type], 255],
    [:guide_analysis_points, %i[acceptance_status advice_reference_name reference_name], 255],
    [:product_nature_category_taxations, [:usage], 255],
    [:analysis_items, %i[absolute_measure_value_unit choice_value indicator_datatype indicator_name measure_value_unit], 255],
    [:trackings, %i[name serial], 255],
    [:incoming_deliveries, %i[mode number reference_number], 255],
    [:product_readings, %i[absolute_measure_value_unit choice_value indicator_datatype indicator_name measure_value_unit originator_type], 255],
    [:production_supports, %i[nature production_usage], 255],
    [:guides, %i[frequency name nature reference_name reference_source_content_type reference_source_file_name], 255],
    [:journal_entry_items, %i[absolute_currency currency real_currency], 3],
    [:journal_entry_items, [:letter], 10],
    [:journal_entry_items, [:state], 30],
    [:journal_entry_items, %i[entry_number name], 255],
    [:sequences, %i[name number_format period usage], 255],
    [:accounts, [:last_letter], 10],
    [:accounts, [:number], 20],
    [:accounts, [:name], 200],
    [:accounts, [:label], 255],
    [:intervention_casts, %i[nature reference_name], 255],
    [:intervention_casts, [:roles], 320],
    [:inventories, [:number], 20],
    [:inventories, [:name], 255],
    [:financial_assets, [:currency], 3],
    [:financial_assets, %i[depreciation_method name number], 255],
    [:entity_links, %i[entity_1_role entity_2_role nature], 255],
    [:document_archives, %i[file_content_type file_file_name file_fingerprint], 255],
    [:document_templates, [:language], 3],
    [:document_templates, %i[archiving nature], 60],
    [:document_templates, %i[formats name], 255],
    [:attachments, %i[nature resource_type], 255],
    [:sale_natures, [:currency], 3],
    [:sale_natures, %i[expiration_delay name payment_delay], 255],
    [:analytic_distributions, [:state], 255],
    [:purchase_items, [:currency], 3],
    [:product_junction_ways, %i[nature role], 255],
    [:cash_sessions, [:currency], 3],
    [:guide_analyses, [:acceptance_status], 255],
    [:preferences, [:nature], 60],
    [:preferences, %i[name record_value_type], 255],
    [:outgoing_deliveries, %i[mode number reference_number], 255],
    [:productions, %i[name state working_indicator working_unit], 255],
    [:product_localizations, %i[nature originator_type], 255],
    [:gaps, [:currency], 3],
    [:gaps, %i[direction entity_role number], 255],
    [:sale_items, [:currency], 3],
    [:product_reading_tasks, %i[absolute_measure_value_unit choice_value indicator_datatype indicator_name measure_value_unit originator_type], 255],
    [:catalogs, [:currency], 3],
    [:catalogs, %i[code usage], 20],
    [:catalogs, [:name], 255],
    [:campaigns, [:number], 60],
    [:campaigns, [:name], 255],
    [:listings, %i[name root_model], 255],
    [:prescriptions, [:reference_number], 255],
    [:custom_fields, [:nature], 20],
    [:custom_fields, %i[column_name customized_type name], 255],
    [:journals, [:currency], 3],
    [:journals, [:code], 4],
    [:journals, [:nature], 30],
    [:journals, [:name], 255],
    [:net_services, [:reference_name], 255],
    [:budgets, %i[computation_method currency direction name working_indicator working_unit], 255],
    [:teams, [:name], 255],
    [:custom_field_choices, %i[name value], 255],
    [:bank_statements, [:currency], 3],
    [:bank_statements, [:number], 255],
    [:catalog_items, [:currency], 3],
    [:catalog_items, %i[commercial_name name], 255],
    [:issues, %i[name nature picture_content_type picture_file_name state target_type], 255],
    [:product_linkages, %i[nature originator_type point], 255],
    [:subscription_natures, [:entity_link_direction], 30],
    [:subscription_natures, [:entity_link_nature], 120],
    [:subscription_natures, %i[name nature], 255],
    [:product_nature_categories, [:number], 30],
    [:product_nature_categories, [:pictogram], 120],
    [:product_nature_categories, %i[name reference_name subscription_duration], 255],
    [:events, %i[name nature place], 255],
    [:identifiers, %i[nature value], 255],
    [:users, [:language], 3],
    [:users, %i[authentication_token confirmation_token current_sign_in_ip email employment encrypted_password first_name last_name last_sign_in_ip reset_password_token unconfirmed_email unlock_token], 255],
    [:product_links, %i[nature originator_type], 255],
    [:postal_zones, [:country], 2],
    [:postal_zones, %i[city city_name code name postal_code], 255],
    [:product_junctions, %i[originator_type type], 255],
    [:cashes, [:country], 2],
    [:cashes, [:currency], 3],
    [:cashes, [:bank_identifier_code], 11],
    [:cashes, [:nature], 20],
    [:cashes, [:iban], 34],
    [:cashes, [:spaced_iban], 42],
    [:cashes, [:bank_name], 50],
    [:cashes, %i[bank_account_key bank_account_number bank_agency_code bank_code mode name], 255],
    [:cash_transfers, %i[emission_currency reception_currency], 3],
    [:cash_transfers, [:number], 255],
    [:incoming_payments, [:currency], 3],
    [:incoming_payments, %i[bank_account_number bank_check_number bank_name number], 255],
    [:listing_node_items, [:nature], 10],
    [:deposits, [:number], 255],
    [:event_participations, [:state], 255],
    [:incoming_payment_modes, [:name], 50],
    [:establishments, %i[code name], 255],
    [:account_balances, [:currency], 255],
    [:georeadings, %i[name nature number], 255],
    [:districts, %i[code name], 255],
    [:subscriptions, [:number], 255],
    [:activities, %i[family name nature], 255],
    [:roles, %i[name reference_name], 255],
    [:transports, %i[number reference_number], 255],
    [:product_enjoyments, %i[nature originator_type], 255],
    [:products, %i[derivative_of variety], 120],
    [:products, %i[identification_number name number picture_content_type picture_file_name type work_number], 255],
    [:dashboards, [:name], 255],
    [:product_ownerships, %i[nature originator_type], 255],
    [:product_phases, [:originator_type], 255],
    [:journal_entries, %i[absolute_currency currency real_currency], 3],
    [:journal_entries, [:state], 30],
    [:journal_entries, %i[number resource_type], 255],
    [:taxes, [:computation_method], 20],
    [:taxes, [:reference_name], 120],
    [:taxes, [:name], 255],
    [:entity_addresses, [:mail_country], 2],
    [:entity_addresses, [:thread], 10],
    [:entity_addresses, [:canal], 20],
    [:entity_addresses, %i[mail_line_1 mail_line_2 mail_line_3 mail_line_4 mail_line_5 mail_line_6 name], 255],
    [:entity_addresses, [:coordinate], 500],
    [:outgoing_payments, [:currency], 3],
    [:outgoing_payments, %i[bank_check_number number], 255],
    [:manure_management_plans, %i[default_computation_method name], 255],
    [:purchase_natures, [:currency], 3],
    [:purchase_natures, [:name], 255],
    [:sales, [:currency], 3],
    [:sales, %i[initial_number number state], 60],
    [:sales, %i[expiration_delay function_title payment_delay reference_number subject], 255],
    [:interventions, %i[natures number reference_name ressource_type state], 255],
    [:purchases, [:currency], 3],
    [:purchases, %i[number state], 60],
    [:purchases, [:reference_number], 255],
    [:product_nature_variant_readings, %i[absolute_measure_value_unit choice_value indicator_datatype indicator_name measure_value_unit], 255],
    [:operations, [:reference_name], 255],
    [:documents, [:number], 60],
    [:documents, [:nature], 120],
    [:documents, %i[key name], 255],
    [:production_support_markers, %i[absolute_measure_value_unit aim choice_value derivative indicator_datatype indicator_name measure_value_unit subject], 255],
    [:manure_management_plan_zones, %i[administrative_area computation_method cultivation_variety soil_nature], 255],
    [:product_nature_variants, %i[derivative_of variety], 120],
    [:product_nature_variants, %i[name number picture_content_type picture_file_name reference_name unit_name], 255],
    [:listing_nodes, [:item_nature], 10],
    [:listing_nodes, %i[attribute_name condition_operator condition_value key label name nature sql_type], 255],
    [:observations, [:importance], 10],
    [:observations, [:subject_type], 255],
    [:product_natures, [:number], 30],
    [:product_natures, %i[derivative_of reference_name variety], 120],
    [:product_natures, %i[name picture_content_type picture_file_name population_counting], 255],
    [:affairs, [:currency], 3],
    [:affairs, %i[number originator_type], 255],
    [:budget_items, [:currency], 255],
    [:analyses, %i[nature number reference_number], 255]
  ].freeze

  def up
    LIMITS.each do |l|
      l.second.each do |column|
        # change_column l.first, column, :string, limit: nil
        # FIXME: Use rails way ASAP
        execute "ALTER TABLE \"#{l.first}\" ALTER COLUMN \"#{column}\" TYPE character varying"
      end
    end
  end

  def down
    LIMITS.reverse_each do |l|
      l.second.reverse_each do |column|
        change_column l.first, column, :string, limit: l.third
      end
    end
  end
end
