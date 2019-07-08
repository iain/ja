# frozen_string_literal: true

module Ja
  module Methods

    verbs = %i[head get post put delete trace options connect patch]

    verbs.each do |verb|

      define_method verb do |*args, &block|
        request verb, *args, &block
      end

      define_method "#{verb}!" do |*args, &block|
        request! verb, *args, &block
      end

    end

  end
end
