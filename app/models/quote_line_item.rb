class QuoteLineItem < ActiveRecord::Base
  before_validation :adjust_quantity
  belongs_to :quote_request
  belongs_to :variant

  has_one :product, :through => :variant

  validates :variant, :presence => true
  validates :quantity, :numericality => { :only_integer => true, :message => I18n.t("validation.must_be_int") }
  # validate :meta_validation_of_quantities

  attr_accessible :quantity

  # def meta_validation_of_quantities
  #   unless quantity && quantity >= 0
  #     errors.add(:quantity, I18n.t("validation.must_be_non_negative"))
  #   end
  #   # avoid reload of order.inventory_units by using direct lookup
  #   unless !Spree::Config[:track_inventory_levels]                        ||
  #          Spree::Config[:allow_backorders]                               ||
  #          order   && InventoryUnit.order_id_equals(order).first.present? ||
  #          variant && quantity <= variant.on_hand
  #     errors.add(:quantity, I18n.t("validation.is_too_large") + " (#{self.variant.name})")
  #   end
  #
  #   if shipped_count = order.shipped_units.nil? ? nil : order.shipped_units[variant]
  #     errors.add(:quantity, I18n.t("validation.cannot_be_less_than_shipped_units") ) if quantity < shipped_count
  #   end
  # end

  def increment_quantity
    self.quantity += 1
  end

  def decrement_quantity
    self.quantity -= 1
  end

  def adjust_quantity
    self.quantity = 0 if self.quantity.nil? || self.quantity < 0
  end
end

