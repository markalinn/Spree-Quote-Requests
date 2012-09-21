class QuoteRequest < ActiveRecord::Base

  attr_accessible :quote_line_items, :bill_address_attributes, :ship_address_attributes, :payments_attributes,
                  :ship_address, :quote_line_items_attributes,
                  :email, :use_billing, :special_instructions

  belongs_to :user
  belongs_to :bill_address, :foreign_key => "bill_address_id", :class_name => "Address"
  belongs_to :ship_address, :foreign_key => "ship_address_id", :class_name => "Address"

  has_many :quote_line_items, :dependent => :destroy

  accepts_nested_attributes_for :quote_line_items
  accepts_nested_attributes_for :bill_address
  accepts_nested_attributes_for :ship_address

  before_create :create_user
  before_create :generate_quote_number

  # TODO: validate the format of the email as well (but we can't rely on authlogic anymore to help with validation)
  validates :email, :presence => true, :format => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i, :if => :require_email

  #delegate :ip_address, :to => :checkout
  def ip_address
    '192.168.1.100'
  end

  scope :by_number, lambda {|number| where("quote_requests.number = ?", number)}
  scope :between, lambda {|*dates| where("quote_requests.created_at between ? and ?", dates.first.to_date, dates.last.to_date)}
  scope :by_customer, lambda {|customer| joins(:user).where("users.email =?", customer)}

  make_permalink :field => :number

  attr_accessor :out_of_stock_items

  class_attribute :update_hooks
  self.update_hooks = Set.new

  # Use this method in other gems that wish to register their own custom logic that should be called after Order#updat
  def self.register_update_hook(hook)
    self.update_hooks.add(hook)
  end

  def to_param
    number.to_s.parameterize.upcase
  end

  # Indicates the number of items in the order
  def item_count
    line_items.map(&:quantity).sum
  end

  # order state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => 'cart', :use_transactions => false do

    event :next do
      transition :from => 'cart',     :to => 'address'
      transition :from => 'address',  :to => 'confirm'
      transition :from => 'confirm',  :to => 'complete'
    end

    event :cancel do
      transition :to => 'canceled', :if => :allow_cancel?
    end
    event :return do
      transition :to => 'returned', :from => 'awaiting_return'
    end
    event :resume do
      transition :to => 'resumed', :from => 'canceled', :if => :allow_resume?
    end
    event :authorize_return do
      transition :to => 'awaiting_return'
    end

    before_transition :to => 'complete' do |order|
      begin
        #Send email
        quote_request.process_payments!
      rescue
      end
    end

    after_transition :to => 'complete', :do => :finalize!
    after_transition :to => 'canceled', :do => :after_cancel

  end

  # This is a multi-purpose method for processing logic related to changes in the Order.  It is meant to be called from
  # various observers so that the Order is aware of changes that affect totals and other values stored in the Order.
  # This method should never do anything to the Order that results in a save call on the object (otherwise you will end
  # up in an infinite recursion as the associations try to save and then in turn try to call +update!+ again.)
  def update!
    update_totals

    # update totals a second time in case updated adjustments have an effect on the total
    update_totals

    update_attributes_without_callbacks({
      :item_total => item_total,
      :total => total
    })

    update_hooks.each { |hook| self.send hook }
  end

  before_validation :clone_billing_address, :if => "@use_billing"
  attr_accessor :use_billing

  def clone_billing_address
    if bill_address and self.ship_address.nil?
      self.ship_address = bill_address.clone
    else
      self.ship_address.attributes = bill_address.attributes.except("id", "updated_at", "created_at")
    end
    true
  end

  def allow_cancel?
    return false unless state != 'canceled'
    #%w{ready backorder pending}.include? shipment_state
  end

  def add_variant(variant, quantity = 1)
    current_item = contains?(variant)
    if current_item
      current_item.quantity += quantity
      current_item.save
    else
      current_item = QuoteLineItem.new(:quantity => quantity)
      current_item.variant = variant
      current_item.price   = variant.price
      self.quote_line_items << current_item
    end

    # populate line_items attributes for additional_fields entries
    # that have populate => [:line_item]
    Variant.additional_fields.select{|f| !f[:populate].nil? && f[:populate].include?(:line_item) }.each do |field|
      value = ""

      if field[:only].nil? || field[:only].include?(:variant)
        value = variant.send(field[:name].gsub(" ", "_").downcase)
      elsif field[:only].include?(:product)
        value = variant.product.send(field[:name].gsub(" ", "_").downcase)
      end
      current_item.update_attribute(field[:name].gsub(" ", "_").downcase, value)
    end

    current_item
  end

  # FIXME refactor this method and implement validation using validates_* utilities
  def generate_quote_number
    record = true
    while record
      random = "Q#{Array.new(9){rand(9)}.join}"
      record = self.class.find(:first, :conditions => ["number = ?", random])
    end
    self.number = random if self.number.blank?
    self.number
  end

  def contains?(variant)
    quote_line_items.detect{|line_item| line_item.variant_id == variant.id}
  end

  def name
    if (address = bill_address || ship_address)
      "#{address.firstname} #{address.lastname}"
    end
  end

  def billing_firstname
    bill_address.try(:firstname)
  end

  def billing_lastname
    bill_address.try(:lastname)
  end

  def products
    quote_line_items.map{|li| li.variant.product}
  end

  private
  def create_user
    self.user = User.current
    self.email = user.email if self.user and not user.anonymous?
  end

  # Updates the following Order total values:
  #
  # +payment_total+      The total value of all finalized Payments (NOTE: non-finalized Payments are excluded)
  # +item_total+         The total value of all LineItems
  # +adjustment_total+   The total value of all adjustments (promotions, credits, etc.)
  # +total+              The so-called "order total."  This is equivalent to +item_total+ plus +adjustment_total+.
  def update_totals
    # update_adjustments
    self.item_total = line_items.map(&:amount).sum
    self.total = item_total
  end

  # Determine if email is required (we don't want validation errors before we hit the checkout)
  def require_email
    return true unless new_record? or state == 'cart'
  end

  def after_cancel
    # TODO: make_shipments_pending
    # TODO: restock_inventory
    OrderMailer.cancel_email(self).deliver
  end

end
