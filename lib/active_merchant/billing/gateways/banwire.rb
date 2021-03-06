module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BanwireGateway < Gateway
      URL = 'https://banwire.com/api.pago_pro'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['MX', 'USD']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.banwire.com/'

      # The name of the gateway
      self.display_name = 'Banwire'

      def initialize(options = {})
        requires!(options, :login)
        @options = options
        super
      end

      def purchase(money, creditcard, options = {})
        post = {}
        add_response_type(post)
        add_customer_data(post, options)
        add_order_data(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
  	add_shipping_address(post, creditcard, options)
        add_customer_data(post, options)
        add_amount(post, money, options)

        commit(money, post)
      end

      private

      def add_response_type(post)
        post[:response_format] = "JSON"
      end

      def add_customer_data(post, options)
        post[:user] = @options[:login]
        post[:phone] = options[:billing_address][:phone]
        post[:mail] = options[:email]
      end

      def add_order_data(post, options)
        post[:reference] = options[:order_id]
        post[:concept] = options[:description]
      end

      def add_address(post, creditcard, options)
        post[:address] = options[:billing_address][:address1]
        post[:post_code] = options[:billing_address][:zipcode]
      end

      def add_shipping_address(post, options)
        post[:s_address] = options[:shipping_address][:address1]
        post[:s_post_code] = options[:shipping_address][:zipcode]
      end

      def add_creditcard(post, creditcard)
        post[:card_num] = creditcard.number
        post[:card_name] = creditcard.name
        post[:card_type] = get_brand(creditcard.brand)
        post[:card_exp] = "#{sprintf("%02d", creditcard.month)}/#{"#{creditcard.year}"[-2, 2]}"
        post[:card_ccv2] = creditcard.verification_value
      end

      def add_amount(post, money, options)
        post[:ammount] = amount(money)
        post[:currency] = @options[:currency]
      end

      #wraper for the brand method
      #ActiveMerchant returns master or american_express
      #Banwire requires mastercard and amex
      def get_brand(brand)
        case brand
        when "master"
          return "mastercard"
        when "american_express"
          return "amex"
        else
          return brand
        end
      end

      def parse(body)
        JSON.parse(body)
      end

      def commit(money, parameters)
        response = parse(ssl_post(URL, post_data(parameters)))
        Response.new success?(response),
                     response["message"],
                     response,
                     :test => test?,
                     :authorization => response["code_auth"]
      end

      def success?(response)
        response["response"] == "ok"
      end

      def post_data(parameters = {})
        parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end
    end
  end
end
