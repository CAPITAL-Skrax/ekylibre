# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: parcels
#
#  accounted_at                         :datetime
#  address_id                           :integer
#  contract_id                          :integer
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer          not null, primary key
#  in_preparation_at                    :datetime
#  journal_entry_id                     :integer
#  lock_version                         :integer          default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer
#  recipient_id                         :integer
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer
#  sale_id                              :integer
#  sender_id                            :integer
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer
#  transporter_id                       :integer
#  undelivered_invoice_journal_entry_id :integer
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#  with_delivery                        :boolean          default(FALSE), not null
#

class Parcel < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency
  refers_to :currency
  enumerize :nature, in: %i[incoming outgoing], predicates: true, scope: true, default: :incoming
  enumerize :delivery_mode, in: %i[transporter us third], predicates: { prefix: true }, scope: true, default: :us
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :delivery
  belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :storage, class_name: 'Product'
  belongs_to :sale, inverse_of: :parcels
  belongs_to :purchase
  belongs_to :recipient, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  belongs_to :sender, class_name: 'Entity'
  belongs_to :transporter, class_name: 'Entity'
  belongs_to :contract
  has_many :items, class_name: 'ParcelItem', inverse_of: :parcel, foreign_key: :parcel_id, dependent: :destroy
  has_many :products, through: :items
  has_many :issues, as: :target
  # has_many :interventions, class_name: 'Intervention', as: :resource

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :given_at, :in_preparation_at, :ordered_at, :prepared_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :nature, presence: true
  validates :number, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :planned_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :reference_number, length: { maximum: 500 }, allow_blank: true
  validates :remain_owner, :with_delivery, inclusion: { in: [true, false] }
  validates :separated_stock, inclusion: { in: [true, false] }, allow_blank: true
  validates :state, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :delivery_mode, :address, presence: true
  validates :recipient, presence: { if: :outgoing? }
  validates :sender, presence: { if: :incoming? }
  validates :transporter, presence: { if: :delivery_mode_transporter? }
  validates :storage, presence: { unless: :outgoing? }

  scope :without_transporter, -> { with_delivery_mode(:transporter).where(transporter_id: nil) }
  scope :with_delivery, -> { where(with_delivery: true) }
  scope :to_deliver, -> { with_delivery.where(delivery_id: nil).where.not(state: :given) }

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  acts_as_list scope: :delivery
  acts_as_numbered
  delegate :draft?, :ordered?, :in_preparation?, :prepared?, :started?, :finished?, to: :delivery, prefix: true

  state_machine initial: :draft do
    state :draft
    state :ordered
    state :in_preparation
    state :prepared
    state :given

    event :order do
      transition draft: :ordered, if: :any_items?
    end
    event :prepare do
      transition draft: :in_preparation, if: :any_items?
      transition ordered: :in_preparation, if: :any_items?
    end
    event :check do
      transition draft: :prepared, if: :all_items_prepared?
      transition ordered: :prepared, if: :all_items_prepared?
      transition in_preparation: :prepared, if: :all_items_prepared?
    end
    event :give do
      transition draft: :given, if: :giveable?
      transition ordered: :given, if: :giveable?
      transition in_preparation: :given, if: :giveable?
      transition prepared: :given, if: :giveable?
    end
    event :cancel do
      transition ordered: :draft
      transition in_preparation: :ordered
      # transition prepared: :in_preparation
      # transition given: :prepared
    end
  end

  before_validation do
    self.planned_at ||= Time.zone.today
    self.state ||= :draft
    self.currency ||= Preference[:currency]
    self.pretax_amount = items.sum(:pretax_amount)
  end

  validate do
    if delivery && delivery.transporter && transporter
      if delivery.transporter != transporter
        errors.add :transporter_id, :invalid
      end
    end
  end

  after_initialize do
    if new_record? && incoming?
      self.address ||= Entity.of_company.default_mail_address
    end
  end

  before_update do
    if given_at != old_record.given_at
      products.each do |product|
        product.readings.where(read_at: old_record.given_at).update_all(read_at: given_at)
      end
    end
  end

  protect on: :destroy do
    prepared? || given?
  end

  # This method permits to add stock journal entries corresponding to the
  # incoming or outgoing parcels.
  # It depends on the preferences which permit to activate the "permanent stock
  # inventory" and "automatic bookkeeping".
  #
  # | Parcel mode            | Debit                      | Credit                    |
  # | incoming parcel        | stock (3X)                 | stock_movement (603X/71X) |
  # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
  bookkeep do |b|
    # For purchase_not_received or sale_not_emitted
    invoice = lambda do |usage, order|
      lambda do |entry|
        label = tc(:undelivered_invoice,
                   resource: self.class.model_name.human,
                   number: number, entity: entity.full_name, mode: nature.l)
        account = Account.find_or_import_from_nomenclature(usage)
        items.each do |item|
          amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
          next unless item.variant && item.variant.charge_account && amount.nonzero?
          if order
            entry.add_credit label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_debit  label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          else
            entry.add_debit  label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_credit label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          end
        end
      end
    end

    ufb_accountable = Preference[:unbilled_payables] && given?
    # For unbilled payables
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: self.currency) }
    b.journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable && incoming?, &invoice.call(:suppliers_invoices_not_received, true))

    b.journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable && outgoing?, &invoice.call(:invoice_to_create_clients, false))

    accountable = Preference[:permanent_stock_inventory] && given?
    # For permanent stock inventory
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: self.currency) }
    b.journal_entry(journal, printed_on: printed_on, if: (Preference[:permanent_stock_inventory] && given?)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human,
                            number: number, entity: entity.full_name, mode: nature.l)
      items.each do |item|
        variant = item.variant
        next unless variant && variant.storable? && item.stock_amount.nonzero?
        if incoming?
          entry.add_credit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, variant: item.variant)
          entry.add_debit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
        elsif outgoing?
          entry.add_debit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, variant: item.variant)
          entry.add_credit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
        end
      end
    end
  end

  def entity
    incoming? ? sender : recipient
  end

  def printed_at
    given_at || created_at || Time.zone.now
  end

  def printed_on
    printed_at.to_date
  end

  def content_sentence
    sentence = items.map(&:name).compact.to_sentence
  end

  def separated_stock?
    separated_stock
  end

  def invoiced?
    purchase.present? || sale.present?
  end

  def invoiceable?
    !invoiced?
  end

  def delivery?
    delivery.present?
  end

  def delivery_started?
    delivery?
  end

  def shippable?
    with_delivery && delivery.blank?
  end

  def allow_items_update?
    !prepared? && !given?
  end

  def address_coordinate
    address.coordinate if address
  end

  def address_mail_coordinate
    (address || sale.client.default_mail_address).mail_coordinate
  end

  def human_delivery_mode
    delivery_mode.text
  end

  def human_delivery_nature
    nature.text
  end

  # Number of products delivered
  def items_quantity
    items.sum(:population)
  end

  def all_items_prepared?
    any_items? && items.all?(&:prepared?)
  end

  def any_items?
    items.any?
  end

  def issues?
    issues.any?
  end

  def giveable?
    !with_delivery || (with_delivery && delivery.present? && delivery.started?)
  end

  def status
    if given?
      (issues? ? :caution : :go)
    else
      (issues? ? :stop : :caution)
    end
  end

  def third_id
    (incoming? ? sender_id : recipient_id)
  end

  def third
    (incoming? ? sender : recipient)
  end

  def order
    return false unless can_order?
    update_column(:ordered_at, Time.zone.now)
    super
  end

  def prepare
    order if can_order?
    return false unless can_prepare?
    now = Time.zone.now
    values = { in_preparation_at: now }
    # values[:ordered_at] = now unless ordered_at
    update_columns(values)
    super
  end

  def check
    state = true
    order if can_order?
    prepare if can_prepare?
    return false unless can_check?
    now = Time.zone.now
    values = { prepared_at: now }
    # values[:ordered_at] = now unless ordered_at
    # values[:in_preparation_at] = now unless in_preparation_at
    update_columns(values)
    state = items.collect(&:check)
    return false, state.collect(&:second) unless (state == true) || (state.is_a?(Array) && state.all? { |s| s.is_a?(Array) ? s.first : s })
    super
    true
  end

  def give
    state = true
    order if can_order?
    prepare if can_prepare?
    state, msg = check if can_check?
    return false, msg unless state
    return false unless can_give?
    update_column(:given_at, Time.zone.now) if given_at.blank?
    items.each(&:give)
    reload
    super
  end

  def first_available_date
    # Used to order.
    # TODO: Replace with a scope using SQL's COALESCE
    given_at || planned_at || prepared_at || in_preparation_at || ordered_at
  end

  class << self
    # Ships parcels. Returns a delivery
    # options:
    #   - delivery_mode: delivery mode
    #   - transporter_id: the transporter ID if delivery mode is :transporter
    #   - responsible_id: the responsible (Entity) ID for the delivery
    # raises:
    #   - "Need an obvious transporter to ship parcels" if there is no unique transporter for the parcels
    def ship(parcels, options = {})
      delivery = nil
      transaction do
        if options[:transporter_id]
          options[:delivery_mode] ||= :transporter
        elsif !delivery_mode.values.include? options[:delivery_mode].to_s
          raise "Need a valid delivery mode at least if no transporter given. Got: #{options[:delivery_mode].inspect}. Expecting one of: #{delivery_mode.values.map(&:inspect).to_sentence}"
        end
        delivery_mode = options[:delivery_mode].to_sym
        if delivery_mode == :transporter
          unless options[:transporter_id] && Entity.find_by(id: options[:transporter_id])
            transporter_ids = transporters_of(parcels).uniq
            if transporter_ids.size == 1
              options[:transporter_id] = transporter_ids.first
            else
              raise StandardError, 'Need an obvious transporter to ship parcels'
            end
          end
        end
        options[:started_at] ||= Time.zone.now
        options[:mode] = options.delete(:delivery_mode)
        delivery = Delivery.create!(options.slice!(:started_at, :transporter_id, :mode, :responsible_id, :driver_id))
        parcels.each do |parcel|
          parcel.delivery_mode = delivery_mode
          parcel.transporter_id = options[:transporter_id]
          parcel.delivery = delivery
          parcel.save!
        end
        delivery.save!
      end
      delivery
    end

    # Returns an array of all the transporter ids for the given parcels
    def transporters_of(parcels)
      parcels.map(&:transporter_id).compact
    end

    def convert_to_trade(parcels, trade_class, &unit_pretax_amount)
      trade = nil

      trade_type = trade_class.name.downcase.to_sym
      trade_nature = trade_class.nature_class
      journal = Journal.send(trade_type.to_s.pluralize.to_sym)

      transaction do
        parcels = parcels.includes(:items).sort_by(&:first_available_date)
        third = detect_third(parcels)
        planned_at = parcels.last.first_available_date || Time.zone.now

        # Instantiate nature
        unless nature = trade_nature.actives.first
          unless journal = journal.opened_on(planned_at).first
            raise "No #{trade_type} journal"
          end
          nature = trade_nature.create!(
            active: true,
            currency: Preference[:currency],
            with_accounting: true,
            journal: journal,
            by_default: true,
            name: trade_nature.tc('default.name', default: trade_nature.model_name.human)
          )
        end

        # Instantiate trade
        trade_attributes = {
          trade_class.third_attribute => third,
          nature: nature,
          delivery_address: parcels.last.address
        }
        trade_attributes[:planned_at] = planned_at if trade_type == :purchase
        trade = trade_class.create!(trade_attributes)

        # Instatiate trade items
        able_predicate = :"#{trade_type}able?"
        taxes_method = :"#{trade_type}_taxes"

        parcels.each do |parcel|
          parcel.items.order(:id).each do |item|
            tradeable = item.variant.send(able_predicate)
            present = item.population && item.population > 0
            next unless tradeable && present

            catalog_item = Catalog.by_default!(trade_type).items.find_by(variant: item.variant)
            tax = item.variant.category.send(taxes_method).first || Tax.first
            trade_item = trade.items.new(
              variant: item.variant,
              unit_pretax_amount: unit_pretax_amount.call(item, catalog_item),
              tax: tax,
              quantity: item.population
            )

            item.send(:"#{trade_type}_item=", trade_item)
          end

          parcel.send(:"#{trade_type}=", trade)
          parcel.save!
        end

        # Refreshes affair
        trade.save!
      end
      trade
    end

    # Convert parcels to one sale. Assume that all parcels are checked before.
    # Sale is written in DB with default values
    def convert_to_sale(parcels)
      convert_to_trade(parcels, Sale) do |_, catalog_item|
        catalog_item ? catalog_item.amount : 0.0
      end
    end

    # Convert parcels to one purchase. Assume that all parcels are checked before.
    # Purchase is written in DB with default values
    def convert_to_purchase(parcels)
      convert_to_trade(parcels, Purchase) do |item|
        item.unit_pretax_amount.nil? || item.unit_pretax_amount.zero? ? (catalog_item ? catalog_item.amount : 0.0) : item.unit_pretax_amount
      end
    end

    def detect_third(parcels)
      thirds = parcels.map(&:third_id).uniq
      raise "Need unique third (#{thirds.inspect})" if thirds.count != 1
      Entity.find(thirds.first)
    end
  end
end
