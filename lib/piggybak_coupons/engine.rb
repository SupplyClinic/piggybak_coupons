require 'piggybak_coupons/line_item_decorator'

module PiggybakCoupons
  class Engine < ::Rails::Engine
    isolate_namespace PiggybakCoupons

    config.to_prepare do
      Piggybak::LineItem.send(:include, ::PiggybakCoupons::LineItemDecorator)
    end

    config.before_initialize do
      Piggybak.config do |config|
        config.manage_classes << "::PiggybakCoupons::Coupon"
        config.extra_secure_paths << "/apply_coupon"
        config.line_item_types[:coupon_application] = { :visible => true,
                                                        :nested_attrs => true,
                                                        :fields => ["coupon_application"],
                                                        :allow_destroy => true,
                                                        :reduce_tax_subtotal => true,
                                                        :class_name => "::PiggybakCoupons::CouponApplication",
                                                        :display_in_cart => "Discount",
                                                        :sort => config.line_item_types[:payment][:sort]
                                                      } 
        config.line_item_types[:payment][:sort] += 1
        config.additional_line_item_attributes[:coupon_application_attributes] = [:code]
      end
    end

    initializer "piggybak_coupons.assets.precompile" do |app|
      app.config.assets.precompile += ['piggybak_coupons/piggybak_coupons-application.js']
    end

    initializer "piggybak_coupons.rails_admin_config" do |app|
      RailsAdmin.config do |config|
        config.model PiggybakCoupons::Coupon do
          navigation_label "Extensions"
          label "Coupon"

          list do
            field :code
            field :coupon_type
            field :min_cart_total do
              formatted_value do
                "$#{sprintf("%.2f", value)}"
              end
            end
            field :expiration_date
            field :application_detail
          end
          edit do
            field :code
            field :amount
            field :discount_type, :enum 
            field :min_cart_total
            field :expiration_date
            field :allowed_applications
          end
        end

        config.model PiggybakCoupons::CouponApplication do
          label "Coupon"
          visible false

          edit do
            field :code do
              read_only do
                !bindings[:object].new_record?
              end
              pretty_value do
                bindings[:object].coupon ? bindings[:object].coupon.code : ""
              end 
            end
          end
        end
      end
    end 
  end
end
