# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::AnimalsController < Backend::ProductsController
  manage_restfully :t3e => {:nature_name => "@animal.nature_name"}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  list(:conditions => {:external => false}) do |t|
    t.column :work_number, :url => true
    t.column :name, :url => true
    t.column :born_at
    t.column :sex
    t.column :name, :through => :mother, :url => true
    t.column :name, :through => :father, :url => true
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of animal groups

  def index
    @animals = Animal.all
    # parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    # respond with associated models to simplify quering in Ireport
    respond_with @animals, :include => [:father, :mother, :variety, :nature]
  end

   # Liste des enfants de l'animal considéré
  list(:children, :model => :animals, :conditions => [" mother_id = ? OR father_id = ? ",['session[:current_animal_id]'],['session[:current_animal_id]']], :order => "born_at DESC") do |t|
    t.column :name, :url => true
    t.column :born_at
    t.column :sex
    t.column :description
  end

  # Liste des lieux de l'animal considéré
  list(:place, :model => :product_localizations, :conditions => [" product_id = ? ",['session[:current_animal_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :container, :url => true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Liste des groupes de l'animal considéré
  list(:group, :model => :product_memberships, :conditions => [" member_id = ? ",['session[:current_animal_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through =>:group, :url => true
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des indicateurs de l'animal considéré
  list(:indicator, :model => :product_indicator_data, :conditions => [" product_id = ? ",['session[:current_animal_id]']], :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

  # Liste des incidents de l'animal considéré
  list(:incident, :model => :incidents, :conditions => [" target_id = ? and target_type = 'Product'",['session[:current_animal_id]']], :order => "observed_at DESC") do |t|
    t.column :name, :url => true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end



  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    session[:current_animal_id] = @animal.id
    t3e @animal, :nature_name => @animal.nature_name
           respond_with(@animal, :methods => :picture_path, :include => [:father, :mother, :nature, :variety, :owner,
                                                   {:indicator_data => {}},
                                                   {:memberships => {:include =>:group}},
                                                    {:product_localizations => {:include =>:container}}])
    # respond_to do |format|
    #   format.html do
    #     session[:current_animal_id] = @animal.id
    #     t3e @animal, :nature_name => @animal.nature_name
    #   end
    #   format.xml {render xml: @animal, :include => [:father, :mother, :nature, :variety, :indicator_data,
    #                                                 {:memberships => {:group => nil}},
    #                                                 {:product_localizations => {:container => nil}}
    #                                                ]}
    #   format.pdf {respond_with @animal, :include => [:father, :mother, :nature, :variety, :indicator_data,
    #                                                  {:memberships => {:group => nil}},
    #                                                  {:product_localizations => {:container => nil}}
    #                                                 ]}
    # end
  end

  def picture
    return unless @animal = find_and_check
    send_file @animal.picture.path(params[:style] || :original)
  end

  def animal_sanitary_list
      #
      builder = Nokogiri::XML::Builder.new  do |xml|#(:target=>$stdout, :indent=>2)
        #xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
        #xml.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN",
        #"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
        campaign = Campaign.first
        entity = Entity.of_company
        entity_breeding_number = Preference.find_by_name('services.synel17.login')
        procedures = Procedure.where("nomen = 'animal_treatment'")
        #raise groups.inspect
          xml.interventions(:campaign => campaign.name,
                            :entity_name => entity.full_name,
                            :entity_adress => entity.default_mail_address.coordinate,
                            :entity_breeding_number => entity_breeding_number.value
                            ) do
            for procedure in procedures
              xml.intervention(:id => procedure.id, :name => procedure.name) do
              target = procedure.variables.of_role(:target).first.target
              worker = procedure.variables.of_role(:worker).first.target
               for input_variable in procedure.variables.of_role(:input)
                      # determine min sale date
                      started_at = procedure.started_at
                      stopped_at = procedure.stopped_at
                      meat_withdrawal_period = input_variable.target.meat_withdrawal_period.to_f
                      milk_withdrawal_period = input_variable.target.milk_withdrawal_period.to_f
                      milk_min_sale_date = stopped_at + milk_withdrawal_period
                      meat_min_sale_date = stopped_at + meat_withdrawal_period
                      procedure_duration_day = (stopped_at - started_at)/(60*60*24)

                      xml.input(:id => input_variable.id,
                                :target_identification => target.identification_number,
                                :target_id => target.id,
                                :target_name => target.name,
                                :target_class_name => target.class.name,
                                :worker_name => worker.name,
                                :worker_id => worker.id,
                                :worker_entity_id => worker.owner.id,
                                :name => input_variable.target.name,
                                :nature => input_variable.target.nature.name,
                                :variety => input_variable.target.variety,
                                :quantity => input_variable.measure_quantity,
                                :quantity_unit => input_variable.measure_unit,
                                :meat_withdrawal_period => meat_withdrawal_period,
                                :milk_withdrawal_period => milk_withdrawal_period,
                                :milk_min_sale_date => milk_min_sale_date,
                                :meat_min_sale_date => meat_min_sale_date,
                                :started_at => started_at,
                                :stopped_at => stopped_at,
                                :procedure_duration_day => procedure_duration_day
                                ) do

               if procedure.incident.id > 0
                      xml.incident(:id => procedure.incident.id,
                                   :name => procedure.incident.name,
                                   :observed_at => procedure.incident.observed_at,
                                   :state =>  procedure.incident.state,
                                   :description => procedure.incident.description
                                   )
               end
              if procedure.prescription.id > 0
                      xml.prescription(:id => procedure.prescription.id,
                                       :reference_number => procedure.prescription.reference_number,
                                       :prescriptor => procedure.prescription.prescriptor.name
                                       )
               end
               end
             end
             end
             end
           end
         end
     @animal_sanitary_list = builder.to_xml
        respond_to do |format|
          format.xml { render :text => @animal_sanitary_list}
      end
   end

end
